#import "VpmStandardWindowButtonView.h"
#import "CommonLog.h"

@interface VpmStandardWindowButtonView()

@property BOOL mouseOver;
@property(strong) NSButton *closeButton;
@property(strong) NSButton *minButton;
@property(strong) NSButton *maxButton;
@property(strong) NSTrackingArea *trackingArea;

@end

@implementation VpmStandardWindowButtonView

- (instancetype)init {
	DDLogInfo( @"init" );
	if ( self = [super initWithFrame:NSMakeRect(0, 0, 58, 14)] ) {
		self.translatesAutoresizingMaskIntoConstraints = NO;
		self.wantsLayer = YES;

		self.mouseOver = NO;
		self.trackingArea = nil;

		NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask| NSResizableWindowMask;
		self.closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:windowStyle];
		self.minButton = [NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:windowStyle];
		self.maxButton = [NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:windowStyle];
		self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
		self.minButton.translatesAutoresizingMaskIntoConstraints = NO;
		self.maxButton.translatesAutoresizingMaskIntoConstraints = NO;

		[self addSubview:self.closeButton];
		[self addSubview:self.minButton];
		[self addSubview:self.maxButton];

		NSDictionary *constraintViews = @{
			@"closeButton": self.closeButton,
			@"minButton":   self.minButton,
			@"maxButton":   self.maxButton
		};
		NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[closeButton]-spacing-[minButton]-spacing-[maxButton]"
		                                           options:0
		                                           metrics:@{@"spacing": @6}
		                                           views:constraintViews];
		[self addConstraints:constraints];
		DDLogInfo( @"%g, %g", self.frame.origin.x, self.frame.origin.y );
	}
	return self;
}

- (void)updateTrackingAreas {
	// This doesn't appear to choke on nil.
	[self removeTrackingArea:self.trackingArea];

	self.mouseOver = NO;
	self.trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
	                                                 options:NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited
	                                                   owner:self
	                                                userInfo:nil];
	[self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	self.mouseOver = YES;
	[self setNeedsDisplay];
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	self.mouseOver = NO;
	[self setNeedsDisplay];
}

// Magic method called by the standard window buttons to determine if they
// should draw their hover decorations. See: http://stackoverflow.com/a/30417372
- (BOOL)_mouseInGroup:(NSButton *)button {
	return self.mouseOver;
}

// maybe shouldn't be overriding setNeedsDisplay for this purpose, but it hasn't
// seemed to cause any problems.
- (void)setNeedsDisplay {
	[self.closeButton setNeedsDisplay];
	[self.minButton setNeedsDisplay];
	[self.maxButton setNeedsDisplay];
}

@end
