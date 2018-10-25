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
    public let allowsCache: Bool
    public let targetDuration: Int
    public let averageBitrate: Int
    public let peakBitrate: Int
    public let segments: [HLSMediaSegment]
    
    public init(version: Int, mediaSequence: Int = 0, allowsCache: Bool, targetDuration: Int, averageBitrate: Int, peakBitrate: Int, segments: [HLSMediaSegment]) {
        self.version = version
        self.mediaSequence = mediaSequence
        self.allowsCache = allowsCache
        self.targetDuration = targetDuration
        self.averageBitrate = averageBitrate
        self.peakBitrate = peakBitrate
        self.segments = segments
    }
}
