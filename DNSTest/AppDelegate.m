//
//  AppDelegate.m
//  DNSTest
//
//  Created by lujb on 15/6/18.
//  Copyright (c) 2015年 lujb. All rights reserved.
//

#import "AppDelegate.h"
#import <resolv.h>
#include <arpa/inet.h>


#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>

#import  <CFNetwork/CFHost.h>
#import <netinet/in.h>
#import <netdb.h>
#import <SystemConfiguration/SystemConfiguration.h>



#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <err.h>
@interface AppDelegate ()

@end

@implementation AppDelegate

-(NSString*) getAddressFromArray:(CFArrayRef) addresses
{
	struct sockaddr  *addr;
	char             ipAddress[INET6_ADDRSTRLEN];
	CFIndex          index, count;
	int              err;
	
	assert(addresses != NULL);
	
	
	count = CFArrayGetCount(addresses);
	for (index = 0; index < count; index++) {
		addr = (struct sockaddr *)CFDataGetBytePtr(CFArrayGetValueAtIndex(addresses, index));
		assert(addr != NULL);
		
		/* getnameinfo coverts an IPv4 or IPv6 address into a text string. */
		err = getnameinfo(addr, addr->sa_len, ipAddress, INET6_ADDRSTRLEN, NULL, 0, NI_NUMERICHOST);
		if (err == 0) {
			NSLog(@"解析到ip地址：%s\n", ipAddress);
		} else {
			NSLog(@"地址格式转换错误：%d\n", err);
		}
	}
	return [NSString stringWithUTF8String:ipAddress];
	//return    [[[NSString alloc] initWithFormat:@"%s",ipAddress] autorelease];//这里只返回最后一个，一般认为只有一个地址
}

- (NSString *) getIPWithHostName:(const NSString *)hostName
{
	struct addrinfo * result;
	struct addrinfo * res;
	char ipv4[128];
	char ipv6[128];
	int error;
	BOOL IS_IPV6 = FALSE;
	bzero(&ipv4, sizeof(ipv4));
	bzero(&ipv4, sizeof(ipv6));
	
	error = getaddrinfo([hostName UTF8String], NULL, NULL, &result);
	if(error != 0) {
		NSLog(@"error in getaddrinfo:%d", error);
		return nil;
	}
	for(res = result; res!=NULL; res = res->ai_next) {
		char hostname[1025] = "";
		error = getnameinfo(res->ai_addr, res->ai_addrlen, hostname, 1025, NULL, 0, 0);
		if(error != 0) {
			NSLog(@"error in getnameifno: %s", gai_strerror(error));
			continue;
		}
		else {
			switch (res->ai_addr->sa_family) {
				case AF_INET:
					memcpy(ipv4, hostname, 128);
					NSLog(@"getIPWithHostName,ipv4: %s ", hostname);
					break;
				case AF_INET6:
					memcpy(ipv6, hostname, 128);
					NSLog(@"getIPWithHostName,ipv6: %s ", hostname);
					IS_IPV6 = TRUE;
				default:
					break;
			}
			
		}
	}
	freeaddrinfo(result);
	
	if(IS_IPV6 == TRUE) return [NSString stringWithUTF8String:ipv6];
	return [NSString stringWithUTF8String:ipv4];
}

