#import <Cocoa/Cocoa.h>
#import "VpmCLI.h"

const static NSTimeInterval VpmLaunchTimeout = -2.0;
const static NSTimeInterval SleepLoopInterval = 0.1;

// Not currently using cocoalumberjack because I don't want to link a shared
// library.
int main( int argc, char **argv ) {
	NSDistantObject<VpmCLI> *remote = nil;
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
		@try {
			remote = (NSDistantObject<VpmCLI> *)[NSConnection rootProxyForConnectionWithRegisteredName:VpmServerID host:nil];
		} @catch ( NSException *exception ) {
			NSLog( @"NSConnection threw an exception. vpm crashed?" );
			return 1;
		}
		if ( !remote ) {
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

	[remote setProtocolForProxy:@protocol(VpmCLI)];

	NSLog( @"connected to vpm." );
	NSArray *args = [NSProcessInfo processInfo].arguments;
	NSString *pwd = [NSFileManager defaultManager].currentDirectoryPath;
	if ( !pwd ) {
		NSLog( @"Uhhhh, what?" );
		return 1;
	}

	NSString* (^CoercePath)( NSString *input ) = ^NSString* ( NSString *input ) {
		// Presumably if the input is an absolutePath, it can't be a url.
		if ( input.absolutePath )
			return input;

		for ( int i = 0; i < ([input length] - 3); i++ ) {
			if ( [input characterAtIndex:i] == ':' &&
				   [input characterAtIndex:i + 1] == '/' &&
				   [input characterAtIndex:i + 2] == '/' )
				return input;
		}

		return [pwd stringByAppendingPathComponent:input];
	};

	NSMutableArray *files = [NSMutableArray arrayWithCapacity:(args.count - 1)];
	for ( int i = 1; i < args.count; i++ ) {
		NSString *argument = CoercePath( args[i] );
		NSLog( @"File: %@", argument );
		[files addObject:argument];
	}

	// I think vpm crashing at any time after the connection is established will
	// cause an exception to be thrown, but I'm not sure. Either way, this is the
	// other likely place that an exception is liable to occur.
	@try {
		[remote loadFiles:files];
	} @catch ( NSException *exception ) {
		NSLog( @"An exception occurred. vpm crashed?" );
		return 1;
	}

	return 0;
}

