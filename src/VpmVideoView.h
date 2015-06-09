#import <Cocoa/Cocoa.h>

#import <mpv/opengl_cb.h>

@class VpmWebView;

@interface VpmVideoView : NSOpenGLView

@property mpv_opengl_cb_context *mpv_gl;
@property(nonatomic, strong) VpmWebView *webView;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)draw;
- (void)unintMpvGl;
- (void)destroy;

@end
