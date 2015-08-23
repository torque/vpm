#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWebView

- (BOOL)mouseDownCanMoveWindow { return YES; }

- (instancetype)initWithFrame:(NSRect)frame {
- (instancetype)initWithFrame:(NSRect)frame controller:(VpmMpvController *)controller{
	self = [super initWithFrame:frame
	                  frameName:@"vpmWekitFrame"
	                  groupName:@"vpmWebkitGroup"];

	if ( self ) {
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.drawsBackground = NO;
		self.ctx = [JSContext contextWithJSGlobalContextRef:self.mainFrame.globalContext];
		[controller attachJSContext:self.ctx];
		self.controller = controller;
		self.frameLoadDelegate = controller;
		[self.mainFrame loadRequest:
			[NSURLRequest requestWithURL:
				[[NSBundle mainBundle] URLForResource:@"video" withExtension:@"html"]
			]
		];
	}

	return self;
}

- (void)destroy {
	[self.controller destroy];
}

@end
