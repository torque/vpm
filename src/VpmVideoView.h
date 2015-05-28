#import <Cocoa/Cocoa.h>

#import <mpv/client.h>
#import <mpv/opengl_cb.h>

#import "VpmWebView.h"

@interface VpmVideoView : NSOpenGLView

@property mpv_opengl_cb_context *mpv_gl;
@property(nonatomic, strong) VpmWebView *webView;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)drawRect;
- (void)destroy;

@end
