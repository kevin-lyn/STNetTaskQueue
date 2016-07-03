Pod::Spec.new do |s|
  s.name         = "STNetTaskQueue"
  s.version      = "0.0.21"
  s.summary      = "STNetTaskQueue is a networking queue library for iOS and OS X. It's abstract and can be implemented in different protocols."

  s.description  = <<-DESC
                   STNetTaskQueue avoid you from directly dealing with "url", "request packing" and "response parsing". All networking tasks are described and processed by subclassing STNetTask, which provides you a clean code style in UI layer when handling networking.
                   DESC

  s.homepage     = "https://github.com/kevin0571/STNetTaskQueue"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Kevin Lin" => "kevin_lyn@outlook.com" }

  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/osorochich/STNetTaskQueue.git", :branch => "common_changes" }

  s.resources = "STNetTaskQueue/*.xcdatamodeld"
  s.frameworks = "CoreData"

  s.source_files = "STNetTaskQueue/*.{h,m}"
  s.public_header_files = "STNetTaskQueue/*.h"
end
