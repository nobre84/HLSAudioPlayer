//
//  HLSMediaTrack.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit

public class HLSMediaTrack {
    public let type: HLSMediaType
    public let groupId: String
    public let name: String
    public let isDefault: Bool
    public let isAutoSelect: Bool
    public let url: URL?
    public let data: HLSMediaTrackData?
    
    public init(type: HLSMediaType, groupId: String, name: String, isDefault: Bool = true, isAutoSelect: Bool = false, url: URL?, data: HLSMediaTrackData?) {
        self.type = type
        self.groupId = groupId
        self.name = name
        self.isDefault = isDefault
        self.isAutoSelect = isAutoSelect
        self.url = url
        self.data = data
    }
}
