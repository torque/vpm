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
		self.mainView = [[VpmVideoView alloc] initWithFrame:[[self contentView] bounds]];
		self.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
		[self.contentView addSubview:self.mainView];
	}

	return self;
}

- (void)destroy {
	[self.mainView destroy];
}

@end
