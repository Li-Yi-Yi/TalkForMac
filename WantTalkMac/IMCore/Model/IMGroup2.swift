//
//  IMGroup2.swift
//  IM
//
//  Created by 林海生 on 2017/5/19.
//  Copyright © 2017年 want. All rights reserved.
//

 
import RealmSwift
import Realm

//好友分组
class IMGroup2: Object {
    
    dynamic var id: String? = nil             //用户id
    dynamic var groupName: String? = nil      // 分组名
    dynamic var isOpened: Bool = false         // 打开或者关闭分组
    dynamic var initials: String? = nil  // 首字母(排序)
    
    let friends = List<IMFriend2>()
    

    var isSelectAll: Bool = false
    
    func getByObject(isOpened: Bool, groupName: String?) {
        self.isOpened = isOpened
        self.groupName = groupName
        self.initials = self.groupName?.lowerInitials()
    }
    
    // 初始化分组
    convenience init(isOpened: Bool, groupName: String?) {
        self.init()
        self.id = IMSessionManager.sharedSessionManager.username
        self.isOpened = isOpened
        self.groupName = groupName
        self.initials = self.groupName?.lowerInitials()
    }
    
    
    required init(){
        super.init()
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    class func findObjects(format: String) -> Results<IMGroup2>{
        let predicate = NSPredicate(format: format)
        let realm = try! Realm()
        let friends = realm.objects(IMGroup2.self).filter(predicate)
        return friends
    }

}
