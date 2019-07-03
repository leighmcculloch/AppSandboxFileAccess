public typealias AppSandboxFileAccessBlock = () -> Void
public typealias AppSandboxFileSecurityScopeBlock = (URL?, Data?) -> Void

protocol AppSandboxFileAccessProtocol: class {
    func bookmarkData(for url: URL) -> Data?
    func setBookmarkData(_ data: Data?, for url: URL?)
    func clearBookmarkData(for url: URL)
}

let CFBundleDisplayName = "CFBundleDisplayName"
let CFBundleName = "CFBundleName"

open class AppSandboxFileAccess {
    /*! @brief The title of the NSOpenPanel displayed when asking permission to access a file.
     Default: "Allow Access"
     */
    open var title = ""
    /*! @brief The message contained on the the NSOpenPanel displayed when asking permission to access a file.
     Default: "[Application Name] needs to access this path to continue. Click Allow to continue."
     */
    open var message = ""
    /*! @brief The prompt button on the the NSOpenPanel displayed when asking permission to access a file.
     Default: "Allow"
     */
    open var prompt = ""
    /*! @brief This is an optional delegate object that can be provided to customize the persistance of bookmark data (e.g. in a Core Data database).
     Default: nil (Default uses the AppSandboxFileAccessPersist class.)
     */
    
    private var defaultDelegate: AppSandboxFileAccessPersist = AppSandboxFileAccessPersist()
    
    private weak var _bookmarkPersistanceDelegate: AppSandboxFileAccessProtocol?
    weak var bookmarkPersistanceDelegate: AppSandboxFileAccessProtocol? {
        get {
            return _bookmarkPersistanceDelegate ?? defaultDelegate
        }
        set(bookmarkPersistanceDelegate) {
            _bookmarkPersistanceDelegate = bookmarkPersistanceDelegate
        }
    }
    

    
    //! @brief Initialise the object with the default values.
    public init() {

        var applicationName = Bundle.main.object(forInfoDictionaryKey: CFBundleDisplayName) as? String
        if applicationName == nil {
            applicationName = Bundle.main.object(forInfoDictionaryKey: CFBundleName) as? String
        }
        
        title = NSLocalizedString("Allow Access", comment: "Sandbox Access panel title.")
        let formatString = NSLocalizedString("%@ needs to access this path to continue. Click Allow to continue.", comment: "Sandbox Access panel message.")
        message = String(format: formatString, applicationName ?? "")
        prompt = NSLocalizedString("Allow", comment: "Sandbox Access panel prompt.")
        
    }
    
    /*! @brief Access a file path to read or write, automatically gaining permission from the user with NSOpenPanel if required
     and using persisted permissions if possible.
     
     @see accessFile:persistPermission:withBlock:
     @see securityScopedURLForFilePath:persistPermission:bookmark:
     
     @param path A file path, either a file or folder, that the caller needs access to.
     @param persist If YES will save the permission for future calls.
     @param block The block that will be given access to the file or folder.
     @return YES if permission was granted or already available, NO otherwise.
     */
    public func accessFilePath(_ path: String?, persistPermission persist: Bool, with block: AppSandboxFileAccessBlock) -> Bool {
        return accessFileURL(URL(fileURLWithPath: path ?? ""), persistPermission: persist, with: block)
    }
    

    
    /*! @brief Access a file URL to read or write, automatically gaining permission from the user with NSOpenPanel if required
     and using persisted permissions if possible.
     
     @see requestAccessPermissionsForFileURL:persistPermission:withBlock:
     
     @discussion Internally calls `requestAccessPermissionsForFileURL:persistPermission:withBlock:` and accesses the returned scoped URL if successful.
     
     @discussion See `requestAccessPermissionsForFileURL:persistPermission:withBlock:` for detailed behaviour.
     
     @param fileURL A file URL, either a file or folder, that the caller needs access to.
     @param persist If YES will save the permission for future calls.
     @param block The block that will be given access to the file or folder.
     @return YES if permission was granted or already available, NO otherwise.
     */
    public func accessFileURL(_ fileURL: URL, persistPermission persist: Bool, with block:AppSandboxFileAccessBlock) -> Bool {


        let success = requestPermissions(forFileURL: fileURL, persistPermission: persist, with: { securityScopedFileURL, bookmarkData in
            // execute the block with the file access permissions

            if (securityScopedFileURL?.startAccessingSecurityScopedResource() == true) {
                block()
                securityScopedFileURL?.stopAccessingSecurityScopedResource()
            }
            

        })
        
        return success
    }
    

    
    /*! @brief Request access permission for a file path to read or write, automatically with NSOpenPanel if required
     and using persisted permissions if possible.
     
     @see securityScopedURLForFilePath:persistPermission:bookmark:
     
     @param path A file path, either a file or folder, that the caller needs access to.
     @param persist If YES will save the permission for future calls.
     @return YES if permission was granted or already available, NO otherwise.
     */
    func requestPermissions(forFilePath filePath: String?, persistPermission persist: Bool, with block: AppSandboxFileSecurityScopeBlock) -> Bool {
        assert(filePath != nil, "Invalid parameter not satisfying: filePath != nil")
        
        let fileURL = URL(fileURLWithPath: filePath ?? "")
        return requestPermissions(forFileURL: fileURL, persistPermission: persist, with: block)
    }
    
