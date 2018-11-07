//
//  HLSMediaTrackData.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 25/10/18.
//

import UIKit

public class HLSMediaTrackData {
    public let version: Int
    public let mediaSequence: Int
    public let allowsCache: Bool?
    public let targetDuration: Int
    public let totalDuration: Double
    public let averageBitrate: Double
    public let peakBitrate: Double
    public let segments: [HLSMediaSegment]
    
    public init(version: Int, mediaSequence: Int = 0, allowsCache: Bool? = nil, targetDuration: Int, segments: [HLSMediaSegment]) {
        self.version = version
        self.mediaSequence = mediaSequence
        self.allowsCache = allowsCache
        self.targetDuration = targetDuration
        self.segments = segments
        totalDuration = segments.map { $0.duration }.reduce(0, +)
        let bitrates = segments.map { $0.bitrate }
        peakBitrate = bitrates.max() ?? 0
        averageBitrate = bitrates.reduce(0, +) / Double(bitrates.count)
    }
}
