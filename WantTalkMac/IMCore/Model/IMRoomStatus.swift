//
//  IMRoomStatus.swift
//  IM
//
//  Created by 林海生 on 2017/6/6.
//  Copyright © 2017年 want. All rights reserved.
//

 import Foundation

//群聊邀请
class IMRoomStatus: NSObject, NSCoding {
    enum RoomStatus: String {
        case defaultType = "0", agree = "1", reject = "2"//状态  defaultType:未处理  agree：同意 reject：拒绝
    }
    
    var roomName: String! //群聊名称
    var jidString: String{
        get{
            return self.roomName+"@conference.coop"
        }
    }
    
    var status : RoomStatus{
        get{
            switch statusStr {
            case "0":
                return .defaultType
            case "1":
                return .agree
            case "2":
                return .reject
            default:
                return .defaultType
            }
        }
    }
    
    var statusStr: String!

    init(roomName: String){
        super.init()
        self.roomName = roomName
        self.statusStr = "0"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(roomName, forKey: "roomName")
        aCoder.encode(statusStr, forKey: "statusStr")
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        roomName = aDecoder.decodeObject(forKey: "roomName") as! String?
        statusStr = aDecoder.decodeObject(forKey: "statusStr") as! String?
    }
    
}
