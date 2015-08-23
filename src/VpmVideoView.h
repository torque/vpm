#import <Cocoa/Cocoa.h>

#import <mpv/opengl_cb.h>

@class VpmWebView;
@class VpmMpvController;

@interface VpmVideoView : NSOpenGLView

@property NSSize backingSize;
@property(nonatomic, strong) VpmWebView *webView;

- (instancetype)initWithFrame:(NSRect)frame controller:(VpmMpvController *)controller;
- (void)destroy;

@end
