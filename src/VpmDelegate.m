#import <mpv/opengl_cb.h>

#import <stdio.h>
#import <stdlib.h>

#import "CommonLog.h"
#import "VpmDelegate.h"
#import "VpmCLIServer.h"
#import "VpmWindow.h"
#import "VpmVideoView.h"
#import "VpmWebView.h"
#import "VpmMpvController.h"

@implementation VpmDelegate


- (void)createWindow {
	self.window = [[VpmWindow alloc] initWithController:self.controller];
	NSMenu *m = [[NSMenu alloc] initWithTitle:@"AMainMenu"];
	NSMenuItem *item = [m addItemWithTitle:@"Apple" action:nil keyEquivalent:@""];
	NSMenu *sm = [[NSMenu alloc] initWithTitle:@"Apple"];
	[m setSubmenu:sm forItem:item];
	NSMenuItem *fs = [sm addItemWithTitle: @"Toggle Full Screen" action:@selector(toggleFullScreen) keyEquivalent:@"f"];
	fs.target = self.window.mainView.webView.bridge;
	[sm addItemWithTitle: @"Quit vpm" action:@selector(terminate:) keyEquivalent:@"q"];
	[NSApp setMenu:m];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	if (![NSBundle mainBundle].bundleIdentifier) {
		puts( "vpm is not meant to be run from outside its bundle." );
		exit( 1 );
	}
	// set up logging
	// apple system log (console)
	[DDLog addLogger:[DDASLLogger sharedInstance]];
	// terminal log
	[DDLog addLogger:[DDTTYLogger sharedInstance]];

	self.server = [VpmCLIServer new];

	[self createWindow];

	[[self.window.mainView.webView mainFrame] loadRequest:
		[NSURLRequest requestWithURL:
			[[NSBundle mainBundle] URLForResource:@"video" withExtension:@"html"]
		]
	];
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	NSLog( @"Application, open files." );
	for ( NSString *file in filenames )
		NSLog( @"open: %@", file );
}

// quit when the window is closed.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	DDLogVerbose( @"Shutting down." );
	[self.window destroy];
	return NSTerminateNow;
}

@end
