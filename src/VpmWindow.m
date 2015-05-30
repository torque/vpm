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
		self.title = @"vpm";
		self.mainView = [[VpmVideoView alloc] initWithFrame:[self.contentView frame]];
		[self.contentView addSubview:self.mainView];
		[self makeKeyAndOrderFront:nil];
		[self makeMainWindow];
	}

	return self;
}

- (void)destroy {
	[self.mainView destroy];
}

@end
