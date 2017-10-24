//
//  IMFriendsManager.swift
//  IM
//
//  Created by 林海生 on 2017/5/19.
//  Copyright © 2017年 want. All rights reserved.
//test111


import Foundation
import RealmSwift

class IMFriendsManager: NSObject {
    
    let realm = try! Realm()
    
    var testIdGroup = [IMFriend2]() //验证好友分组 (当离线时 被删除好友，会导致自己好友列表还存在好友，用于存放临时好友进行验证。)
    let sessionManage = IMSessionManager.sharedSessionManager
    // MARK: @单例
    static let sharedFriendManager: IMFriendsManager  = { IMFriendsManager() }()
    
    //获取好友所在indexPath以及分组
    func getIndexPathAtId(id: String)-> (IMFriend2, IndexPath?)?{
        let group = self.getGroups()
        if group.count == 0 {
            return nil
        }
        for (index, item) in group.enumerated() {
            let group = item as! IMGroup2
            let friends = group.friends.sorted(by: ["initials"])
            for (index1, item1) in friends.enumerated() {
                if id == item1.userId! {
                    return (item1, IndexPath(item: index1, section: index))
                }
            }
        }
        return nil
    }
    
    //根据id删除好友
    func removeFriendBy(id: String){
        let groups = self.getGroups()
        for item in groups{
            let group = item as! IMGroup2
            for (index, friend) in group.friends.enumerated(){
                if friend.userId == id {
                    do{
                        try realm.write {
                            group.friends.remove(objectAtIndex: index)
                            if group.friends.count == 0{
                                realm.delete(group)
                            }
                        }
                    }catch{
                        log.error("更具id删除好友")
                    }

                }
            }
        }
        
    }

    
    // 删除多出来的好友(离线时被删除)
    func deleteNoneFriend(){ //
        guard self.testIdGroup.count > 0 else{
            return
        }
        
        let groups = self.getGroups()
        var friends = [IMFriend2]()
        
        for item in groups{
            let group = item as! IMGroup2
            friends += group.friends
            if group.friends.count == 0{
                let realm = try! Realm()
                try! realm.write {
                    realm.delete(group)
                }
            }
        }
     
        for testFriend in friends{
            var has = false
            for friend in self.testIdGroup{
                if testFriend.userId == friend.userId{
                    has = true
                    break
                }
            }
            if has{
                continue
            }
            self.removeFriendBy(id: testFriend.userId!)
        }
        
        self.testIdGroup.removeAll()
    }
    
    
    func addFriendAndGroup(friend: IMFriend2,groupName: String?){
        self.testIdGroup.append(friend)
        
        let groupStr = groupName == nil ? "我的好友" : groupName!
        
        let predicate = NSPredicate(format: "userId = %@", friend.userId!)//好友查询
        let predicate2 = NSPredicate(format: "groupName = %@ AND id = %@", groupStr, sessionManage.username!) //分组查询
        
        //查询当前帐号下，是否存在分组
        let oldFriends = realm.objects(IMFriend2.self).filter(predicate)
        let oldGroups = realm.objects(IMGroup2.self).filter(predicate2)
        
        
        do{
            try realm.write {
                if oldFriends.count == 0{
                    realm.add(friend)
                }else{
                    oldFriends.first?.nickName = friend.nickName
                    oldFriends.first?.myId = IMSessionManager.sharedSessionManager.username!
                }
            }
        }catch{
            log.error("添加好友")
        }
    
        do{
            if oldGroups.count == 0 {
                //添加分组
                let group = IMGroup2(isOpened: false, groupName: groupStr)
                try realm.write {
                    realm.add(group)
                    oldGroups.first?.friends.append(oldFriends.first!)
                }
            }else{
                let inFriend = oldGroups.first?.friends.filter(predicate)
                if inFriend?.count == 0{
                    try realm.write {
                        oldGroups.first?.friends.append(oldFriends.first!)
                    }
                }
            }
        }catch{
            log.error("分组添加好友")
        }
    }

    func addfriend(friend: IMFriend2, isInterim: Bool = false){
        let predicate = NSPredicate(format: "userId = %@", friend.userId!)
        //查询当前帐号下，是否存在
        let oldFriend = realm.objects(IMFriend2.self).filter(predicate)
        
        do{
            try realm.write {
                if oldFriend.count == 0 {
                    realm.add(friend)
                }else{
                    //同步好友备注名(其它设备 修改备注名时)
                    oldFriend.first?.name = friend.name
                    if isInterim {
                        oldFriend.first?.myId = IMSessionManager.sharedSessionManager.username!
                        oldFriend.first?.nickName = friend.name
                    }else{
                        oldFriend.first?.myId = IMSessionManager.sharedSessionManager.username!
                        oldFriend.first?.nickName = friend.nickName
                    }
                }
            }
        }catch{
            log.error("添加好友")
        }
    }

