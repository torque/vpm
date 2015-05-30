#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWebView

- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame
	                  frameName:@"vpmWekitFrame"
	                  groupName:@"vpmWebkitGroup"];

	if ( self ) {
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.drawsBackground = NO;
		self.ctx = [JSContext contextWithJSGlobalContextRef:self.mainFrame.globalContext];
		self.bridge = [[VpmMpvController alloc] initWithJSContext:self.ctx];
	}

	return self;
}

- (void)destroy {
	[self.bridge destroy];
}

@end
