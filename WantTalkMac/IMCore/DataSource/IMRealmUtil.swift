//
//  IMRealmUtil.swift
//  IM
//
//  Created by 林海生 on 2017/5/23.
//  Copyright © 2017年 want. All rights reserved.
//

// 

import Foundation
import RealmSwift

class IMRealmUtil: NSObject {
    
    //add
    class func addObject(object: Object,update: Bool){
        let realm = try! RealmSwift.Realm()
        do{
            try realm.write {
                realm.add(object, update: update)
            }
        }catch{
            log.error("add\(Object.Type.self)--Realm数据库报错")
        }
    }
    
    //find
    class func findObjects(predicate: NSPredicate?,object: Object.Type)-> Results<Object>{
        
        let realm = try! RealmSwift.Realm()
        var friends:Results<Object>
        if predicate == nil{
            friends = realm.objects(object)
        }else{
            friends = realm.objects(object).filter(predicate!)
        }
        
        return friends
    }
    
    //update
    class func updateObject<T>(value: T,predicate: NSPredicate, object: Object.Type){
        let realm = try! RealmSwift.Realm()
        let objects = realm.objects(object).filter(predicate)
        guard objects.count > 0 else {
            return
        }
        do{
            try realm.write {
                realm.create(object, value: value, update: true)
            }
        }catch{
            log.error("update\(Object.Type.self)--Realm数据库报错")
        }
    }
    
    //delete
    class func deleteObject(predicate: NSPredicate, object: Object.Type){
        let realm = try! RealmSwift.Realm()
        let objects = realm.objects(object).filter(predicate)
        guard objects.count < 0 else {
            return
        }
        do{
            try realm.write {
                realm.delete(objects)
            }
        }catch{
            log.error("delete\(Object.Type.self)--Realm数据库报错")
        }
    }
}

