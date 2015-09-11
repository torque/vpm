#import "CommonLog.h"
#import "VpmCLIServer.h"

@implementation VpmCLIServer

- (instancetype)initWithController:(VpmMpvController *)controller {
	if ( self = [super init] ) {
		self.server = [NSConnection serviceConnectionWithName:VpmServerID rootObject:self];
		if ( !self.server ) return nil;

		self.controller = controller;
		DDLogInfo( @"Server is listening" );
	}

	return self;
}

- (void)loadFiles:(NSArray *)files {
	for ( NSString* file in files )
		DDLogInfo( @"file: %@", file );
}

@end
