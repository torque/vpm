#import <Cocoa/Cocoa.h>
#import "VpmCLI.h"

const static NSTimeInterval VpmLaunchTimeout = -2.0;
const static NSTimeInterval SleepLoopInterval = 0.1;

int main( int argc, char **argv ) {
	NSDistantObject<VpmCLI> *server = nil;
	BOOL running = [NSRunningApplication runningApplicationsWithBundleIdentifier:VPM_BUNDLE_ID].count > 0;
	if ( running )
		NSLog( @"vpm is already running." );
	else {
		// may want to check launchservices for a list of all matching bundles
		// NSArray *urls = (__bridge NSArray*)LSCopyApplicationURLsForBundleIdentifier( (__bridge CFStringRef)VPM_BUNDLE_ID, NULL );
		NSString *vpm = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:VPM_BUNDLE_ID];
		NSLog( @"vpm: %@", vpm );
		[[NSWorkspace sharedWorkspace] launchApplication:vpm];
	}

	NSDate *start = [NSDate date];
	while ( YES ) {
		// For some reason, using ARC makes clang be a lot more strict about unknown
		// messages. This causes NSDistantObject to act like a piece of shit unless
		// it's explicitly declared with the protocol, and then it still needs to be
		// cast on assignment to avoid a stupid "incompatible pointer" warning.
		server = (NSDistantObject<VpmCLI> *)[NSConnection rootProxyForConnectionWithRegisteredName:VpmServerID host:nil];
		if ( !server ) {
			// check timeout and loop again
			NSTimeInterval waitLength = [start timeIntervalSinceNow];
			NSLog( @"Waitlength: %g", waitLength );
			if ( waitLength < VpmLaunchTimeout ) {
				NSLog( @"Couldn't connect to vpm app. Maybe vpm hasn't launched yet?");
				return 1;
			}
			[NSThread sleepForTimeInterval:SleepLoopInterval];
		} else
			break;
	}

	[server setProtocolForProxy:@protocol(VpmCLI)];

	NSLog( @"connected to vpm." );
	// this is synchronous.
	[server sayHello:@"client"];

	return 0;
}

