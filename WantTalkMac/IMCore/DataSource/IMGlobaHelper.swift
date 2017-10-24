//
//  IMGlobaHelper.swift
//  IM_Swift
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 wangwang. All rights reserved.
//

//
import Cocoa
#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

func dispatch_async_safely_to_main_queue(block: @escaping ()->()) {
    dispatch_async_safely_to_queue(queue: DispatchQueue.main, block)
}

/**
 *  this methd will dispatch the 'block' to a specified 'queue'
 *  if the 'queue' is the main queue, and current thread is main thread, the block
 *  will be invoked immediately instead of being dispatched.
 */
func dispatch_async_safely_to_queue(queue: DispatchQueue, _ block: @escaping ()->()) {
    if queue == DispatchQueue.main && Thread.isMainThread {
        block()
    } else {
        queue.async {
            block()
        }
    }
}

func IMAlertView_show(_ title: String, message: String? = nil) {
    var theMessage = ""
    #if TARGET_OS_IOS
        if message != nil {
            theMessage = message!
        }
    
        let alertView = UIAlertView(title: title , message: theMessage, delegate: nil, cancelButtonTitle: "取消", otherButtonTitles: "好的")
        alertView.show()
    #else
        if message != nil {
            theMessage = message!
        }
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = theMessage
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "好的")
        alert.runModal()
    #endif
}
