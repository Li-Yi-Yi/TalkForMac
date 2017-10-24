//
//  IMRxManager.swift
//  IM
//
//  Created by 林海生 on 2017/7/28.
//  Copyright © 2017年 want. All rights reserved.
//

 
import RxSwift
import Kingfisher
#if TARGET_OS_IOS
import UIKit
#else
import AppKit
#endif

class IMRxManager: NSObject {
    static let sharedRxManager: IMRxManager  = { IMRxManager() }()
    
    
    //根据内外网判断头像
    #if TARGET_OS_IOS
    func observableGender(id userId: String, subject: PublishSubject<UIImage>){
        if IMTokenManager.sharedTokenManager.getInterfaces() {
            if UserDefaults.standard.bool(forKey: "\(IMUserAvatar)\(userId)") {
                if let image = self.headerImagePath(imageName: userId){
                     subject.onNext(image)
                }else{
                    subject.onNext(UIImage(named: "wz")!)
                }
            } else {
                let image = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") == "2" ? UIImage(named: "wn") : UIImage(named: "wz")
                subject.onNext(image!)
                
                let url = "\(IMSessionManager.sharedSessionManager.userAvatarURL!)\(userId)"
                let iamgeView = UIImageView()
                
                iamgeView.kf.setImage(with: URL(string: url), placeholder: image, options: [.transition(ImageTransition.fade(0.1))], progressBlock: nil, completionHandler: { [weak self](image, error, cacheType, url) in
                    guard let strongSelf = self else { return }
                    if image != nil {
                        subject.onNext(strongSelf.addLocalHeaderImageToFile(headerImage: image!, imageName: userId)!)
                    }else{
                        if  let isWZ = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") {
                            subject.onNext((isWZ == "2" ? UIImage(named: "wn") : UIImage(named: "wz"))!)
                        }else{
                            IMObjectManager.sharedObjectManager.taskToFetchFriendGender(id: userId).continueWith(continuation: { [weak subject](task) in
                                guard let strongSubject = subject else{return}
                                if task.error != nil {
                                    strongSubject.onNext(UIImage(named: "wz")!)
                                }else{
                                    if task.result == "2"{
                                        strongSubject.onNext(UIImage(named: "wn")!)
                                        UserDefaults.standard.set("2", forKey: "\(IMUserGender)\(userId)")
                                    }else if task.result == "1"{
                                        strongSubject.onNext(UIImage(named: "wz")!)
                                        UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                                    }else{
                                        strongSubject.onNext(UIImage(named: "wz")!)
                                        UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                                    }
                                }
                            })
                        }
                    }
                })
            }
        } else {
            if let gender = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") {
                subject.onNext((gender == "2" ? UIImage(named: "wn") : UIImage(named: "wz"))!)
            }else{
                IMObjectManager.sharedObjectManager.taskToFetchFriendGender(id: userId).continueWith(continuation: { [weak subject](task) in
                    guard let strongSubject = subject else{return}
                    if task.error != nil {
                        strongSubject.onNext(UIImage(named: "wz")!)
                    }else{
                        if task.result == "2"{
                            strongSubject.onNext(UIImage(named: "wn")!)
                            UserDefaults.standard.set("2", forKey: "\(IMUserGender)\(userId)")
                        }else if task.result == "1"{
                            strongSubject.onNext(UIImage(named: "wz")!)
                            UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                        }else{
                            strongSubject.onNext(UIImage(named: "wz")!)
                            UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                        }
                    }
                })
            }
        }
    }
    
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
            var headerImage = headerImage
            if headerImage.size.width > headerImage.size.height{
                headerImage = UIImage(cgImage: headerImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.upMirrored)
            }
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsURL.appendingPathComponent("\(imageName).png")
            let image = headerImage.im_imageToResizeWithSize(size: CGSize(width: 200, height: 200), compressionQuality: 0.5)
            if let pngImageData = UIImagePNGRepresentation(image!) {
                try pngImageData.write(to: fileURL, options: .atomic)
                UserDefaults.standard.set(true, forKey: "\(IMUserAvatar)\(imageName)")
            }
            
            return image
        } catch {
            return nil}
    }
    #else
    func observableGender(id userId: String, subject: PublishSubject<NSImage>){
        
        if IMTokenManager.sharedTokenManager.getInterfaces() {
            
            if UserDefaults.standard.bool(forKey: "\(IMUserAvatar)\(userId)") {
                if let image = self.headerImagePath(imageName: userId){
                    subject.onNext(image)
                }else{
                    subject.onNext(NSImage(named: "wz")!)
                }
            } else {
                let image = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") == "2" ? NSImage(named: "wn") : NSImage(named: "wz")
                subject.onNext(image!)
                
                let url = "\(IMSessionManager.sharedSessionManager.userAvatarURL!)\(userId)"
                
                let imageView = NSImageView()
            
                imageView.kf.setImage(with: URL(string: url), placeholder: image, options: [.transition(ImageTransition.none)], progressBlock: nil, completionHandler: { [weak self](image, error, cacheType, url) in
                
                    guard let strongSelf = self else { return }
                    if image != nil {
                        subject.onNext(strongSelf.addLocalHeaderImageToFile(headerImage: image!, imageName: userId)!)
                    }else{
                        if  let isWZ = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") {
                            subject.onNext((isWZ == "2" ? NSImage(named: "wn") : NSImage(named: "wz"))!)
                        }else{
                            IMObjectManager.sharedObjectManager.taskToFetchFriendGender(id: userId).continueWith(continuation: { [weak subject](task) in
                                guard let strongSubject = subject else{return}
                                if task.error != nil {
                                    strongSubject.onNext(NSImage(named: "wz")!)
                                }else{
                                    if task.result == "2"{
                                        strongSubject.onNext(NSImage(named: "wn")!)
                                        UserDefaults.standard.set("2", forKey: "\(IMUserGender)\(userId)")
                                    }else if task.result == "1"{
                                        strongSubject.onNext(NSImage(named: "wz")!)
                                        UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                                    }else{
                                        strongSubject.onNext(NSImage(named: "wz")!)
                                        UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                                    }
                                }
                            })
                        }
                    }
                })
            }
        } else {
            if let gender = UserDefaults.standard.string(forKey: "\(IMUserGender)\(userId)") {
                subject.onNext((gender == "2" ? NSImage(named: "wn") : NSImage(named: "wz"))!)
            }else{
                IMObjectManager.sharedObjectManager.taskToFetchFriendGender(id: userId).continueWith(continuation: { [weak subject](task) in
                    guard let strongSubject = subject else{return}
                    if task.error != nil {
                        strongSubject.onNext(NSImage(named: "wz")!)
                    }else{
                        if task.result == "2"{
                            strongSubject.onNext(NSImage(named: "wn")!)
                            UserDefaults.standard.set("2", forKey: "\(IMUserGender)\(userId)")
                        }else if task.result == "1"{
                            strongSubject.onNext(NSImage(named: "wz")!)
                            UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                        }else{
                            strongSubject.onNext(NSImage(named: "wz")!)
                            UserDefaults.standard.set("1", forKey: "\(IMUserGender)\(userId)")
                        }
                    }
                })
            
            
            }
        
        }
    }
    // 获取头像路径
    func headerImagePath(imageName: String) -> NSImage? {
        
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
    // 存入本地头像
    // macOS：使用者關聯的app資料會存在/User/Library/Application Support/[AppName]
    func addLocalHeaderImageToFile(headerImage: NSImage, imageName: String) -> NSImage? {
        
        do {
            // 取得App名稱
            let infos = Bundle.main.infoDictionary
            let AppName : String = infos?[kCFBundleNameKey as String] as! String
            
            
            //var headerImage = headerImage
            if headerImage.size.width > headerImage.size.height{
                // Why?
                //headerImage = UIImage(cgImage: headerImage.cgImage!, scale: 1.0, orientation: UIImageOrientation.upMirrored)
            }
            
            
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
            return nil}
    }
    #endif
}
