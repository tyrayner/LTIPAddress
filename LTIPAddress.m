/*
 
 LTIPAddress
 Created by Tyler Rayner on 2/23/16.
 raynersw.com
 
 An Objective-C class for wrapping IPv4 or IPv6 addresses
 
 */

#import "LTIPAddress.h"

@interface LTIPAddress (LTIPAddress_internal)
- (void *)_nativeAddressPtr;
@end

@interface LTIPAddressIPv4 (LTIPAddressIPv4_internal)
- (id)_initWithNativeAddress:(struct in_addr)ADDR;
@end

@interface LTIPAddressIPv6 (LTIPAddressIPv6_internal)
- (id)_initWithNativeAddress:(struct in6_addr)ADDR;
- (NSString *)_addressStringExpanded;
@end

@implementation LTIPAddress

+ (id)addressWithString:(NSString *)ADDRSTR
{
	BOOL		success = NO;
	struct		in_addr addr4;
	struct		in6_addr addr6;
	int			ptonRet = 0;
	const char	*cStr = NULL;
	LTIPAddress	*ret = nil;
	NSString	*str_addr = nil;
	NSString	*str_mask = nil;
	NSArray		*components = nil;
	
	components = [ADDRSTR componentsSeparatedByString:@"/"];
	if ([components count] == 2) {
		str_addr = components[0];
		str_mask = components[1];
	} else {
		str_addr = ADDRSTR;
	}
	
	cStr = [str_addr cStringUsingEncoding:NSASCIIStringEncoding];
	if (!cStr) goto bail;
	ptonRet = inet_pton(AF_INET6, cStr, &addr6);
	if (1 == ptonRet) {
		ret = [[LTIPAddressIPv6 alloc] _initWithNativeAddress:addr6];
	} else {
		ptonRet = inet_pton(AF_INET, cStr, &addr4);
		if (1 == ptonRet) {
			ret = [[LTIPAddressIPv4 alloc] _initWithNativeAddress:addr4];
		} else {
			goto bail;
		}
	}
	
	NSInteger iv = [str_mask integerValue];
	if ( ((iv == 0) && (![str_mask isEqualToString:@"0"])) || (iv > 128) ) {
		ret->_hasNetmask = NO;
	} else {
		ret->_hasNetmask = YES;
		ret->_netmask = (uint8_t)iv;
	}
	
	success = YES;
bail:
	return ret;
}

- (id)initWithCoder:(NSCoder *)CODER
{
	return [LTIPAddress addressWithString:[CODER decodeObjectForKey:@"stringValue"]];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.stringValue forKey:@"stringValue"];
}

- (id)copyWithZone:(NSZone *)zone
{
	return [LTIPAddress addressWithString:self.stringValue];
}

- (BOOL)isEqual:(id)object
{
	if (self == object) return YES;
	if (![object isKindOfClass:[LTIPAddress class]]) return NO;
	
	LTIPAddress *o = (LTIPAddress *)object;
	
	if (
		(self.family != o.family) ||
		(self.hasNetmask != o.hasNetmask) ||
		(
			(self.hasNetmask) &&
			(self.netmask != o.netmask)
		 )
		) {
		return NO;
	}
	
	void *na0 = NULL;
	void *na1 = NULL;
	socklen_t na_len = 0;
	
	if (self.family == LTIPAddressFamilyIPv4) {
		struct in_addr _na0 = ((LTIPAddressIPv4 *)self).nativeAddress;
		struct in_addr _na1 = ((LTIPAddressIPv4 *)object).nativeAddress;
		return (0 == memcmp(&_na0, &_na1, 4));
	} else if (self.family == LTIPAddressFamilyIPv6) {
		struct in6_addr _na0 = ((LTIPAddressIPv6 *)self).nativeAddress;
		struct in6_addr _na1 = ((LTIPAddressIPv6 *)object).nativeAddress;
		return (0 == memcmp(&_na0, &_na1, 16));
	} else {
		return NO;
	}
	
	return (0 == memcmp(na0, na1, na_len));
}

