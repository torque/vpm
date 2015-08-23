#import <Cocoa/Cocoa.h>

@class VpmVideoView;
@class VpmWindowDelegate;
@class VpmMpvController;

@interface VpmWindow : NSWindow

@property NSPoint startPoint;
@property (nonatomic, strong) VpmVideoView *mainView;
@property (nonatomic, readonly, strong) VpmWindowDelegate *delegateHolder;

- (instancetype)initWithController:(VpmMpvController *)controller;
- (void)constrainedCenteredResize:(NSSize)newContentSize;
- (void)updateMainViewBounds;
- (void)destroy;

@end
