//
//  AppSandboxFileAccess.m
//  AppSandboxFileAccess
//
//  Created by Leigh McCulloch on 23/11/2013.
//
//  Copyright (c) 2013, Leigh McCulloch
//  All rights reserved.
//
//  BSD-2-Clause License: http://opensource.org/licenses/BSD-2-Clause
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
//  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
//  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
//  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "AppSandboxFileAccess.h"
#import "AppSandboxFileAccessPersist.h"
#import "AppSandboxFileAccessOpenSavePanelDelegate.h"

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

#define CFBundleDisplayName @"CFBundleDisplayName"
#define CFBundleName        @"CFBundleName"

@implementation AppSandboxFileAccess

+ (AppSandboxFileAccess *)fileAccess {
	return [[AppSandboxFileAccess alloc] init];
}

- (id)init {
	self = [super init];
	if (self) {
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:CFBundleDisplayName];
		if (!applicationName) {
			applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:CFBundleName];
		}
		
		self.title = @"Allow Access";
		self.message = [NSString stringWithFormat:@"%@ needs to access this path to continue. Click Allow to continue.", applicationName];
		self.prompt = @"Allow";
		
	}
	return self;
}

- (NSURL *)askPermissionForUrl:(NSURL *)url {
	// this url will be the url allowed, it might be a parent url of the url passed in
	__block NSURL *allowedUrl = nil;
	
	// create delegate that will limit which files in the open panel can be selected, to ensure only a folder
	// or file giving permission to the file requested can be selected
	AppSandboxFileAccessOpenSavePanelDelegate *openPanelDelegate = [[AppSandboxFileAccessOpenSavePanelDelegate alloc] initWithFileURL:url];
	
	// check that the url exists, if it doesn't, find the parent path of the url that does exist and ask permission for that
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *path = [url path];
	while (path.length > 1) { // give up when only '/' is left in the path or if we get to a path that exists
		if ([fileManager fileExistsAtPath:path isDirectory:NULL]) {
			break;
		}
		path = [path stringByDeletingLastPathComponent];
	}
	url = [NSURL fileURLWithPath:path];
	
	// display the open panel
	dispatch_block_t displayOpenPanelBlock = ^{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setMessage:self.message];
		[openPanel setCanCreateDirectories:NO];
		[openPanel setCanChooseFiles:YES];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setPrompt:self.prompt];
		[openPanel setTitle:self.title];
		[openPanel setShowsHiddenFiles:NO];
		[openPanel setExtensionHidden:NO];
		[openPanel setDirectoryURL:url];
		[openPanel setDelegate:openPanelDelegate];
		[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
		NSInteger openPanelButtonPressed = [openPanel runModal];
		if (openPanelButtonPressed == NSFileHandlingPanelOKButton) {
			allowedUrl = [openPanel URL];
		}
	};
	if ([NSThread isMainThread]) {
		displayOpenPanelBlock();
	} else {
		dispatch_sync(dispatch_get_main_queue(), displayOpenPanelBlock);
	}

	return allowedUrl;
}

- (void)persistPermissionPath:(NSString *)path {
	[self persistPermissionURL:[NSURL fileURLWithPath:path]];
}

- (void)persistPermissionURL:(NSURL *)url {
	// store the sandbox permissions
	NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
	if (bookmarkData) {
		[AppSandboxFileAccessPersist setBookmarkData:bookmarkData forURL:url];
	}
}

- (BOOL)accessFilePath:(NSString *)path withBlock:(AppSandboxFileAccessBlock)block persistPermission:(BOOL)persist {
	return [self accessFileURL:[NSURL fileURLWithPath:path] withBlock:block persistPermission:persist];
}

- (BOOL)accessFileURL:(NSURL *)fileUrl withBlock:(AppSandboxFileAccessBlock)block persistPermission:(BOOL)persist {

	NSURL *allowedUrl = nil;
	
	// standardize the file url and remove any symlinks so that the url we lookup in bookmark data would match a url given by the askPermissionForUrl method
	fileUrl = [[fileUrl URLByStandardizingPath] URLByResolvingSymlinksInPath];
	
	// lookup bookmark data for this url, this will automatically load bookmark data for a parent path if we have it
	NSData *bookmarkData = [AppSandboxFileAccessPersist bookmarkDataForURL:fileUrl];
	if (bookmarkData) {
		// resolve the bookmark data into an NSURL object that will allow us to use the file
		BOOL bookmarkDataIsStale;
		allowedUrl = [NSURL URLByResolvingBookmarkData:bookmarkData options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:NULL];
		// if the bookmark data is stale, we'll create new bookmark data further down
		if (bookmarkDataIsStale) {
			bookmarkData = nil;
		}
	}
	
	// if allowed url is nil, we need to ask the user for permission
	if (!allowedUrl) {
		allowedUrl = [self askPermissionForUrl:fileUrl];
		if (!allowedUrl) {
			// if the user did not give permission, exit out here
			return NO;
		}
	}
	
	// if we have no bookmark data, we need to create it, this may be because our bookmark data was stale, or this is the first time being given permission
	if (persist && !bookmarkData) {
		[self persistPermissionURL:allowedUrl];
	}
	
	// execute the block with the file access permissions
	@try {
		[allowedUrl startAccessingSecurityScopedResource];
		block();
	} @finally {
		[allowedUrl stopAccessingSecurityScopedResource];
	}
	
	return YES;
}

@end