- (void *)_nativeAddressPtr
{
	NSException *e = [NSException exceptionWithName:@"Invalid invocation" reason:@"LTIPAddress superclass invocation of - (void *)_nativeAddressPtr is not allowed." userInfo:nil];
	
	@throw e;
	
	return NULL;
}

- (LTIPAddressFamily)family
{
	NSException *e = [NSException exceptionWithName:@"Invalid invocation" reason:@"LTIPAddress superclass invocation of - (LTIPAddressFamily)family is not allowed." userInfo:nil];
	
	@throw e;
}

- (BOOL)containsAddress:(LTIPAddress *)ADDR
{
	NSException *e = [NSException exceptionWithName:@"Invalid invocation" reason:@"LTIPAddress superclass invocation of - (LTIPAddressFamily)containsAddress: is not allowed." userInfo:nil];
	
	@throw e;
}

- (NSString *)stringValueWithOptions:(LTIPAddressPresentationOptions)OPTIONS
{
	BOOL showMask;
	NSString *addr = nil;
	
	if ((OPTIONS & LTIPAddressForceNetmask) && (OPTIONS & LTIPAddressSuppressNetmask)) {
		NSException *e = [NSException exceptionWithName:@"Invalid options" reason:@"[LTIPAddress stringValueWithOptions:] contained flags for both LTIPAddressForceNetmask and LTIPAddressSuppressNetmask" userInfo:nil];
		@throw e;
	}
	
	if (OPTIONS & LTIPAddressSuppressNetmask) {
		showMask = NO;
	} else {
		if (OPTIONS & LTIPAddressForceNetmask) {
			showMask = YES;
		} else {
			showMask = self.hasNetmask;
		}
	}
	
	if ((self.family == LTIPAddressFamilyIPv6) && (OPTIONS & LTIPAddressExpanded)) {
		addr = [((LTIPAddressIPv6 *)self) _addressStringExpanded];
	} else {
		char str[INET6_ADDRSTRLEN];
		if (0 == inet_ntop(self.family, [self _nativeAddressPtr], str, INET6_ADDRSTRLEN)) {
			return nil;
		}
		addr = [[NSString alloc] initWithCString:str encoding:NSASCIIStringEncoding];
	}
	
	if (showMask) {
		int nm = 0;
		if (self.hasNetmask) {
			nm = self.netmask;
		} else {
			if (self.family == LTIPAddressFamilyIPv4) nm = 32;
			else if (self.family == LTIPAddressFamilyIPv6) nm = 128;
		}
		return [NSString stringWithFormat:@"%@/%i", addr, nm];
	} else {
		return addr;
	}
}


- (NSString *)stringValue
{
	return [self stringValueWithOptions:0];
}

- (NSString *)description
{
	return self.stringValue;
}

@end



@implementation LTIPAddressIPv4 : LTIPAddress

- (id)_initWithNativeAddress:(struct in_addr)ADDR
{
	if (self = [super init])
	{
		_nativeAddress = ADDR;
	} return self;
}

- (void *)_nativeAddressPtr
{
	return &_nativeAddress;
}

- (LTIPAddressFamily)family
{
	return LTIPAddressFamilyIPv4;
}

- (BOOL)containsAddress:(LTIPAddress *)ADDR
{
	if (ADDR.family != LTIPAddressFamilyIPv4) {
		return NO;
	}
	
	uint32_t a0n = 0; // addresses network
	uint32_t a1n = 0;
	uint32_t a0 = 0; // addresses host
	uint32_t a1 = 0;
	uint8_t cidr = 0; // cidr i.e. /32 /29
	uint32_t m = 0; // bitmask
	uint32_t a0m = 0; // addresses masked
	uint32_t a1m = 0;
	
	a0n = (self.nativeAddress.s_addr);
	a1n = (((LTIPAddressIPv4 *)ADDR).nativeAddress.s_addr);
	
	a0 = NTOHL(a0n);
	a1 = NTOHL(a1n);
	
	cidr = (self.hasNetmask) ? self.netmask : 32;
	
	m = (cidr == 0) ? 0 : (0xffffffff << (32 - cidr));
	
	a0m = a0 & m;
	a1m = a1 & m;
	
	return (a0m == a1m);
}


