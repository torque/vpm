#import <Cocoa/Cocoa.h>

@class VpmVideoView;

@interface VpmWindow : NSWindow

@property (nonatomic, strong) VpmVideoView *mainView;

-(void)destroy;

@end
