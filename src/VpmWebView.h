#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>

@class VpmMpvController;

@interface VpmWebView : WebView <NSDraggingDestination>

@property(weak) JSContext *ctx;
@property(strong) VpmMpvController *controller;

- (instancetype)initWithFrame:(NSRect)frame controller:(VpmMpvController *)controller;
- (void)destroy;

@end
