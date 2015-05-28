#import <Cocoa/Cocoa.h>
#import "VpmDelegate.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		NSApplication *app = [NSApplication sharedApplication];
		[app setActivationPolicy:NSApplicationActivationPolicyRegular];

		VpmDelegate *delegate = [VpmDelegate new];
		app.delegate = delegate;
		[app run];
	}
	return EXIT_SUCCESS;
}
