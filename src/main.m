#import <Cocoa/Cocoa.h>
#import "CommonLog.h"
#import "VpmDelegate.h"

int main(int argc, const char * argv[]) {
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	[DDLog addLogger:[DDTTYLogger sharedInstance]];

	NSApplication *app = [NSApplication sharedApplication];
	VpmDelegate *delegate = [VpmDelegate new];
	app.delegate = delegate;
	[app run];
	return 0;
}