    /*! @brief Request access permission for a file path to read or write, automatically with NSOpenPanel if required
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
     
     @param fileURL A file URL, either a file or folder, that the caller needs access to.
     @param persist If YES will save the permission for future calls.
     @param block The block that will be given access to the file or folder.
     @return YES if permission was granted or already available, NO otherwise.
     */
    func requestPermissions(forFileURL fileURL: URL?, persistPermission persist: Bool, with block: AppSandboxFileSecurityScopeBlock) -> Bool {
        assert(fileURL != nil, "Invalid parameter not satisfying: fileURL != nil")
        
        guard let fileURL = fileURL else {
            return false
        }
        
        var allowedURL: URL? = nil
        
        // standardize the file url and remove any symlinks so that the url we lookup in bookmark data would match a url given by the askPermissionForURL method
        let standardisedFileURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
        
        // lookup bookmark data for this url, this will automatically load bookmark data for a parent path if we have it
        var bookmarkData:Data? = bookmarkPersistanceDelegate?.bookmarkData(for: standardisedFileURL)
        if let concreteData = bookmarkData {
            // resolve the bookmark data into an NSURL object that will allow us to use the file
            var bookmarkDataIsStale: Bool = false
            do {
                allowedURL = try URL.init(resolvingBookmarkData:concreteData, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale)
            } catch {
            }
            // if the bookmark data is stale we'll attempt to recreate it with the existing url object if possible (not guaranteed)
            if bookmarkDataIsStale {
                bookmarkData = nil
                bookmarkPersistanceDelegate?.clearBookmarkData(for: standardisedFileURL)
                if allowedURL != nil {
                    bookmarkData = persistPermissionURL(allowedURL)
                    if bookmarkData == nil {
                        allowedURL = nil
                    }
                }
            }
        }
        
        // if allowed url is nil, we need to ask the user for permission
        if allowedURL == nil {
            allowedURL = askPermission(for: standardisedFileURL)
            if allowedURL == nil {
                // if the user did not give permission, exit out here
                return false
            }
        }
        
        // if we have no bookmark data and we want to persist, we need to create it
        if persist && bookmarkData == nil {
            bookmarkData = persistPermissionURL(allowedURL)
        }
        
        //if block
        block(allowedURL, bookmarkData)
        
        return true
    }
    
    /*! @brief Persist a security bookmark for the given path. The calling application must already have permission.
     
     @see persistPermissionURL:
     
     @param path The path with permission that will be persisted.
     @return Bookmark data if permission was granted or already available, nil otherwise.
     */
    func persistPermissionPath(_ path: String?) -> Data? {
        assert(path != nil, "Invalid parameter not satisfying: path != nil")
        
        return persistPermissionURL(URL(fileURLWithPath: path ?? ""))
    }
    
    /*! @brief Persist a security bookmark for the given URL. The calling application must already have permission.
     
     @discussion Use this function to persist permission of a URL that has already been granted when a user introduced
     a file to the calling application. E.g. by dropping the file onto the application window, or dock icon,
     or when using an NSOpenPanel.
     
     Note: If the calling application does not have access to this file, this call will do nothing.
     
     @param url The URL with permission that will be persisted.
     @return Bookmark data if permission was granted or already available, nil otherwise.
     */
    func persistPermissionURL(_ url: URL?) -> Data? {
        assert(url != nil, "Invalid parameter not satisfying: url != nil")
        
        // store the sandbox permissions
        var bookmarkData: Data? = nil
        do {
            bookmarkData = try url?.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
        }
        if bookmarkData != nil {
            bookmarkPersistanceDelegate?.setBookmarkData(bookmarkData, for: url)
        }
        return bookmarkData
    }
    
    
    
    func askPermission(for url: URL?) -> URL? {
        var url = url
        assert(url != nil, "Invalid parameter not satisfying: url != nil")
        
        // this url will be the url allowed, it might be a parent url of the url passed in
        var allowedURL: URL? = nil
        
        // create delegate that will limit which files in the open panel can be selected, to ensure only a folder
        // or file giving permission to the file requested can be selected
        var openPanelDelegate: AppSandboxFileAccessOpenSavePanelDelegate? = nil
        if let url = url {
            openPanelDelegate = AppSandboxFileAccessOpenSavePanelDelegate(fileURL: url)
        }
        
        // check that the url exists, if it doesn't, find the parent path of the url that does exist and ask permission for that
        let fileManager = FileManager.default
        var path = url?.path
        while (path?.count ?? 0) > 1 {
            // give up when only '/' is left in the path or if we get to a path that exists
            if fileManager.fileExists(atPath: path ?? "", isDirectory: nil) {
                break
            }
            path = URL(fileURLWithPath: path ?? "").deletingLastPathComponent().absoluteString
        }
        url = URL(fileURLWithPath: path ?? "")
        
        // display the open panel
        let displayOpenPanelBlock = {
            let openPanel = NSOpenPanel()
            openPanel.message = self.message
            openPanel.canCreateDirectories = false
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.prompt = self.prompt
            openPanel.title = self.title
            openPanel.showsHiddenFiles = false
            openPanel.isExtensionHidden = false
            openPanel.directoryURL = url
            openPanel.delegate = openPanelDelegate
            NSApplication.shared.activate(ignoringOtherApps: true)
            let openPanelButtonPressed = openPanel.runModal().rawValue
            if openPanelButtonPressed == NSFileHandlingPanelOKButton {
                allowedURL = openPanel.url
            }
        }
        if Thread.isMainThread {
            displayOpenPanelBlock()
        } else {
            DispatchQueue.main.sync(execute: displayOpenPanelBlock)
        }
        
        return allowedURL
    }
}


