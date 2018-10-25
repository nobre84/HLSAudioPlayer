//
//  HLSParser.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

let playlistHeaderIdentifier = "#EXTM3U"
let playlistTrackIdentifier = "#EXT-X-MEDIA:"

public class HLSParser {
    
    private var url: URL
    private var playlist: String
    
    public var tracks: [HLSMediaTrack] = []
    
    public init(url: URL) throws {
        self.url = url
        
        let contents = try String(contentsOf: url)
        let playlist = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
        
        self.playlist = playlist
        
        try parseTracks()
    }
    
    private func parseTracks() throws {
        let lines = playlist.split(separator: "\n")
        let audioTracks = lines.compactMap { $0.starts(with: playlistTrackIdentifier) ? $0.dropFirst(playlistTrackIdentifier.count) : nil }
        tracks = try audioTracks.map { try parseTrack(from: String($0)) }
    }
    
    private func parseTrack(from metadata: String) throws -> HLSMediaTrack {
        let attributes = try parseAttributes(from: metadata)
        
        guard let typeRawValue = attributes["TYPE"] else { throw HLSError.missingTrackMediaType }
        guard let type = HLSMediaType(rawValue: typeRawValue) else { throw HLSError.unknownTrackMediaType }
        guard let groupId = attributes["GROUP-ID"] else { throw HLSError.missingTrackGroupId }
        guard let name = attributes["NAME"] else { throw HLSError.missingTrackName }
        let isDefault = attributes["DEFAULT"] != "NO"
        let isAutoSelect = attributes["AUTOSELECT"] == "YES"
        if attributes["AUTOSELECT"] != nil, isDefault, !isAutoSelect {
            throw HLSError.invalidTrackAutoSelectValue
        }
        let trackUrl = URL(string: attributes["URI"] ?? "absent", relativeTo: url)
        
        return HLSMediaTrack(type: type, groupId: groupId, name: name, isDefault: isDefault, isAutoSelect: isAutoSelect, url: trackUrl, data: nil)
    }
    
    private func parseAttributes(from metadata: String) throws -> [String: String] {
        let step1 = metadata.split(separator: ",")
        let step2 = step1.map { $0.split(separator: "=") }
        return try step2.reduce([String: String]()) { current, next -> [String: String] in
            guard let key = next.first,
                let value = next.last else { throw HLSError.invalidTrackMetadata }
            var new = current
            new[String(key)] = String(value).replacingOccurrences(of: "\"", with: "")
            return new
        }
    }
}
