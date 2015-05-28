#import <OpenGL/gl.h>

#import "VpmVideoView.h"

static void glUpdate( void *ctx );
static void *glProbe( void *ctx, const char *name) {
	NSString *sym = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
	return CFBundleGetFunctionPointerForName(
	         CFBundleGetBundleWithIdentifier(
	           CFSTR( "com.apple.opengl" )
	         ), (__bridge CFStringRef)sym
	       );
}


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
		// Have to explicitly initialize this to nil.
		self.mpv_gl = nil;

		GLint swapInt = 1;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
		self.webView = [[VpmWebView alloc] initWithFrame:self.bounds];
		[self addSubview:self.webView];
		// init mpv_gl stuff
		[self initMpvGL];
		[[self openGLContext] makeCurrentContext];
	}

	return self;
}

- (void)initMpvGL {
	mpv_handle *mpv = self.webView.bridge.mpv;
	// re-add error checking at some point.
	mpv_set_option_string( mpv, "vo", "opengl-cb" );
	self.mpv_gl = mpv_get_sub_api( mpv, MPV_SUB_API_OPENGL_CB );
	if ( !self.mpv_gl ) {
		puts( "libmpv does not have the opengl-cb sub-API." );
		// handle error.
	}

	int r = mpv_opengl_cb_init_gl( self.mpv_gl, NULL, glProbe, NULL );
	if ( r < 0 ) {
		puts( "gl init has failed." );
		// handle error.
	}

	mpv_opengl_cb_set_update_callback( self.mpv_gl, glUpdate, (__bridge void *)self );
}

static void glUpdate( void *ctx ) {
	VpmVideoView *view = (__bridge VpmVideoView *)ctx;
	dispatch_async( dispatch_get_main_queue( ), ^{
		[view drawRect];
	} );
}

- (void)drawRect {
	if ( self.mpv_gl ) {
		mpv_opengl_cb_draw(self.mpv_gl, 0, self.bounds.size.width, -self.bounds.size.height);
	} else {
		glClearColor(0, 0, 0, 0);
		glClear(GL_COLOR_BUFFER_BIT);
	}
	[[self openGLContext] flushBuffer];
}

- (void)drawRect:(NSRect)dirtyRect {
	[self drawRect];
}

- (void)destroy {
	mpv_opengl_cb_uninit_gl( self.mpv_gl );
	[self.webView destroy];
}

@end
