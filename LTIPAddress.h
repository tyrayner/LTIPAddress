/*

 LTIPAddress
 Created by Tyler Rayner on 2/23/16.
 raynersw.com
 
 An Objective-C class for wrapping IPv4 or IPv6 addresses
 
 */

#import <Foundation/Foundation.h>
#import <arpa/inet.h>

#define LTIPAddressType4 AF_INET
#define LTIPAddressType6 AF_INET6

typedef enum LTIPAddressFamily {
	LTIPAddressFamilyIPv4 = AF_INET,
	LTIPAddressFamilyIPv6 = AF_INET6,
} LTIPAddressFamily;

typedef enum LTIPAddressPresentationOptions {
	
// Default behavior is to print the netmask only if the address has one, and use compressed format for IPv6 addresses.
	LTIPAddressStandard = 0,
	
// Always print the netmask. If the address lacks a netmask, it will be /32 for IPv4 or /128 for IPv6.
	LTIPAddressForceNetmask = 1<<0,
	
// Never print the netmask.
	LTIPAddressSuppressNetmask = 1<<1,
	
// For IPv6 addresses, print the full-length address (39 character + netmask). Has no effect for IPv4 addresses.
	LTIPAddressExpanded = 1<<2,
	
} LTIPAddressPresentationOptions;



@interface LTIPAddress : NSObject <NSCopying, NSCoding> // Abstract superclass for LTIPAddressIPv4 and LTIPAddressIPv6

@property (readonly) LTIPAddressFamily family;
@property (readonly) BOOL hasNetmask;
@property (readonly) uint8_t netmask; // 0-32 for IPv4, 0-128 for IPv6

/*
 addressWithString:
 
 The designated initializer for LTIPAddress objects.
 
 Returns an LTIPAddressIPv6 or LTIPAddressIPv4 address depending upon the string passed in.
 
 ADDRSTR: The IP address in string format, optionally with netmask in CIDR format (i.e. /29). If the string is not a valid IPv4 or IPv6 address, will return nil.
 */
+ (id)addressWithString:(NSString *)ADDRSTR;


/*
 containsAddress:
 
 Determine if an addresses falls within a subnet.
 
 When calling this method, self should have a netmask.
 
 Returns YES if ADDR is contained within the subnet specified by self, NO if not.
 
 ADDR: The address to compare with self. If ADDR contains a netmask, the netmask is ignored.
 */
- (BOOL)containsAddress:(LTIPAddress *)ADDR; // If ADDR has a netmask, it is ignored.


/*
 stringValueWithOptions:
 
 Returns an NSString representation of the IP address.
 
 OPTIONS: A bitmask of LTIPAddressPresentationOptions
 */
- (NSString *)stringValueWithOptions:(LTIPAddressPresentationOptions)OPTIONS;


/*
 stringValue
 
 Returns an NSString representation of the IP address.
 
 Convenience method. Calls stringValueWithOptions:LTIPAddressStandard
 */
- (NSString *)stringValue;

@end


@interface LTIPAddressIPv4 : LTIPAddress <NSCopying, NSCoding>

@property(readonly)			struct in_addr nativeAddress; // The native address, as defined in in.h
							 
@end


@interface LTIPAddressIPv6 : LTIPAddress <NSCopying, NSCoding>

@property(readonly)			struct in6_addr nativeAddress; // The native address, as defined in in6.h

@end

