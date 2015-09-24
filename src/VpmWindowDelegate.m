#import "VpmWindowDelegate.h"
#import "VpmWindow.h"

@implementation VpmWindowDelegate

- (void)windowDidResize:(NSNotification *)notification {
	[[notification object] updateViewBounds];
}

@end
