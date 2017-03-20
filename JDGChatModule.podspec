Pod::Spec.new do |s|

  s.name         = "JDGChatModule"
  s.version      = "1.0"
  s.summary      = "JDGChatModule is a module using XMPP framework and JSQMessagesViewController"

  s.description  = <<-DESC

JDGChatModule is chat module implementing XMPP framework and JSQMessagesViewController

                   DESC

  s.homepage     = "https://github.com/jefrydagucci/JDGChatModule"

  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE" }

  s.author             = { "Jefry" => "jefrydagucci@gmail.com" }

  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/jefrydagucci/JDGChatModule.git", :tag => "v#{s.version}" }
  s.social_media_url = "http://instagram.com/jefrydagucci"

  s.source_files  = "JDGChatModule", "JDGChatModule/*.{h, m, swift}"

  s.requires_arc = true

  s.dependency "XMPPFramework", "~> 3.7"
  s.dependency "JSQMessagesViewController", "~> 7.3"

end