@end



@implementation LTIPAddressIPv6 : LTIPAddress

- (id)_initWithNativeAddress:(struct in6_addr)ADDR
{
	if (self = [super init])
	{
		_nativeAddress = ADDR;
	} return self;
}

- (void *)_nativeAddressPtr
{
	return &_nativeAddress;
}

- (NSString *)_addressStringExpanded
{
	struct in6_addr a = self.nativeAddress;
	return [NSString stringWithFormat:
			@"%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x:%02x%02x",
			a.__u6_addr.__u6_addr8[0], a.__u6_addr.__u6_addr8[1],
			a.__u6_addr.__u6_addr8[2], a.__u6_addr.__u6_addr8[3],
			a.__u6_addr.__u6_addr8[4], a.__u6_addr.__u6_addr8[5],
			a.__u6_addr.__u6_addr8[6], a.__u6_addr.__u6_addr8[7],
			a.__u6_addr.__u6_addr8[8], a.__u6_addr.__u6_addr8[9],
			a.__u6_addr.__u6_addr8[10], a.__u6_addr.__u6_addr8[11],
			a.__u6_addr.__u6_addr8[12], a.__u6_addr.__u6_addr8[13],
			a.__u6_addr.__u6_addr8[14], a.__u6_addr.__u6_addr8[15]
			];
}

- (LTIPAddressFamily)family
{
	return LTIPAddressFamilyIPv6;
}

- (BOOL)containsAddress:(LTIPAddress *)ADDR
{
	if (ADDR.family != LTIPAddressFamilyIPv6) {
		return NO;
	}
	
	uint32_t *a0n = NULL; // addresses network
	uint32_t *a1n = NULL;
	uint32_t a0[4] = {0,0,0,0}; // addresses host
	uint32_t a1[4] = {0,0,0,0};
	uint8_t cidr = 0; // cidr i.e. /48 /64
	uint32_t m[4] = {0,0,0,0}; // bitmask
	uint32_t a0m[4] = {0,0,0,0}; // addresses masked
	uint32_t a1m[4] = {0,0,0,0};
	
	a0n = (self.nativeAddress.__u6_addr.__u6_addr32);
	a1n = (((LTIPAddressIPv6 *)ADDR).nativeAddress.__u6_addr.__u6_addr32);
	
	a0[0] = NTOHL(a0n[0]);
	a0[1] = NTOHL(a0n[1]);
	a0[2] = NTOHL(a0n[2]);
	a0[3] = NTOHL(a0n[3]);
	
	a1[0] = NTOHL(a1n[0]);
	a1[1] = NTOHL(a1n[1]);
	a1[2] = NTOHL(a1n[2]);
	a1[3] = NTOHL(a1n[3]);
	
	cidr = (self.hasNetmask) ? self.netmask : 128;
	
	for (int i = 0; i < 4; i++)
	{
		int offset = i * 32;
		int shift = (cidr >= (32 + offset)) ? 32 : (((cidr - offset) < 0) ? 0 : (cidr - offset));
		
		m[i] = (shift == 0) ? 0 : (0xffffffff << (32 - shift));
		
		a0m[i] = a0[i] & m[i];
		a1m[i] = a1[i] & m[i];
	}
	
	return ((a0m[0]==a1m[0])&&(a0m[1]==a1m[1])&&(a0m[2]==a1m[2])&&(a0m[3]==a1m[3]));
}


@end

