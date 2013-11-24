//
//  AppSandboxFileAccess.h
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

#import <Foundation/Foundation.h>

typedef void (^AppSandboxFileAccessBlock)();

@interface AppSandboxFileAccess : NSObject

/*! @brief The title of the NSOpenPanel displayed when asking permission to access a file.
 Default: "Allow Access"
 */
@property (retain) NSString *title;
/*! @brief The message contained on the the NSOpenPanel displayed when asking permission to access a file.
 Default: "[Application Name] needs to access this path to continue. Click Allow to continue."
 */
@property (retain) NSString *message;
/*! @brief The prompt button on the the NSOpenPanel displayed when asking permission to access a file. 
 Default: "Allow"
 */
@property (retain) NSString *prompt;

/*! @brief Create the object with the default values. */
+ (AppSandboxFileAccess *)fileAccess;

/*! @brief Initialise the object with the default values. */
- (id)init;

/*! @brief Access a file path to read or write, automatically gaining permission from the user with NSOpenPanel if required
 and using persisted permissions if possible.
 
 @see accessFile:withBlock:persistPermission:
 
 @param path A file path, either a file or folder, that the caller needs access to.
 @param block The block that will be given access to the file or folder.
 @param persist If YES will save the permission for future calls.
 @return YES if permission was granted or already available, NO otherwise.
 */
- (BOOL)accessFilePath:(NSString *)path withBlock:(AppSandboxFileAccessBlock)block persistPermission:(BOOL)persist;

/*! @brief Access a file URL to read or write, automatically gaining permission from the user with NSOpenPanel if required
 and using persisted permissions if possible.
 
 @discussion Use this function to access a file URL to either read or write in an application restricted by the App Sandbox.
 This function will ask the user for permission if necessary using a well formed NSOpenPanel. The user will
 have the option of approving access to the URL you specify, or a parent path for that URL. If persist is YES
 the permission will be stored as a bookmark in NSUserDefaults and further calls to this function will
 load the saved permission and not ask for permission again.
 
 @discussion If the file URL does not exist, it's parent directory will be asked for permission instead, since permission
 to the directory will be required to write the file. If the parent directory doesn't exist, it will ask for 
 permission of whatever part of the parent path exists.
 
 @discussion Note: If the caller has permission to access a file because it was dropped onto the application or introduced
 to the application in some other way, this function will not be aware of that permission and still prompt
 the user. To prevent this, use the persistPermission function to persist a permission you've been given
 whenever a user introduces a file to the application. E.g. when dropping a file onto the application window
 or dock or when using an NSOpenPanel.
 
 @param fileUrl A file URL, either a file or folder, that the caller needs access to.
 @param block The block that will be given access to the file or folder.
 @param persist If YES will save the permission for future calls.
 @return YES if permission was granted or already available, NO otherwise.
 */
- (BOOL)accessFileURL:(NSURL *)fileUrl withBlock:(AppSandboxFileAccessBlock)block persistPermission:(BOOL)persist;

/*! @brief Persist a security bookmark for the given path. The calling application must already have permission.
 
 @see persistPermissionURL:
 
 @param path The path with permission that will be persisted.
 */
- (void)persistPermissionPath:(NSString *)path;

/*! @brief Persist a security bookmark for the given URL. The calling application must already have permission.
 
 @discussion Use this function to persist permission of a URL that has already been granted when a user introduced
 a file to the calling application. E.g. by dropping the file onto the application window, or dock icon, 
 or when using an NSOpenPanel.
 
 Note: If the calling application does not have access to this file, this call will do nothing.
 
 @param url The URL with permission that will be persisted.
 */
- (void)persistPermissionURL:(NSURL *)url;

@end
