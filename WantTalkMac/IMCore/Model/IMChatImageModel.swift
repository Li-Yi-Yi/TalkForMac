//
//  ChatImageModel.swift
//  IM
//
//  Created by miler on 2017/3/29.
//  Copyright © 2017年 want. All rights reserved.
//

import Foundation
#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

class IMChatImageModel: NSObject {
    var imageHeight : CGFloat?
    var imageWidth : CGFloat?
    var imageId : String?
    var originalURL : String?
    var thumbURL : String?
    var localStoreName: String?  //拍照，选择相机的图片的临时名称
    #if TARGET_OS_IOS
    var localThumbnailImage: UIImage? {  //从 Disk 加载出来的图片
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
            return UIImage(contentsOfFile: path!)
        } else {
            return nil
        }
    }
    #else
    var localThumbnailImage: NSImage? {
        if let theLocalStoreName = localStoreName {
            let path = ImageFilesManager.cachePathForKey(theLocalStoreName)
                return NSImage.init(contentsOfFile: path!)
        } else {
            return nil
        }
    }
    #endif
    override init() {
        super.init()
    }
}
