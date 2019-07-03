
//  AppSandboxFileAccessOpenSavePanelDelegate.m
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

class AppSandboxFileAccessOpenSavePanelDelegate: NSObject, NSOpenSavePanelDelegate {
    private var pathComponents: [Any] = []
    
    init(fileURL: URL) {
        super.init()

        pathComponents = fileURL.pathComponents
    }
    
    
    
    // MARK: -- NSOpenSavePanelDelegate
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {

        let pathComponents = self.pathComponents
        let otherPathComponents = url.pathComponents
        
        // if the url passed in has more components, it could not be a parent path or a exact same path
        if (otherPathComponents.count) > pathComponents.count {
            return false
        }
        
        // check that each path component in url, is the same as each corresponding component in self.url
        for i in 0..<(otherPathComponents.count) {
            let comp1 = otherPathComponents[i]
            let comp2 = pathComponents[i] as? String
            // not the same, therefore url is not a parent or exact match to self.url
            if !(comp1 == comp2) {
                return false
            }
        }
        
        // there were no mismatches (or no components meaning url is root)
        return true
    }
}
