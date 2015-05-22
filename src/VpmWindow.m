#import "VpmWindow.h"

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
		[self.contentView addSubview:self.mainView];
	}

	return self;
}

@end
