//
//  IMRoom.swift
//  BPM-T
//
//  Created by Jim.Yen on 2016/12/28.
//  Copyright © 2016年 com.want.mis.wantworld. All rights reserved.
//

import Foundation
import XMPPFramework

class IMRoom: NSObject {
    
    var roomName: String?
    var roomJid: XMPPJID?
    var roomJidString: String? {
        set{}
        get{ return self.roomJid!.bare() }
    }
    var roomPassword: String?
    
    init(roomName: String?, jid: XMPPJID?, password: String?) {
        super.init()
        self.roomName = roomName
        self.roomJid = jid
        self.roomPassword = password
    }
    init(jid: XMPPJID?) {
        super.init()
        self.roomJid = jid?.bare()
        self.roomName = jid?.user
    }
    init(room: XMPPRoom?) {
        super.init()
        self.roomJid = room?.roomJID
        self.roomName = room?.roomJID.user
    }
}
