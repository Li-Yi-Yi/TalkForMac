//
//  IMAddGroupChatSelectModel.swift
//  BPM-T
//
//  Created by Jim.Yen on 2017/1/4.
//  Copyright © 2017年 com.want.mis.wantworld. All rights reserved.
//

import Foundation

class IMAddGroupChatSelectModel: NSObject {
    var friendModel: IMFriend2?
    var friendDetail: IMFriendDetail?
    var id: String? {
        get{
            return self.friendModel!.userId!
        }
    }
    var name: String? {
        get{
            return friendModel!.nickName!
        }
    }
    var onSelected: Bool?
    
    init(friend: IMFriend2) {
        super.init()
        self.friendModel = friend
        self.onSelected = false
    }
    
    init(friendDetail: IMFriendDetail) {
        super.init()
        self.friendModel = IMFriend2(id: "\(friendDetail.id!)@coop", nickName: friendDetail.name!)
        self.friendDetail = friendDetail
        self.onSelected = false
    }
}
