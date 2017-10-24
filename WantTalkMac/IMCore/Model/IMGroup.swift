//
//  IMGroup.swift
//  IM
//
//  Created by 刘表聪 on 16/11/7.
//  Copyright © 2016年 want. All rights reserved.
//

import Foundation

/**
 *  分组model
 */
class IMGroup: NSObject {

    var isOpened: Bool          // 打开或者关闭分组
    var groupName: String?      // 分组名
    var friends = [IMFriend]()  // 分组下面的好友数组
    var onlineCount: Int = 0    // 在线的个数
    var isSelectAll: Bool = false
    
    // 初始化分组
    init(isOpened: Bool, groupName: String?) {
        self.isOpened = isOpened
        self.groupName = groupName
    }
    
    init(isOpened: Bool, groupName: String?, selectAll: Bool) {
        self.isOpened = isOpened
        self.groupName = groupName
        self.isSelectAll = selectAll
    }
    
    // 添加好友到分组里面
    func addFriend(friend: IMFriend) {
        if self.friends.isEmpty {
            self.friends.append(friend)
            return
        }
        var flag = false
        for (index, item) in self.friends.enumerated() {
            if friend.userId == item.userId {
                self.friends[index].nickName = friend.nickName
                self.friends[index].group = friend.group
                flag = false
                break
            } else {
                flag = true
            }
        }
        if flag {
            self.friends.append(friend)
        }
    }
    
    // 从分组里面删除好友
    func deleteFriend(friend: IMFriend) {
        for (index, item) in self.friends.enumerated() {
            if friend.userId == item.userId {
                self.friends.remove(at: index)
                break
            }
        }
    }

}
