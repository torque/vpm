#import <mpv/client.h>
#import <OpenGL/gl.h>

#import "CommonLog.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

static void glUpdate( void *ctx );
static void *glProbe( void *ctx, const char *name) {
	NSString *sym = [NSString stringWithCString:name encoding:NSASCIIStringEncoding];
	return CFBundleGetFunctionPointerForName(
	         CFBundleGetBundleWithIdentifier(
	           CFSTR( "com.apple.opengl" )
	         ), (__bridge CFStringRef)sym
	       );
}

@interface VpmVideoView()

@property(strong) NSLock *drawLock;
@property mpv_opengl_cb_context *mpv_gl;
@property(nonatomic, strong) dispatch_queue_t glQueue;
@property(nonatomic, strong) VpmMpvController *controller;

- (void)initMpvGL;
- (void)draw;
- (void)unintMpvGl;

@end

@implementation VpmVideoView

- (BOOL)mouseDownCanMoveWindow { return YES; }

- (instancetype)initWithFrame:(NSRect)frame controller:(VpmMpvController *)controller {
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
		self.controller = controller;
		self.wantsBestResolutionOpenGLSurface = YES;
		self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
		self.wantsLayer = YES;
		self.layer.cornerRadius = 5;
		self.layer.masksToBounds = YES;
		// Have to explicitly initialize this to nil.
		self.mpv_gl = nil;

		self.glQueue = dispatch_queue_create( "org.unorg.vpm.gl", DISPATCH_QUEUE_SERIAL );
		self.drawLock = [NSLock new];
		self.webView = [[VpmWebView alloc] initWithFrame:self.bounds controller:controller];
		[self addSubview:self.webView];
		// init mpv_gl stuff
		[[self openGLContext] makeCurrentContext];
		[self initMpvGL];
	}

	return self;
}

- (void)prepareOpenGL {
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
}

- (void)initMpvGL {
	mpv_handle *mpv = self.controller.mpv;
	// re-add error checking at some point.
	mpv_set_option_string( mpv, "vo", "opengl-cb" );
	self.mpv_gl = mpv_get_sub_api( mpv, MPV_SUB_API_OPENGL_CB );
	if ( !self.mpv_gl ) {
		DDLogError( @"libmpv does not have the opengl-cb sub-API." );
		exit( 0 );
	}

	int r = mpv_opengl_cb_init_gl( self.mpv_gl, NULL, glProbe, NULL );
	if ( r < 0 ) {
		DDLogError( @"gl init has failed." );
		exit( 0 );
	}

	mpv_opengl_cb_set_update_callback( self.mpv_gl, glUpdate, (__bridge void *)self );
}

static void glUpdate( void *ctx ) {
	VpmVideoView *view = (__bridge VpmVideoView *)ctx;
	dispatch_async( view.glQueue, ^{
		[view draw];
	} );
}

- (void)draw {
	[self.drawLock lock];
	[[self openGLContext] makeCurrentContext];
	if ( self.mpv_gl ) {
		mpv_opengl_cb_draw( self.mpv_gl, 0, self.backingSize.width, -self.backingSize.height );
	} else {
		glClearColor( 0, 0, 0, 0 );
		glClear( GL_COLOR_BUFFER_BIT );
	}
	[[self openGLContext] flushBuffer];
	if (self.mpv_gl)
		mpv_opengl_cb_report_flip( self.mpv_gl, 0 );
	[self.drawLock unlock];
}

- (void)drawRect:(NSRect)dirtyRect {
	[self draw];
}

- (void)unintMpvGl {
	[self.drawLock lock];
	[[self openGLContext] makeCurrentContext];
	mpv_opengl_cb_uninit_gl( self.mpv_gl );
	self.mpv_gl = nil;
	[self.drawLock unlock];
}

- (void)destroy {
	[self unintMpvGl];
	[self.webView destroy];
}

@end
