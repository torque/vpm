#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

#import <mpv/opengl_cb.h>

@interface VpmVideoView : NSOpenGLView

@property mpv_opengl_cb_context *mpv_gl;
@property(nonatomic, strong) WebView *webView;
@property(nonatomic, weak, readonly) JSContext *jsCtx;

- (void)drawRect;
- (void)attachJSContext;

@end