    func addGroup(groupName: String?){
        let groupStr = groupName == nil ? "我的好友" : groupName!
        
        let predicate = NSPredicate(format: "groupName = %@ AND id = %@", groupStr, sessionManage.username!)
        //查询当前帐号下，是否存在分组
        let oldGroups = realm.objects(IMGroup2.self).filter(predicate)
        
        if oldGroups.count == 0 {
            //添加分组
            let group = IMGroup2(isOpened: false, groupName: groupStr)
            do{
                try realm.write {
                    realm.add(group)
                }
            }catch{
                log.error("添加分组")
            }
        }
    }
    
    func allFriendsUnLine(){//所有好友下线
        let friends = IMRealmUtil.findObjects(predicate: nil, object: IMFriend2.self)
        do{
            try realm.write {
                for friend in friends{
                    (friend as! IMFriend2).unOnline = true
                }
            }
        }catch{
            log.error("所有好友下线")
        
        }
    }
    
    func removeGroupFriends(){//删除所有好友
        let predicate = NSPredicate(format: "id = %@",sessionManage.username!)
        //查询当前帐号下，是否存在分组
        let oldGroups = realm.objects(IMGroup2.self).filter(predicate)
        
        if oldGroups.count == 0 {
            return
        }else{
            do{
                try realm.write {
                    for group in oldGroups{
                        group.friends.removeAll()
                    }
                }
            }catch{
                log.error("删除所有好友")
            }
        }
    }
     
    
    
    //好友查询
    func findFriendBy(id: String)-> IMFriend2?{
        let predicate = NSPredicate(format: "userId = %@", id)
        let friend = IMRealmUtil.findObjects(predicate: predicate, object: IMFriend2.self).first
        return friend as? IMFriend2
    }
    
    //分组所有查询
    func getGroups()-> Results<Object>{
        let predicate = NSPredicate(format: "id = %@",sessionManage.username!)
        let objects = IMRealmUtil.findObjects(predicate: predicate, object: IMGroup2.self).sorted(byKeyPath: "initials", ascending: true)
        return objects
    }
    
    //查询某个分组
    func findGroup(groupName: String)-> IMGroup2?{
        let group = self.getGroups().filter(NSPredicate(format: "groupName = %@", groupName))
        if group.count > 0{
            return group.first as? IMGroup2
        }
        return nil
        
    }

    func updateFriend<T>(value: T,id: String){
        let predicate = NSPredicate(format: "userId = %@",id)
        IMRealmUtil.updateObject(value: value, predicate: predicate, object: IMFriend2.self)
    }
    
    //好友移动(单人)
    func mobileFrined(groupName: String,toName: String,friend: IMFriend2){
        let group = self.findGroup(groupName: groupName)
        let friends = group?.friends
        try! realm.write {
            for (index, item) in friends!.enumerated(){
                if item.userId == friend.userId{
                    friends?.remove(objectAtIndex: index)
                }
            }
            if friends?.count == 0{
                realm.delete(group!)
            }
        }
        
        IMXMPPManager.sharedXmppManager.addFriendWithUserId(userId: friend.userId, friendName: friend.nickName!, groupName: toName)
    }
    
    //修改备注名
    func updateRemark(friend: IMFriend2,remarkName: String,groupName: String){
        IMXMPPManager.sharedXmppManager.addFriendWithUserId(userId: friend.userId!, friendName: remarkName, groupName: groupName)
    }
    
    //修改分组名
    func updateGroupName(groupName: String,toName: String){
        let group = self.findGroup(groupName: groupName)
        let realm = try! Realm()
        try! realm.write {
            group?.groupName = toName
        }
        
        for friend in group!.friends {
             IMXMPPManager.sharedXmppManager.addFriendWithUserId(userId: friend.userId, friendName: friend.nickName!, groupName: toName)
        }
    }
    
    //删除分组
    func deleteGroupName(groupName: String){
        guard let group = self.findGroup(groupName: groupName) else{
            return
        }
        for f in group.friends {
            IMXMPPManager.sharedXmppManager.addFriendWithUserId(userId: f.userId, friendName: f.nickName!, groupName: "我的好友")
        }
        try! realm.write {
            realm.delete(group)
        }
    }
    
    
    //删除所有分组
    func deleteAllGroup(){
        let predicate = NSPredicate(format: "id = %@",sessionManage.username!)
        //查询当前帐号下，是否存在分组
        let oldGroups = realm.objects(IMGroup2.self).filter(predicate)
        
        if oldGroups.count == 0 {
            return
        }else{
            do{
                try realm.write {
                    realm.delete(oldGroups)
                }
            }catch{
                log.error("删除所有分组")
            }
        }
    }
    
}
