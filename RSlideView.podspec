Pod::Spec.new do |s|
  s.name         = 'RSlideView'
  s.version      = '1.0.2'
  s.authors      = { 'Ricky Tan' => 'ricky.tan.xin@gmail.com' }
  s.homepage     = 'https://github.com/rickytan/RSlideView'
  s.platform     = :ios
  s.summary      = 'A easy-to-use and wysiwyg view for slide shows, support Interface Builder'
  s.source       = { :git => 'https://github.com/rickytan/RSlideView.git', :tag => s.version.to_s }
  s.license      = 'MIT'
  s.frameworks   = 'UIKit'
  s.source_files = 'Classes'
  s.requires_arc = true
  s.ios.deployment_target = '5.0'
  s.social_media_url = 'http://rickytan.cn'
end