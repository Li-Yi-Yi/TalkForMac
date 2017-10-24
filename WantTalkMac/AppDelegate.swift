//
//  AppDelegate.swift
//  WantTalkMac
//
//  Created by 吳淑菁 on 2017/9/13.
//  Copyright © 2017年 吳淑菁. All rights reserved.
//

import Cocoa
import ApplicationServices
import RealmSwift
import Alamofire

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var isFirstLogin: Bool = false //在登录页面登录
    var pushKey: String?
    var isPushLogout: Bool = false
    let netWorkManager = NetworkReachabilityManager()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    //MARK:
    func getChatterSize() -> CGSize {
        
        return CGSize(width: 280, height: 480)
    }

}

