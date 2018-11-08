Pod::Spec.new do |s|
  s.name             = 'HLSAudioPlayer'
  s.version          = '0.1.1'
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

  s.subspec 'Shared' do |ss|
    ss.source_files = 'HLSAudioPlayer/Shared/Sources/**/*.*'
  end

  s.subspec 'Parser' do |ss|
    ss.source_files = 'HLSAudioPlayer/Parser/Sources/**/*.*'

    ss.dependency 'HLSAudioPlayer/Shared'
  end

  s.subspec 'Downloader' do |ss|
    ss.source_files = 'HLSAudioPlayer/Downloader/Sources/**/*.*'

    ss.dependency 'HLSAudioPlayer/Parser'
    ss.dependency 'RNConcurrentBlockOperation'
  end

  s.subspec 'Player' do |ss|
    ss.source_files = 'HLSAudioPlayer/Player/Sources/**/*.*'
    ss.resources = 'HLSAudioPlayer/Player/Resources/**/*.*'

    ss.dependency 'HLSAudioPlayer/Downloader'
  end

  s.subspec 'GestureHelper' do |ss|
    ss.source_files = 'HLSAudioPlayer/GestureHelper/Sources/**/*.*'
  end

end
