#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWebView

- (BOOL)mouseDownCanMoveWindow { return YES; }

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
		[self registerForDraggedTypes:@[NSFilenamesPboardType, NSURLPboardType]];
	}

	return self;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	NSPasteboard *pboard = [sender draggingPasteboard];
	if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		[self.controller loadFiles:files];
	}
	if ( [[pboard types] containsObject:NSURLPboardType] ) {
		NSURL *url = [NSURL URLFromPasteboard:pboard];
		if ( url.fileURL )
			[self.controller loadFiles:@[url.path]];
		else {
			NSString *urlStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
			if ( urlStr )
				[self.controller loadFiles:@[urlStr]];
		}
	}
	return YES;
}

- (void)destroy {
	[self.controller destroy];
}

@end
