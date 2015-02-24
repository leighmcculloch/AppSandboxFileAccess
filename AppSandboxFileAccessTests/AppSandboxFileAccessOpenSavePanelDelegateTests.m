//
//  AppSandboxFileAccessOpenSavePanelDelegateTests.m
//  AppSandboxFileAccessTests
//
//  Created by Vincent Esche on 01/02/15.
//  Copyright (c) 2015 Vincent Esche. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "AppSandboxFileAccessOpenSavePanelDelegate.h"

@interface AppSandboxFileAccessOpenSavePanelDelegateTests : XCTestCase

@property (readwrite, strong, nonatomic) AppSandboxFileAccessOpenSavePanelDelegate *delegate;

@end

@implementation AppSandboxFileAccessOpenSavePanelDelegateTests

- (void)setUp {
	[super setUp];
	
	NSURL *fileURL = [NSURL fileURLWithPath:@"/a/b/c"];
	self.delegate = [[AppSandboxFileAccessOpenSavePanelDelegate alloc] initWithFileURL:fileURL];
}

- (void)test__panel_shouldEnableURL__withSameURLs {
	NSURL *fileURL = [NSURL fileURLWithPath:@"/a/b/c"];
	BOOL enabled = [self.delegate panel:nil shouldEnableURL:fileURL];
	XCTAssertTrue(enabled, @"Should enable URL if same.");
}

- (void)test__panel_shouldEnableURL__withLongerURL {
	NSURL *fileURL = [NSURL fileURLWithPath:@"/a/b/c/d"];
	BOOL enabled = [self.delegate panel:nil shouldEnableURL:fileURL];
	XCTAssertFalse(enabled, @"Should not enable URL if longer.");
}

- (void)test__panel_shouldEnableURL__withShorterURL {
	NSURL *fileURL = [NSURL fileURLWithPath:@"/a/b/"];
	BOOL enabled = [self.delegate panel:nil shouldEnableURL:fileURL];
	XCTAssertTrue(enabled, @"Should enable URL if shorter.");
}

@end
