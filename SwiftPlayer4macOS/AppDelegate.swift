//
//  AppDelegate.swift
//  SwiftPlayer4macOS
//
//  Created by mayjay on 2016. 9. 14..
//  Copyright © 2016년 Kwanghoon Choi. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    //MARK: - Menu
    @IBAction func open(_ sender: AnyObject?) {
        guard let window = NSApplication.shared().windows.first else {
            return
        }
        guard let main = window.contentViewController as? MainController else {
            return
        }
        main.open()
    }
}

