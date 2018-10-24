Pod::Spec.new do |s|
  s.name             = 'HLSAudioPlayer'
  s.version          = '0.1.0'
  s.summary          = 'A mini framework for parsing and playing audio streams from HLS playlists.'

  s.description      = <<-DESC
    HLSAudioPlayer is a mini framework for parsing and playing audio streams from HLS playlists.
                       DESC

  s.homepage         = 'https://github.com/nobre84/HLSAudioPlayer'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Rafael Nobre' => 'nobre84@gmail.com' }
  s.source           = { :git => 'https://github.com/nobre84/HLSAudioPlayer.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/nobre84'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'

  s.source_files = 'HLSAudioPlayer/Sources/**/*.*'
  #s.resources = 'HLSAudioPlayer/Assets/**/*.*'
end
