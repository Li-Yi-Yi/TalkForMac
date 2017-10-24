//
//  IMTokenManager.swift
//  IM
//
//  Created by 刘表聪 on 17/2/14.
//  Copyright © 2017年 want. All rights reserved.
//

import SystemConfiguration.CaptiveNetwork
import Foundation
#if TARGET_OS_IOS
#else
import CoreWLAN
import IOKit
#endif


/**
 *  获取token，IP 地址等一些值
 */

let kAuthToken: String = "auth_token";

class IMTokenManager: NSObject {
    
    var token: String?
    
    var localPath: String?
    
    var imchatModel: IMChat!
    
    
    
    // MARK: @单例
    static let sharedTokenManager: IMTokenManager  = { IMTokenManager() }()
    
    func getUUID() -> String {
    #if TARGET_OS_IOS
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        return deviceID
    #endif
        //  use MAC address as UUID
        return macUUID.getMacIndentifier()
    }
    
    
    // 获取当前wifi的IP地址
    func getLocalIPAddressForCurrentWiFi() -> String? {
        var address: String?
        
        // get list of all interfaces on the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        guard getifaddrs(&ifaddr) == 0 else {
            return nil
        }
        guard let firstAddr = ifaddr else {
            return nil
        }
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            
            let interface = ifptr.pointee
            
            // Check for IPV4 or IPV6 interface
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // Check interface name
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    
                    // Convert interface address to a human readable string
                    var addr = interface.ifa_addr.pointee
                    var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(&addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostName, socklen_t(hostName.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostName)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
    
    // 根据网址请求 获取IP地址
    func getIPAddressFromDNSQuery(url: String) -> String? {
        let host = CFHostCreateWithName(nil, url as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean =  false
        if let address = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?, let theAddress = address.firstObject as? NSData {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(theAddress.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                let numAddress = String(cString: hostname)
                return numAddress
            }
            return nil
        }
        
        return nil
    }
    
    func isIntranetName() -> Bool {
        #if TARGET_OS_IOS
        if let cfas: Array = CNCopySupportedInterfaces() as Array? {
            for cfa in cfas {
                
                if let dict = CFBridgingRetain(CNCopyCurrentNetworkInfo(cfa as! CFString)) {
                    if let ssid = dict["SSID"] as? String {
                        let subString = (ssid as NSString).contains("want")
                        if subString {
                            return true
                        }
                    }
                }
                
            }
        }
        #else
            return self.getInterfaces()
        #endif
        
    }
    
    // MARK: - 根据当前wifiip地址是否是内网wifi
    func getInterfaces() -> Bool {
    #if TARGET_OS_IOS
        guard let unwrappedCFArrayInterfaces = CNCopySupportedInterfaces() else {
            return false
        }
        guard let swiftInterfaces = (unwrappedCFArrayInterfaces as NSArray) as? [String] else {
            return false
        }
        for interface in swiftInterfaces {
            
            guard let unwrappedCFDictionaryForInterface = CNCopyCurrentNetworkInfo(interface as CFString) else {
                return false
            }
            guard let SSIDDict = (unwrappedCFDictionaryForInterface as NSDictionary) as? [String: AnyObject] else {
                return false
            }
            
            if let wifiName: String = SSIDDict["SSID"] as? String {
                if wifiName.localizedCaseInsensitiveContains("want") {
                    return true
                }
            }
        
        }
    
    #else
        // 從CoreWLAN取得wifi資料
        let client = CWWiFiClient.shared()
        for interface in client.interfaces()! {
            print(interface.ssid() ?? "none")
            
            if let wifiName: String = interface.ssid() {
                if wifiName.localizedCaseInsensitiveContains("want") {
                    return true
                }
            }
        }
        #endif

        return false
    }

}

