#import "VpmWindow.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmWindow

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL)isMovableByWindowBackground { return YES; }

- (void)mouseDown:(NSEvent *)theEvent {
	self.startPoint = theEvent.locationInWindow;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSRect screenRect = self.screen.visibleFrame;
	NSRect windowRect = self.frame;
	NSPoint newOrigin = windowRect.origin;

	NSPoint currentLocation = theEvent.locationInWindow;
	newOrigin.x += currentLocation.x - self.startPoint.x;
	newOrigin.y += currentLocation.y - self.startPoint.y;

	if (newOrigin.y + windowRect.size.height > screenRect.origin.y + screenRect.size.height) {
		newOrigin.y = screenRect.origin.y + screenRect.size.height - windowRect.size.height;
	}

	self.frameOrigin = newOrigin;
}

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

// it appears the more standard key handling chain is swallowing certain
// keys such as tab and space for reasons that are profoundly unclear to
// me. Is it WebView's fault? Need there be a witch hunt?
- (void)sendEvent:(NSEvent *)theEvent {
	switch ( theEvent.type ) {
		case NSKeyDown: {
			[self.mainView.webView.bridge handleKeyEvent:theEvent];
			// don't fall through to default, because it causes error bells.
			return;
		}
		case NSLeftMouseDown: {
			[self mouseDown:theEvent];
			break;
		}
		case NSLeftMouseDragged: {
			[self mouseDragged:theEvent];
			break;
		}
		default: {}
	}
	[super sendEvent:theEvent];
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
	newSize.width  = MAX( self.minSize.width,  newSize.width );
	newSize.height = MAX( self.minSize.height, newSize.height );

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
