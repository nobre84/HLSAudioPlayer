//
//  HLSAudioPlayer.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit
import AVKit

fileprivate enum HLSAudioPlayerState {
    case uninitialized
    case fetching
    case playing
    case paused
    case error(Error?)
}

public class HLSAudioPlayer: UIView {
    
    public var url: URL?
    
    // MARK: - Private Variables
    
    private let downloader = HLSSegmentDownloader()
    private var player: AVAudioPlayer?
    
    private var state: HLSAudioPlayerState = .uninitialized {
        didSet {
            print("oldState: \(oldValue) -> newState: \(state)")
            handleStateChange(state)
        }
    }
    
    deinit {
        print("Player gone")
    }
    
    private lazy var bgLayer: CAShapeLayer = {
        let width = iconImageView.bounds.size.width
        let pi = CGFloat(Double.pi)
        let path = UIBezierPath(arcCenter: iconImageView.center, radius: width / 8, startAngle: 0, endAngle: 2 * pi, clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.withAlphaComponent(0.8).cgColor
        shapeLayer.lineWidth = 32
        
        shapeLayer.addSublayer(coverLayer)
        
        return shapeLayer
    }()
    
    private lazy var coverLayer: CAShapeLayer = {
        let width = iconImageView.bounds.size.width
        let pi = CGFloat(Double.pi)
        let path = UIBezierPath(arcCenter: iconImageView.center, radius: width / 8, startAngle: 3 * pi / 2, endAngle: 2 * pi + 3 * pi / 2, clockwise: true)
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor(red: 83/255, green: 124/255, blue: 143/255, alpha: 0.8).cgColor
        shapeLayer.lineWidth = 32
        return shapeLayer
    }()
    
    // MARK: Outlets
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    // MARK: - Life Cycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupContent()
    }
    
    // MARK: - Private Methods
    
    private func fetch() throws {
        guard let url = url else { throw HLSPlayerError.missingUrl }
        
        let parser = try HLSParser(url: url)
        let highestQualityAudioTrack = parser.tracks.filter { $0.type == .audio }.compactMap { $0.data }.sorted { $0.averageBitrate > $1.averageBitrate}.first
        
        guard let track = highestQualityAudioTrack else { throw HLSPlayerError.missingTrack }
        
        downloader.progressHandler = { progress in
            self.setLoadingPercentage(to: progress)
        }
        setLoadingPercentage(to: 0)
        downloader.downloadSegments(of: track) { response in
            do {
                _ = try response()
                // TODO: Handle raw ts content
                // self.player = try AVAudioPlayer(contentsOf: urls[0])
                self.player = try AVAudioPlayer(contentsOf: self.dummyUrl())
                self.player?.delegate = self
                self.state = .playing
            }
            catch {
                // Dismisses the loader in case of errors
                self.setLoadingPercentage(to: 1)
                self.state = .error(error)
            }
        }
    }
    
    private func play() {
        if player?.play() ?? false {
            iconImageView.image = Resources.iconPause
        }
    }
    
    private func pause() {
        if case .paused = state {
            player?.pause()
            iconImageView.image = Resources.iconPlay
        }
    }
    
    private func complete() {
        do {
            try HLSSegmentDownloader.clearCaches()
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
    
    private func setLoadingPercentage(to value: Double) {
        if value == 0 {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.coverLayer.strokeEnd = 0
            CATransaction.commit()
            self.iconImageView.layer.addSublayer(self.bgLayer)
        }
        else if value == 1 {
            self.bgLayer.removeFromSuperlayer()
        }
        else {
            self.coverLayer.strokeEnd = CGFloat(value)
        }
    }
    
    private func handleStateChange(_ newState: HLSAudioPlayerState) {
        do {
            switch state {
            case .uninitialized:
                complete()
            case .fetching:
                try fetch()
            case .playing:
                play()
            case .paused:
                pause()
            case .error(let error):
                print(error as Any)
            }
        }
        catch {
            state = .error(error)
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
