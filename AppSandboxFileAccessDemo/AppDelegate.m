//
//  AppDelegate.m
//  AppSandboxFileAccessDemo
//
//  Created by Definite Loop on 01/02/15.
//  Copyright (c) 2015 Leigh McCulloch. All rights reserved.
//

#import "AppDelegate.h"

#import <AppSandboxFileAccess/AppSandboxFileAccess.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	// initialise the file access class
	AppSandboxFileAccess *fileAccess = [AppSandboxFileAccess fileAccess];
	
	// the application was provided this file when the user dragged this file on to the app
	NSString *file = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) firstObject];
	
	BOOL isDirectory = NO;
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:file isDirectory:&isDirectory];
	NSAssert(fileExists, @"File not found!");
	
	// persist permission to access the file the user introduced to the app, so we can always
	// access it and then the AppSandboxFileAccess class won't prompt for it if you wrap access to it
	[fileAccess persistPermissionPath:file];
	
	// get the parent directory for the file
	NSString *directory = (isDirectory) ? file : [file stringByDeletingLastPathComponent];
	
	// get access to the parent directory
	BOOL accessAllowed = [fileAccess accessFilePath:directory persistPermission:YES withBlock:^{
		NSAlert *alert = [[NSAlert alloc] init];
		alert.informativeText = @"Touching file now.";
		alert.messageText = @"Access Granted";
		[alert addButtonWithTitle:@"OK"];
		[alert runModal];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSError *error = nil;
		if (![fileManager setAttributes:@{NSFileModificationDate: [NSDate date]} ofItemAtPath:file error:&error]) {
			NSLog(@"Error: %@", error);
		}
	}];
	
	if (!accessAllowed) {
		NSLog(@"Sad Wookie");
	}
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
