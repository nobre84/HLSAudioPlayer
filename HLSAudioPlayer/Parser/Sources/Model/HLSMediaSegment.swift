//
//  HLSMediaSegment.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit

public class HLSMediaSegment {
    public let duration: Double
    public let uri: URL
    public let byteRange: NSRange?
    public let title: String?
    public let bitrate: Double
    
    public init(duration: Double, uri: URL, byteRange: NSRange?, title: String?) {
        self.duration = duration
        self.uri = uri
        self.byteRange = byteRange
        self.title = title
        if let byteRange = byteRange {
            bitrate = Double(byteRange.length) / duration * 8 / 1024 /*kilobits*/
        }
        else {
            bitrate = 0
        }
    }
}
