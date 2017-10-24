//
//  IMFriendStatus.swift
//  IM
//
//  Created by 刘表聪 on 16/11/10.
//  Copyright © 2016年 want. All rights reserved.
//

import Foundation

/**
 *  好友状态model
 */
class IMFriendStatus: NSObject {
    
    var userId: String?       // 好友id
    var isOnline = false      // 好友是否在线
    var isApplyAdded = false  // 是否是申请添加
    var isFinishAdded = false //手动操作添加好友时(二次验证bug)添加判断，完成添加好友时为
    var applyString: String?  // 申请说明
    var nickName: String?     // 备注名
    
    init(id: String?, isOnlineStatus: Bool) {
        self.userId = id! + "@coop"
        self.isOnline = isOnlineStatus
    }
    
    init(id: String?, isApplyAdded: Bool) {
        self.userId = id
        self.isApplyAdded = isApplyAdded
    }
}
