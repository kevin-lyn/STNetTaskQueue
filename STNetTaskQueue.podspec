Pod::Spec.new do |s|
  s.name         = "STNetTaskQueue"
  s.version      = "0.0.2"
  s.summary      = "Queue for managing network requests"

  s.description  = <<-DESC
                   STNetTaskQueue may be your choice if you want to handle each network request stuff in separated STNetTask instead of having all the network requests logics in a "Manager" class
                   DESC

  s.homepage     = "https://github.com/kevin0571/STNetTaskQueue"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kevin Lin" => "kevin_lyn@outlook.com" }

  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/kevin0571/STNetTaskQueue.git", :tag => s.version }

  s.source_files = "STNetTaskQueue/*.{h,m}"
  s.public_header_files = "STNetTaskQueue/*.h"
end