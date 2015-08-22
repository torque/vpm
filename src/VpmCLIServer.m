#import "CommonLog.h"
#import "VpmCLIServer.h"

@implementation VpmCLIServer

- (instancetype)init {
	if ( self = [super init] ) {
		self.server = [NSConnection serviceConnectionWithName:VpmServerID rootObject:self];
		if ( !self.server ) return nil;
		DDLogInfo( @"Server is listening" );
	}

	return self;
}

- (BOOL)sayHello:(NSString *)message {
	DDLogWarn( @"CLI says: %@", message );
	return YES;
}

@end
