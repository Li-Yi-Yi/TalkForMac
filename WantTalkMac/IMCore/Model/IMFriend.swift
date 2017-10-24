//
//  IMFriend.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

import Foundation

/**
 *  好友model
 */
class IMFriend: NSObject, NSCopying {
    
    var userId: String?          // 好友id, Jid带@coop
    var nickName: String?        // 好友备注名
    var group: String?           // 好友分组
    var isOnline: Bool = false   // 是否在线
    var isShowTip: Bool = false  // 是否显示红点未读消息
    var recentMessage: String?   // 最后一条消息
    var unreadMesNumber: Int     // 未读消息数目
    var date: String?            // 日期
    var isGroupChat: Bool {      // 是否是分组
        get{
            if self.userId!.contains("@") {
                return self.userId!.components(separatedBy: "@")[1] == "conference.coop"
            } else {
                return false
            }
        }
    }
    
    var initials: String{ //首字母
        get{
            guard let name = self.nickName else {
                return ""
            }
            return name.lowerInitials()
        }
    }
    
    init(id: String?, nickName: String?, group: String?) {  // 初始化
        self.userId = id
        self.nickName = nickName
        self.group = group
        self.isOnline = false
        self.isShowTip = false
        self.recentMessage = ""
        self.unreadMesNumber = 0
        self.date = ""
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let friend = IMFriend(id: self.userId, nickName: self.nickName, group: self.group)
        friend.isOnline = self.isOnline
        friend.isShowTip = self.isShowTip
        friend.recentMessage = self.recentMessage
        friend.unreadMesNumber = self.unreadMesNumber
        friend.date = self.date
        return friend
    }
}
