//
//  HLSAudioPlayer.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit
import AVKit

enum HLSAudioPlayerState {
    case uninitialized
    case fetching
    case playing
    case paused
    case completed
    case error
}

public class HLSAudioPlayer: UIView {
    var state: HLSAudioPlayerState = .uninitialized {
        didSet {
            print("oldState: \(oldValue) -> newState: \(state)")
        }
    }
    var url: URL?
    
    private let downloader = HLSSegmentDownloader()
    private var player: AVAudioPlayer?
    @IBOutlet private var contentView: UIView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContent()
    }
    
    public func load() throws {
        guard let url = url else { throw HLSPlayerError.missingUrl }
        
        let parser = try HLSParser(url: url)
        let highestQualityAudioTrack = parser.tracks.filter { $0.type == .audio }.compactMap { $0.data }.sorted { $0.averageBitrate > $1.averageBitrate}.first
        
        guard let track = highestQualityAudioTrack else { throw HLSPlayerError.missingTrack }
        
        state = .fetching
        
        downloader.progressHandler = { progress in
            print("\(progress * 100)%")
        }
        downloader.downloadSegments(of: track) { response in
            do {
                let urls = try response()
//                self.player = try AVAudioPlayer(contentsOf: urls[0])
                self.player = try AVAudioPlayer(contentsOf: self.dummyUrl())
                self.player?.delegate = self
                self.state = .playing
                self.player?.play()
            }
            catch {
                self.state = .error
            }
        }
    }
    
    private func dummyUrl() -> URL {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "track", withExtension: "mp3") else {
            fatalError("Failed fetching dummy track")
        }
        return url
    }
    
    private func setupContent() {
        Bundle(for: type(of: self)).loadNibNamed("HLSAudioPlayer", owner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        print("tapped")
        do {
            url = URL(string: "http://pubcache1.arkiva.de/test/hls_index.m3u8")
            try load()
        }
        catch {
            state = .error
        }
    }
}

extension HLSAudioPlayer: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .uninitialized
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        state = .error
    }
    
}
