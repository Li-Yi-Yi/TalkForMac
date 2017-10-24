//
//  IMUpLoadFileManager.swift
//  IM
//
//  Created by miler on 2017/3/31.
//  Copyright © 2017年 want. All rights reserved.
//
// macOS: 還無法確定是否使用CkoSFtp，暫時先註解

import Foundation

//聊天图片sftp
let userName: String = "imuser"
let password: String = "IM=-User"
//日志sftp
let logUserName: String = "LogUser"
let logPassword: String = "Log=-User"
//chilkat的code
let ChilkatCode: String = "WANTWA.SS1082018_FAdGYQkuR49e"

/// 文件上传管理类
class IMUpLoadFileManager: NSObject {
    
    //let sftp = CkoSFtp()!
    private var port: Int!
    private var hostname: String!
    
    static let sharedFileManager: IMUpLoadFileManager = { IMUpLoadFileManager() } ()
    
    
    /// 判断Ftp连接状态
    ///
    /// - Returns: 成功连接
    func checkFtpStatus() -> Bool {/*
        var success: Bool = sftp.unlockComponent(ChilkatCode)
        guard success != false  else {
            print("\(sftp.lastErrorText)")
            return false
        }
        
        sftp.connectTimeoutMs = 5000
        sftp.idleTimeoutMs = 10000
        
        self.hostname = "coop.want-want.com"
        self.port = 22
        
        guard sftp.connect(hostname, port: port as NSNumber) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
        //判断登录
        guard sftp.authenticatePw(userName, password: password) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
        
        //初始化sftp
        success = sftp.initializeSftp()
        if success != true {
            print("\(sftp.lastErrorText)")
            return false
        }
        */
        return true
    }
    
    /// 上传文件
    ///
    /// - Parameters:
    ///   - fileName: 文件名称
    ///   - filePath: 文件本地路径
    /// - Returns: 返回成功
    func uploadFile(fileName: String,filePath: String) -> Bool {
        /*
        guard sftp.uploadFile(byName: fileName, localFilePath: filePath) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
         */
        return true
    }
    
    /// 根据服务器文件名字下载文件
    ///
    /// - Parameters:
    ///   - fileName: 文件名字
    ///   - localFilePath: 本地存储位置
    /// - Returns: 返回的结果状态
    func downLoadFileForName(fileName: String?, localFilePath: String?) -> Bool {
        /*
        guard sftp.downloadFile(byName: fileName, localFilePath: localFilePath) else {
            print("\(sftp.lastErrorText)")
            return false
        }
         */
        return true
    }
    
    func checkLogFtpStatus() -> Bool {
        /*
        var success: Bool = sftp.unlockComponent(ChilkatCode)
        guard success != false  else {
            print("\(sftp.lastErrorText)")
            return false
        }
        
        sftp.connectTimeoutMs = 5000
        sftp.idleTimeoutMs = 10000
        
        self.hostname = "10.1.0.218"
        self.port = 22
        
        guard sftp.connect(hostname, port: port as NSNumber) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
        //判断登录
        guard sftp.authenticatePw(logUserName, password: logPassword) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
        
        //初始化sftp
        success = sftp.initializeSftp()
        if success != true {
            print("\(sftp.lastErrorText)")
            return false
        }
        */
        return true
    }
    
    /// 上传Log文件
    ///
    /// - Parameters:
    ///   - fileName: 文件名称
    ///   - filePath: 文件本地路径
    /// - Returns: 返回成功
    func uploadLogFile(fileName: String,filePath: String) -> Bool {
        /*
        guard sftp.uploadFile(byName: fileName, localFilePath: filePath) != false else {
            print("\(sftp.lastErrorText)")
            return false
        }
         */
        return true
    }
    
}
