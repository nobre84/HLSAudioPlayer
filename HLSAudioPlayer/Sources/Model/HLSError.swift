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
    case invalidTrackAutoSelectValue
}
