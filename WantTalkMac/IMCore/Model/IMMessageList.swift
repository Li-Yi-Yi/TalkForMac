//
//  IMMessageList.swift
//  BPM-T
//
//  Created by 刘表聪 on 16/12/30.
//  Copyright © 2016年 com.want.mis.wantworld. All rights reserved.
//

import Cocoa

/**
 *  消息列表model
 */
let kUserId: String = "kUserId"
let kMessage: String = "kMessage"
let kMessageListDate: String = "kMessageListDate"

class IMMessageList: NSObject, NSCoding {
    
    var userId: String?      // 好友id
    var message: String?     // 最新消息
    var isGroupChat: Bool {  // 是否是群聊
        get{
            return self.userId?.components(separatedBy: "+")[0].components(separatedBy: "@")[1] == "conference.coop"
        }
    }
    
    var date: String?        // 日期
    
    // 初始化
    init(id: String?, message: String?) {
        super.init()
        self.userId = id
        self.message = message
        self.date = ""
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(userId, forKey: kUserId)
        aCoder.encode(message, forKey: kMessage)
        aCoder.encode(date, forKey: kMessageListDate)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        userId = aDecoder.decodeObject(forKey: kUserId) as! String?
        message = aDecoder.decodeObject(forKey: kMessage) as! String?
        date = aDecoder.decodeObject(forKey: kMessageListDate) as! String?
    }
    
}
