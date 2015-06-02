#import "VpmWindow.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWindow

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (instancetype)initWithContentRect:(NSRect)contentRect
                          styleMask:(NSUInteger)windowStyle
                            backing:(NSBackingStoreType)bufferingType
                              defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect
	                        styleMask:windowStyle
	                          backing:bufferingType
	                            defer:deferCreation];
	if ( self ) {
		self.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
		self.minSize = NSMakeSize( 300, 300 );
		self.title = @"vpm";
		self.mainView = [[VpmVideoView alloc] initWithFrame:[self.contentView frame]];
		// bad.
		self.mainView.webView.bridge.window = self;
		[self.contentView addSubview:self.mainView];
		[self makeKeyAndOrderFront:nil];
		[self makeMainWindow];
	}

	return self;
}

// This is a huge trainwreck, but hopefully a working one.
- (void)constrainedCenteredResize:(NSSize)newContentSize {
	NSRect screenRect = self.screen.visibleFrame;
	NSRect windowRect = self.frame;
	NSRect contentRect = [self.contentView frame];
	NSSize newSize;
	CGFloat titlebarHeight = windowRect.size.height - contentRect.size.height;
	// if either of the differences are negative, the requested size is
	// larger than the screen size.
	if ( screenRect.size.width  - newContentSize.width  < 0 ||
	     screenRect.size.height - newContentSize.height - titlebarHeight < 0 )
	{
		CGFloat ar  = newContentSize.width/newContentSize.height;
		CGFloat sar = screenRect.size.width/screenRect.size.height;
		// requested size is wider than screen, so width is limiting factor.
		if ( ar > sar ) {
			newSize.width = screenRect.size.width;
			newSize.height = newSize.width/ar + titlebarHeight;
		} else {
			newSize.height = screenRect.size.height - titlebarHeight;
			newSize.width = newSize.height*ar;
			newSize.height += titlebarHeight;
		}
	} else {
		newSize.width = newContentSize.width;
		newSize.height = newContentSize.height + titlebarHeight;
	}

	CGFloat dx = newSize.width - windowRect.size.width;
	CGFloat dy = newSize.height - windowRect.size.height;
	NSPoint newOrigin = NSMakePoint(windowRect.origin.x - dx/2.0, windowRect.origin.y - dy/2.0);
	if ( newOrigin.x < screenRect.origin.x ) {
		newOrigin.x = screenRect.origin.x;
	} else if ( newOrigin.x + newSize.width > screenRect.origin.x + screenRect.size.width ) {
		newOrigin.x = screenRect.origin.x + screenRect.size.width - newSize.width;
	}

	if ( newOrigin.y < screenRect.origin.y ) {
		newOrigin.y = screenRect.origin.y;
	} else if ( newOrigin.y + newSize.height > screenRect.origin.y + screenRect.size.height ) {
		newOrigin.y = screenRect.origin.y + screenRect.size.height - newSize.height;
	}

	NSRect newFrame = NSMakeRect( newOrigin.x,   newOrigin.y,
		                            newSize.width, newSize.height);
	[self setFrame:newFrame
	       display:YES
	       animate:YES];
}

- (void)destroy {
	[self.mainView destroy];
}

@end
