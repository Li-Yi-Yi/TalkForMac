//
//  macUUID.m
//  TalkClient
//
//  Created by 吳淑菁 on 2017/9/12.
//
//

#include "macUUID.h"
#if TARGET_OS_IOS
#else
#import <IOKit/IOKitLib.h>
#endif
#import <Foundation/Foundation.h>


@implementation macUUID

+(NSString *)getMacIndentifier {
    
#if TARGET_OS_IOS
    
    return nil
    
#else
    kern_return_t             kernResult;
    mach_port_t               master_port;
    CFMutableDictionaryRef    matchingDict;
    io_iterator_t             iterator;
    io_object_t               service;
    CFDataRef                 macAddress = nil;
    
    
    kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
    
    if (kernResult != KERN_SUCCESS) {
        
        printf("IOMasterPort returned %d\n", kernResult);
        return nil;
        
    }
    
    
    matchingDict = IOBSDNameMatching(master_port, 0, "en0");
    
    if (!matchingDict) {
        
        printf("IOBSDNameMatching returned empty dictionary\n");
        return nil;
        
    }
    
    
    kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
    
    if (kernResult != KERN_SUCCESS) {
        
        printf("IOServiceGetMatchingServices returned %d\n", kernResult);
        
        return nil;
        
    }
    
    
    while((service = IOIteratorNext(iterator)) != 0) {
        
        io_object_t parentService;
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane,&parentService);
        
        if (kernResult == KERN_SUCCESS) {
            
            if (macAddress) CFRelease(macAddress);
            macAddress = (CFDataRef) IORegistryEntryCreateCFProperty(parentService,CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
            
            IOObjectRelease(parentService);
            
        } else {
            
            printf("IORegistryEntryGetParentEntry returned %d\n", kernResult);
            
        }
        
        IOObjectRelease(service);
        
    }
    
    IOObjectRelease(iterator);
    
    NSData *macData = (__bridge_transfer NSData *) macAddress;
    if ([macData length] < 1) return nil;
    const UInt8 *bytes = [macData bytes];
    NSMutableString *result = [NSMutableString string];
    for (int i= 0;i< [macData length];i++) {
        if ([result length] != 0)
            [result appendFormat:@":%02hhx",bytes[i]];
        else
            [result appendFormat:@"%02hhx",bytes[i]];
    }
    
    
    return result;
#endif
    
}

@end
