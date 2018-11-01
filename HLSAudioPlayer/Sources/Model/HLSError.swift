//
//  HLSError.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit

public enum HLSError: Error {
    case invalidPlaylist
    case invalidTrackMetadata
    case missingTrackMediaType
    case unknownTrackMediaType
    case missingTrackGroupId
    case missingTrackName
    case invalidTrackAutoSelectAttribute
    case invalidTrackUriAttribute
    case missingTrackDataHeaders
    case missingTrackDataVersion
    case invalidTrackDataVersion
    case invalidTrackDataMediaSequence
    case missingTrackDataTargetDuration
    case invalidTrackDataTargetDuration
    case missingSegmentDuration
    case invalidSegmentDuration
    case missingSegmentUri
    case invalidSegmentUri
    case invalidSegmentByteRange
    case multipleErrors([Error])
}
