//
//  AppDelegate.swift
//  socks
//
//  Created by 徳備彩人 on 2019/01/22.
//  Copyright © 2019 徳備彩人. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var item1: NSMenuItem!
    @IBOutlet weak var item2: NSMenuItem!
    @IBOutlet weak var quitItem: NSMenuItem!
    //メニューバーに表示されるアプリケーションを作成
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    var running:Bool = false
    
    let redTitle: [NSAttributedString.Key : Any] = [
        .foregroundColor : NSColor.red
    ]
    
    let blackTitle: [NSAttributedString.Key : Any] = [
        .foregroundColor : NSColor.black
    ]
    
    let formatter = DateFormatter()

    weak var timer: Timer!
    var startTime = Date()
    var endTime = Date()
    var timerHour = "00"
    var timerMinute = "00"
    var timerSecond = "00"
    var sleep_stopped = false
    var fileURL: URL!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    
        self.statusItem.button?.attributedTitle = NSAttributedString(string: "00:00:00", attributes:self.blackTitle)
        
        // self.statusItem.menu = menu
        //メニューのハイライトモードの設定
        self.statusItem.button?.highlight(false)
        //buttonの機能を設定
        self.statusItem.button?.action = #selector(AppDelegate.click(_:))
        self.statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(sleep_stop), name: NSWorkspace.willSleepNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(sleep_start), name: NSWorkspace.didWakeNotification, object: nil)

        let openFileDialog = NSOpenPanel()
        openFileDialog.canChooseDirectories = false
        openFileDialog.canChooseFiles = true
        openFileDialog.canCreateDirectories = false
        openFileDialog.allowsMultipleSelection = false
        let result = openFileDialog.runModal()
        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
            self.fileURL = openFileDialog.url
        } else if result.rawValue == NSApplication.ModalResponse.cancel.rawValue {
            NSApplication.shared.terminate(self)
        }
        self.formatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func sleep_start(_ sender: Notification) {
        if(self.sleep_stopped){
            startTimer()
            self.sleep_stopped = false
        }
    }
    @objc func sleep_stop(_ sender: Notification) {
        if(self.running){
            stopTimer()
            self.sleep_stopped = true
        }
    }
    
    @objc func click(_ sender: NSStatusBarButton){
        let event = NSApp.currentEvent!
        if event.type == NSEvent.EventType.rightMouseUp {
            
        } else {
            
            if(self.running){
                self.stopTimer()
            }else{
                self.startTimer()
            }
        }
    }

    func startTimer() {
        if self.timer != nil{
            // timerが起動中なら一旦破棄する
            self.timer.invalidate()
        }
        
        self.timer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(self.timerCounter),
            userInfo: nil,
            repeats: true)
        
        self.startTime = Date()
        self.running = true
    }
    
    func stopTimer() {
        if self.timer != nil{
            self.timer.invalidate()
        }
        self.endTime = Date()
        self.statusItem.button?.attributedTitle = NSAttributedString(string: self.displayedTime(), attributes:self.blackTitle)
        self.running = false
//        displayedTime().write( to: self.fileURL, atomically: false, encoding: String.Encoding.utf8 )
        
        if write(url: self.fileURL, text: savedTime()){
            print("success")
        } else {
            print("error")
            //エラー処理
        }
    }
    
    @objc func timerCounter() {
        // タイマー開始からのインターバル時間
        let currentTime = Date().timeIntervalSince(startTime)
        
        let hour = (Int)(fmod((currentTime/3600), 60))
        // fmod() 余りを計算
        let minute = (Int)(fmod((currentTime/60), 60))
        // currentTime/60 の余り
        let second = (Int)(fmod(currentTime, 60))
        
        // %02d： ２桁表示、0で埋める
        let sHour = String(format:"%02d", hour)
        let sMinute = String(format:"%02d", minute)
        let sSecond = String(format:"%02d", second)

        self.timerHour = sHour
        self.timerMinute = sMinute
        self.timerSecond = sSecond
        
        self.statusItem.button?.attributedTitle = NSAttributedString(string: self.displayedTime(), attributes:self.redTitle)
    }
    
    func displayedTime() -> (String) {
        return self.timerHour + ":" + self.timerMinute + ":" + self.timerSecond
    }
    
    func savedTime() -> (String) {
        return self.formatter.string(from: self.startTime) + "," + self.formatter.string(from: self.endTime) + "," + self.displayedTime() + "\n"
    }
    
    func write(url: URL, text: String) -> Bool {
        guard let stream = OutputStream(url: url, append: true) else {
            return false
        }
        stream.open()
        
        defer {
            stream.close()
        }
        
        guard let data = text.data(using: .utf8) else { return false }
        var result: Int!
        data.withUnsafeBytes {
            let unsafeBufferPointer = $0.bindMemory(to: UInt8.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            result = stream.write(unsafePointer, maxLength: data.count)
        }
        return (result > 0)
    }
}

