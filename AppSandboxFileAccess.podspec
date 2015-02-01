Pod::Spec.new do |s|

  s.name         = "AppSandboxFileAccess"
  s.version      = "1.0.14"
  s.summary      = "A class that wraps up writing and accessing files outside a Mac apps App Sandbox files into a simple interface."

  s.description  = <<-DESC
                   A class that wraps up writing and accessing files outside a Mac apps App Sandbox files into a simple interface.
                   The class will request permission from the user with a simple to understand dialog consistent
                   with Apple's documentation and persist permissions across application runs.
                   DESC

  s.homepage     = "https://github.com/leighmcculloch/AppSandboxFileAccess"
  s.license      = { :type => "BSD-2", :file => "LICENSE" }
  s.author       = { "Leigh McCulloch" => "leigh@mcchouse.com" }
  s.platform     = :osx, "10.7.3"
  s.source       = { :git => "https://github.com/leighmcculloch/AppSandboxFileAccess.git", :tag => "1.0.14" }
  s.source_files = "AppSandboxFileAccess/Classes/*.{h,m}"
  s.requires_arc = true

end
