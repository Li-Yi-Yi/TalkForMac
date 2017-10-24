//
//  NSViewController+Extension.swift
//  TalkClient
//
//  Created by 吳淑菁 on 2017/9/12.
//
//

import Foundation
import AppKit

/**
 *  弹框提示，类型包括 .alert, .actionSheet
 */

extension NSViewController {
    
    // show simple alert with prompt string, confirm button, cancel button
    // parameter:prompt : String
    func showPrompt(prompt: String) {
        
        let alert = NSAlert()
        alert.addButton(withTitle: NSLocalizedString("好的", comment: ""))
    
        alert.messageText = prompt
        alert.informativeText = prompt
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        
        switch response {
        case 0:
            break
        case 1:
            break
        default:
            print("...")
        }
        
        
    }

}
