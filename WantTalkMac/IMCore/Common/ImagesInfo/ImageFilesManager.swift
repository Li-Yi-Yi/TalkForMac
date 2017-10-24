//
//  ImageFilesManager.swift
//  TSWeChat
//
//  Created by Hilen on 2/24/16.
//  Copyright © 2016 Hilen. All rights reserved.
//

import Foundation
import Kingfisher
#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

/*
    围绕 Kingfisher 构建的缓存器，先预存图片名称，等待上传完毕后改成 URL 的名字。
    https://github.com/onevcat/Kingfisher/blob/master/Sources%2FImageCache.swift#l625
*/

class ImageFilesManager {
    let imageCacheFolder = KingfisherManager.shared.cache
    
    @discardableResult
    class func cachePathForKey(_ key: String) -> String? {
        let fileName = key.ts_MD5String
        return (KingfisherManager.shared.cache.diskCachePath as NSString).appendingPathComponent(fileName)
    }
    #if TARGET_OS_IOS
    class func storeImage(_ image: UIImage, key: String, completionHandler: (() -> ())?) {
        KingfisherManager.shared.cache.removeImage(forKey:key)
        KingfisherManager.shared.cache.store(image, forKey: key, toDisk: true, completionHandler: completionHandler)
    }
    #else
    class func storeImage(_ image: NSImage, key: String, completionHandler: (() -> ())?) {
        KingfisherManager.shared.cache.removeImage(forKey:key)
        KingfisherManager.shared.cache.store(image, forKey: key, toDisk: true, completionHandler: completionHandler)
    }
    #endif
    
    //获取接收图片/文件 的存储路径
    class func getImagePathForPhotoName(_ photoName: String) -> String? {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!+photoName
    }
    
    class func getImagePathForPhotoUrl(_ photoName: String?) -> URL {
        let fileManager = FileManager.default
        let url = fileManager.urls(for: .cachesDirectory, in: .allDomainsMask).first?.appendingPathComponent(photoName!)
        return url!
    }
    
    /**
     修改文件名称
     
     - parameter originPath:      原路径
     - parameter destinationPath: 目标路径
     
     - returns: 目标路径
     */
    @discardableResult
    class func renameFile(_ originPath: URL, destinationPath: URL) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: originPath.path, toPath: destinationPath.path)
            return true
        } catch let error as NSError {
            print("\(error)")
            return false
        }
    }
}





