#import <Cocoa/Cocoa.h>

@class VpmVideoView;
@class VpmWindowDelegate;

@interface VpmWindow : NSWindow

@property NSPoint startPoint;
@property (nonatomic, strong) VpmVideoView *mainView;
@property (nonatomic, readonly, strong) VpmWindowDelegate *delegateHolder;

- (void)constrainedCenteredResize:(NSSize)newContentSize;
- (void)updateMainViewBounds;
- (void)destroy;

@end
