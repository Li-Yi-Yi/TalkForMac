//
//  IMZipManager.swift
//  IM
//
//  Created by 林海生 on 2017/7/6.
//  Copyright © 2017年 want. All rights reserved.
//

 
import Zip

class IMZipManager: NSObject {
    static let sharedZipManager: IMZipManager  = { IMZipManager() }()
    var logTxtPath: String?  //当天的日志地址
    var logPath: URL?    //日志文件夹地址URL
    var zipPath: URL?   //zip地址URL
    
    func zipLogFil(userId: String)-> String?{
        let cachePath = FileManager.default.urls(for: .cachesDirectory,
                                                 in: .userDomainMask)[0]
        let date: Date = Date()
        let fileFormatter: DateFormatter = DateFormatter()
        fileFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
        let time = fileFormatter.string(from: date)
        //日志文件夹地址
        self.logPath = cachePath.appendingPathComponent(userId)
        // 创建一个zip文件
        self.zipPath = cachePath.appendingPathComponent("\(userId) \(time)_i.zip")
        
        do {
            try Zip.zipFiles(paths: [self.logPath!], zipFilePath: self.zipPath!, password: nil, progress: nil)
            return self.zipPath!.path
        }catch {
            log.error("压缩日志文件失败")
        }
        
        return nil
    }
    
    //删除非今天的日志
    func deleteUnTadayLog(){
        let date: Date = Date()
        let logFormatter:DateFormatter = DateFormatter()
        logFormatter.dateFormat = "YYYY-MM-dd"
        let LogFile = logFormatter.string(from: date)
        
        let fileManager = FileManager.default
        let fileArray = fileManager.subpaths(atPath: self.logPath!.path)
        for fn in fileArray!{
            if fn.hasPrefix(LogFile){
                continue
            }
            if !fn.hasSuffix(".txt"){
                continue
            }
            do {
                try fileManager.removeItem(atPath: self.logPath!.path + "/\(fn)")
            }catch{
                log.error("删除非今天的日志 失败")
            }
        }
    }
    
    
    func deleteZipFile(){
        do {
            try FileManager.default.removeItem(atPath: self.zipPath!.path)
        }catch{
            log.error("删除非今天的日志 失败")
        }
    }
}
