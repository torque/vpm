#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

#import "VpmMpvController.h"

@interface VpmWebView : WebView

@property(weak) JSContext *ctx;
@property(strong) VpmMpvController *bridge;

- (instancetype)initWithFrame:(NSRect)frame;
- (void)destroy;

@end
