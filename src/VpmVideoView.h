#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

#import <mpv/opengl_cb.h>

#import "VpmJSBridge.h"

@interface VpmVideoView : NSOpenGLView

@property mpv_opengl_cb_context *mpv_gl;
@property(nonatomic, strong) WebView *webView;
@property(nonatomic, weak, readonly) JSContext *jsCtx;
@property(nonatomic, strong) VpmJSBridge *bridge;

- (void)drawRect;
- (void)attachJS;

@end
