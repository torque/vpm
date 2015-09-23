#import "CommonLog.h"
#import "VpmWindow.h"
#import "VpmWindowDelegate.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

@interface VpmWindow()

@property (nonatomic, strong) VpmMpvController *controller;
@property (nonatomic, strong) VpmWindowDelegate *delegateHolder;

@end

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

- (instancetype)initWithController:(VpmMpvController *)controller {
	const int height = 396, width = 704;
	NSRect screenFrame = [NSScreen mainScreen].visibleFrame;
	NSRect contentRect = NSMakeRect( (screenFrame.size.width - width)/2 + screenFrame.origin.x,
	                                (screenFrame.size.height - height)/2 + screenFrame.origin.y,
	                                width, height );
	int styleMask = NSBorderlessWindowMask | NSResizableWindowMask;
	NSBackingStoreType backing = NSBackingStoreBuffered;
	BOOL defer = NO;

	self = [super initWithContentRect:contentRect
	                        styleMask:styleMask
	                          backing:backing
	                            defer:defer];
	if ( self ) {
		self.delegateHolder = [VpmWindowDelegate new];
		self.delegate = self.delegateHolder;
		self.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
		self.backgroundColor = [NSColor clearColor];
		self.opaque = NO;
		self.minSize = NSMakeSize( 150, 150 );
		self.targetSize = NSMakeSize( self.frame.size.width, self.frame.size.height );
		self.title = @"vpm";
		self.controller = controller;
		// Kind of bad? less bad than before.
		controller.window = self;
		self.mainView = [[VpmVideoView alloc] initWithFrame:[self.contentView frame] controller:controller];
		[self.contentView addSubview:self.mainView];
		[self makeKeyAndOrderFront:nil];
		[self makeMainWindow];
		[self updateMainViewBounds];
	}

	return self;
}

// it appears the more standard key handling chain is swallowing certain
// keys such as tab and space for reasons that are profoundly unclear to
// me. Is it WebView's fault? Need there be a witch hunt?
- (void)sendEvent:(NSEvent *)theEvent {
	switch ( theEvent.type ) {
		case NSKeyDown: {
			DDLogVerbose( @"Keydown: %@, U+%04X", theEvent.characters, [theEvent.characters characterAtIndex:0] );
			[self.controller handleKeyEvent:theEvent];
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

// This is a huge trainwreck, but a working one.
- (void)constrainedCenteredResize:(NSSize)newContentSize {
	newContentSize = [self.mainView convertSizeFromBacking:newContentSize];
	NSRect screenRect = self.screen.visibleFrame;
	NSRect windowRect = self.frame;
	NSRect contentRect = [self.contentView frame];
	// not really necessary since we no longer have a titlebar, but probably
	// should be kept regardless.
	CGFloat titlebarHeight = windowRect.size.height - contentRect.size.height;
	NSSize newSize;
	DDLogVerbose( @"Titlebar height: %g", titlebarHeight );
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

	NSSize minSize = [self.mainView convertSizeFromBacking:self.minSize];
	newSize.width  = MAX( minSize.width,  newSize.width );
	newSize.height = MAX( minSize.height, newSize.height );

	DDLogVerbose( @"s: (%g, %g) -> (%g, %g)", windowRect.size.width, windowRect.size.height, newSize.width, newSize.height);

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

	DDLogVerbose( @"o: (%g, %g) -> (%g, %g)", windowRect.origin.x, windowRect.origin.y, newOrigin.x, newOrigin.y);
	NSRect newFrame = NSMakeRect( floor( newOrigin.x ),   floor( newOrigin.y ),
		                            floor( newSize.width ), floor( newSize.height ) );
	[self setFrame:newFrame
	       display:YES
	       animate:YES];
}

- (void)updateMainViewBounds {
	self.mainView.backingSize = [self.mainView convertSizeToBacking:[self.contentView frame].size];
}

- (void)destroy {
	[self.mainView destroy];
}

@end
