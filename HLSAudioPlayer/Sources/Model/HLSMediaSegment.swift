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
    public let byteRange: Range<Int>?
    public let title: String?
    
    public init(duration: Double, uri: URL, byteRange: Range<Int>?, title: String?) {
        self.duration = duration
        self.uri = uri
        self.byteRange = byteRange
        self.title = title
    }
}
