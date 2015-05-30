#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

@class VpmMpvController;

@interface VpmWebView : WebView

@property(weak) JSContext *ctx;
@property(strong) VpmMpvController *bridge;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)destroy;

@end
