Pod::Spec.new do |s|
  s.name         = "CSSOperation"
  s.version      = "0.0.3"
  s.summary      = "NSOperation的一个扩展。便于控制任务（模块）执行顺序和方式。"
  s.license      = { :type => 'MIT License', :file => 'LICENSE' }
  s.authors      = { 'Joslyn' => 'cs_joslyn@foxmail.com' }
  s.homepage     = 'https://github.com/JoslynWu/CSSOperation'
  s.social_media_url   = "http://www.jianshu.com/u/fb676e32e2e9"
  s.ios.deployment_target = '8.0'
  s.source       = { :git => 'https://github.com/JoslynWu/CSSOperation.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.source_files = 'CSSOperation/*.{h,m}'
  s.public_header_files = 'CSSOperation/*.{h}'
end