-(NSArray *)outPutDNSServers{
	res_state res = malloc(sizeof(struct __res_state));
	int result = res_ninit(res);
	
	NSMutableArray *servers = [[NSMutableArray alloc] init];
	if (result == 0) {
		union res_9_sockaddr_union *addr_union = malloc(res->nscount * sizeof(union res_9_sockaddr_union));
		res_getservers(res, addr_union, res->nscount);
		
		for (int i = 0; i < res->nscount; i++) {
			if (addr_union[i].sin.sin_family == AF_INET) {
				char ip[INET_ADDRSTRLEN];
				inet_ntop(AF_INET, &(addr_union[i].sin.sin_addr), ip, INET_ADDRSTRLEN);
				NSString *dnsIP = [NSString stringWithUTF8String:ip];
				[servers addObject:dnsIP];
				NSLog(@"IPv4 DNS IP: %@", dnsIP);
			} else if (addr_union[i].sin6.sin6_family == AF_INET6) {
				char ip[INET6_ADDRSTRLEN];
				inet_ntop(AF_INET6, &(addr_union[i].sin6.sin6_addr), ip, INET6_ADDRSTRLEN);
				NSString *dnsIP = [NSString stringWithUTF8String:ip];
				[servers addObject:dnsIP];
				NSLog(@"IPv6 DNS IP: %@", dnsIP);
			} else {
				NSLog(@"Undefined family.");
			}
		}
	}
	res_nclose(res);
	free(res);
	
	return [NSArray arrayWithArray:servers];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
	
	NSString * str = [self getIPWithHostName:@"www.qq.com"];
	NSLog(@"getIPWithHostName,str=%@", str);
	
	
//	NSString *values[] = {@"www.qq.com", @"www.hb3344.com"};
//	CFArrayRef arrayRef = CFArrayCreate(kCFAllocatorDefault, (void *)values, (CFIndex)2, NULL);
//	NSString * str2 = [self getAddressFromArray:arrayRef];
//	NSLog(@"str2=%@", str2);
	
	
	[self outPutDNSServers];
	//方法 2
	
//	    struct hostent *host = gethostbyname2("www.weixin.qq.com",AF_INET6);
//	
//	    struct in_addr **list = (struct in_addr **)host->h_addr_list;
//	    NSString *ip= [NSString stringWithCString:inet_ntoa(*list[0]) encoding:NSUTF8StringEncoding];
//	    NSLog(@"ip address is : %@",ip);
	
    //方法 1
//    unsigned char auResult[512];
//    int nBytesRead = 0;
//    
//    nBytesRead = res_query("www.baidu.com", ns_c_in, ns_t_a, auResult, sizeof(auResult));
//    
//    ns_msg handle;
//    ns_initparse(auResult, nBytesRead, &handle);
//    
//    NSMutableArray *ipList = nil;
//    int msg_count = ns_msg_count(handle, ns_s_an);
//    if (msg_count > 0) {
//        ipList = [[NSMutableArray alloc] initWithCapacity:msg_count];
//        for(int rrnum = 0; rrnum < msg_count; rrnum++) {
//            ns_rr rr;
//            if(ns_parserr(&handle, ns_s_an, rrnum, &rr) == 0) {
//                char ip1[16];
//                strcpy(ip1, inet_ntoa(*(struct in_addr *)ns_rr_rdata(rr)));
//                NSString *ipString = [[NSString alloc] initWithCString:ip1 encoding:NSASCIIStringEncoding];
//                if (![ipString isEqualToString:@""]) {
//                    
//                    //将提取到的IP地址放到数组中
//                    [ipList addObject:ipString];
//					NSLog(@"ipString=%@",ipString);
//                }
//            }
//        }
//    }
//    
//
//	
//    //方法 3
//    Boolean result,bResolved;
//    CFHostRef hostRef;
//    CFArrayRef addresses = NULL;
//
//    CFStringRef hostNameRef = CFStringCreateWithCString(kCFAllocatorDefault, "www.hb3344.com", kCFStringEncodingASCII);
//    
//    hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostNameRef);
//    if (hostRef) {
//        result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL);
//        if (result == TRUE) {
//            addresses = CFHostGetAddressing(hostRef, &result);
//        }
//    }
//    bResolved = result == TRUE ? true : false;
//    
//    if(bResolved)
//    {
//        struct sockaddr_in* remoteAddr;
//        for(int i = 0; i < CFArrayGetCount(addresses); i++)
//        {
//            CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
//            remoteAddr = (struct sockaddr_in*)CFDataGetBytePtr(saData);
//            
//            if(remoteAddr != NULL)
//            {
//                //获取IP地址
//                char ip[16];
//                strcpy(ip, inet_ntoa(remoteAddr->sin_addr));
//				NSLog(@"ip=%s",ip);
//            }
//        }
//    }
//	
//    CFRelease(hostNameRef);
//    CFRelease(hostRef);
	
	

 
	
	
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
