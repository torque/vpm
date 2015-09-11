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
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
	DDLogVerbose( @"Application should open untitled file? No." );
	return NO;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
	DDLogVerbose( @"Application should handle reopen? No." );
	return NO;
}

- (void)createWindow {
	self.window = [[VpmWindow alloc] initWithController:self.controller];
	NSMenu *m = [[NSMenu alloc] initWithTitle:@"AMainMenu"];
	NSMenuItem *item = [m addItemWithTitle:@"Apple" action:nil keyEquivalent:@""];
	NSMenu *sm = [[NSMenu alloc] initWithTitle:@"Apple"];
	[m setSubmenu:sm forItem:item];
	NSMenuItem *fs = [sm addItemWithTitle: @"Toggle Full Screen" action:@selector(toggleFullScreen) keyEquivalent:@"f"];
	fs.target = self.controller;
	[sm addItemWithTitle: @"Quit vpm" action:@selector(terminate:) keyEquivalent:@"q"];
	[NSApp setMenu:m];
	[NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	DDLogVerbose( @"app finish lunch." );
	if (![NSBundle mainBundle].bundleIdentifier) {
		DDLogWarn( @"vpm will not run properly outside its bundle." );
		exit( 1 );
	}
	self.controller = [VpmMpvController new];
	self.server = [[VpmCLIServer alloc] initWithController:self.controller];

	[self createWindow];
}

// This is called before applicationDidFinishLaunching when opening a file
// launches the app, so we need to store an array of files to open to be used
// when the controller is initialized.
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
	DDLogVerbose( @"Application, open files." );
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
