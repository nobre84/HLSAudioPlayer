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
    case error(Error?)
}

public class HLSAudioPlayer: UIView {
    var state: HLSAudioPlayerState = .uninitialized {
        didSet {
            do {
                print("oldState: \(oldValue) -> newState: \(state)")
                switch state {
                case .uninitialized:
                    complete()
                case .fetching:
                    try fetch()
                case .playing:
                    try play()
                case .paused:
                    pause()
                case .error(let error):
                    print(error as Any)                    
                }
            }
            catch {
                defer {
                    state = .error(error)
                }
            }
        }
    }
    public var url: URL?
    
    // MARK: Private Variables
    
    private let downloader = HLSSegmentDownloader()
    private var player: AVAudioPlayer?
    private lazy var coverLayer: CAShapeLayer = {
        let width = iconImageView.bounds.size.width
        let pi = CGFloat(Double.pi)
        let path = UIBezierPath(arcCenter: iconImageView.center, radius: width / 2, startAngle: 0, endAngle: 2 * pi, clockwise: false)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.7).cgColor
        shapeLayer.lineWidth = width
        return shapeLayer
    }()
    
    private func setLoadingPercentage(to value: Double) {
        if value == 0 {
            iconImageView.layer.addSublayer(coverLayer)
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        coverLayer.strokeEnd = CGFloat(1 - value)
        CATransaction.commit()
        if value == 1 {
            coverLayer.removeFromSuperlayer()
        }
    }
    
    // MARK: Outlets
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContent()
    }
    
    public func fetch() throws {
        guard let url = url else { throw HLSPlayerError.missingUrl }
        
        let parser = try HLSParser(url: url)
        let highestQualityAudioTrack = parser.tracks.filter { $0.type == .audio }.compactMap { $0.data }.sorted { $0.averageBitrate > $1.averageBitrate}.first
        
        guard let track = highestQualityAudioTrack else { throw HLSPlayerError.missingTrack }
        
        downloader.progressHandler = { progress in
            self.setLoadingPercentage(to: progress)
        }
        downloader.downloadSegments(of: track) { response in
            do {
                let urls = try response()
//                self.player = try AVAudioPlayer(contentsOf: urls[0])
                self.player = try AVAudioPlayer(contentsOf: self.dummyUrl())
                self.player?.delegate = self
                self.state = .playing
            }
            catch {
                self.state = .error(error)
            }
        }
    }
    
    public func play() throws {
        player?.play()
        iconImageView.image = Resources.iconPause
    }
    
    public func pause() {
        player?.pause()
        iconImageView.image = Resources.iconPlay
    }
    
    public func complete() {
        do {
            try HLSSegmentDownloader.clearCaches()
            setLoadingPercentage(to: 0)
            iconImageView.image = Resources.iconPlay
        }
        catch {
            state = .error(error)
        }
    }
    
    private func dummyUrl() -> URL {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "coo-coo", withExtension: "mp3") else {
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
        setLoadingPercentage(to: 0)
    }
    
    @objc private func handleTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
        switch state {
        case .uninitialized:
            state = .fetching
        case .playing:
            state = .paused
        case .paused:
            state = .playing
        default:
            break
        }
    }
}

extension HLSAudioPlayer: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .uninitialized
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        state = .error(error)
    }
    
}
