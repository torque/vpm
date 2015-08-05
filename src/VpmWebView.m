#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWebView

- (BOOL)mouseDownCanMoveWindow { return YES; }

- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame
	                  frameName:@"vpmWekitFrame"
	                  groupName:@"vpmWebkitGroup"];

	if ( self ) {
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.drawsBackground = NO;
		self.ctx = [JSContext contextWithJSGlobalContextRef:self.mainFrame.globalContext];
		self.bridge = [[VpmMpvController alloc] initWithJSContext:self.ctx];
		self.frameLoadDelegate = self.bridge;
	}

	return self;
}

- (void)destroy {
	[self.bridge destroy];
}

@end
