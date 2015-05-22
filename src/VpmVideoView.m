#import <OpenGL/gl.h>

#import "VpmVideoView.h"

@implementation VpmVideoView
- (instancetype)initWithFrame:(NSRect)frame {
	NSOpenGLPixelFormatAttribute attributes[] = {
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAAccelerated,
		0
	};
	self = [super initWithFrame:frame
	                pixelFormat:[[NSOpenGLPixelFormat alloc]
	                              initWithAttributes:attributes]];

	if ( self ) {
		self.wantsBestResolutionOpenGLSurface = YES;
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.wantsLayer = YES;
		_webView = [[WebView alloc] initWithFrame:[self bounds]
		                                frameName:@"vpmWekitFrame"
		                                groupName:@"vpmWebkitGroup"];

		if (_webView) {
			_webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
			_webView.drawsBackground = NO;
			[self addSubview:_webView];
		} else {
			// probably crash or something
		}
		// implicitly runs prepareOpenGL
		[[self openGLContext] makeCurrentContext];
	}

	return self;
}

- (void)prepareOpenGL
{
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
	// flush view with black. Looks better on startup.
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	// still not sure why flushing twice is necessary to blank the view.
	[[self openGLContext] flushBuffer];
	[[self openGLContext] flushBuffer];
	self.mpv_gl = NULL;
}

- (void)drawRect {
	if (self.mpv_gl)
		mpv_opengl_cb_draw(self.mpv_gl, 0, self.bounds.size.width, -self.bounds.size.height);
	[[self openGLContext] flushBuffer];
}

- (void)drawRect:(NSRect)dirtyRect {
	[self drawRect];
}

- (void)attachJS {
	_jsCtx = [JSContext contextWithJSGlobalContextRef:self.webView.mainFrame.globalContext];

	[self.jsCtx setExceptionHandler:^(JSContext *context, JSValue *value) {
		NSLog( @"%@", value );
	}];

	self.jsCtx[@"console"][@"log"] = ^(JSValue *msg) {
		NSLog( @"JavaScript: %@", msg );
	};

	NSLog(@"bridgeset %p", self.bridge);
	if (self.bridge) {
		self.jsCtx[@"vpm"] = self.bridge;
	}
}

@end
