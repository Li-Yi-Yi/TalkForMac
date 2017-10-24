//
//  IMXMPPManager+addition.swift
//  IM
//
//  Created by 刘表聪 on 17/3/21.
//  Copyright © 2017年 want. All rights reserved.
//

// macOS：使用者關聯的app資料會存在/User/Library/Application Support/[AppName]

#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

extension IMXMPPManager {
    #if TARGET_OS_IOS
    // 获取头像路径
    func headerImagePath(imageName: String) -> UIImage? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsURL.appendingPathComponent("\(imageName).png").path
        if FileManager.default.fileExists(atPath: filePath) {
            return UIImage(contentsOfFile: filePath)
        } else {
            return nil
        }
    }
    
    // 存入本地头像
    func addLocalHeaderImageToFile(headerImage: UIImage, imageName: String) -> UIImage? {
        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("\(imageName).png")
            let image = headerImage.im_imageToResizeWithSize(size: CGSize(width: 200, height: 200), compressionQuality: 0.5)
            if let pngImageData = UIImagePNGRepresentation(image!) {
                try pngImageData.write(to: fileURL, options: .atomic)
                UserDefaults.standard.set(true, forKey: "\(IMUserAvatar)\(imageName)")
            }
            return image
        } catch {
            return nil
        }
    }
    #else
    func headerImagePath(imageName: String) -> NSImage?{
        
        // 取得App名稱
        let infos = Bundle.main.infoDictionary
        let AppName : String = infos?[kCFBundleNameKey as String] as! String
        
        let applicationSupportDirURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dirURL = applicationSupportDirURL.appendingPathComponent(AppName)
        let filePath = dirURL.appendingPathComponent("\(imageName).png").path
        if FileManager.default.fileExists(atPath: filePath) {
            return NSImage(contentsOfFile: filePath)
        } else {
            return nil
        }

    }
    func addLocalHeaderImageToFile(headerImage: NSImage, imageName: String) -> NSImage? {
        do {
            // 取得App名稱
            let infos = Bundle.main.infoDictionary
            let AppName : String = infos?[kCFBundleNameKey as String] as! String
        
            //  find image in /User/Library/Application Support/ApplicationName
            let applicationSupportDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dirURL = applicationSupportDirURL.appendingPathComponent(AppName)
            let fileURL = dirURL.appendingPathComponent("\(imageName).png")
            
            let image = headerImage.im_imageToResizeWithSize(size: CGSize(width: 200, height: 200))
            if let pngImageData = image?.png { //UIImagePNGRepresentation(image!) {
                try pngImageData.write(to: fileURL, options: .atomic)
                UserDefaults.standard.set(true, forKey: "\(IMUserAvatar)\(imageName)")
            }
            
            return image
        } catch {
            return nil
        }
    }
    #endif
    
    
}
