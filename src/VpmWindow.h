#import <Cocoa/Cocoa.h>

@class VpmVideoView;

@interface VpmWindow : NSWindow

@property (nonatomic, strong) VpmVideoView *mainView;

- (void)constrainedCenteredResize:(NSSize)newContentSize;
-(void)destroy;

@end
