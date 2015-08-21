#import <Cocoa/Cocoa.h>
#import "VpmDelegate.h"

int main(int argc, const char * argv[]) {
	NSApplication *app = [NSApplication sharedApplication];

	VpmDelegate *delegate = [VpmDelegate new];
	app.delegate = delegate;
	[app run];
	return 0;
}
