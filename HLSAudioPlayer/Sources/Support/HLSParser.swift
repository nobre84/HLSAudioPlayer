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
        
        let playlist = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
        guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
        
        self.playlist = playlist
        
        try parseTracks(from: playlist)
    }
    
    private func parseTracks(from playlist: String) throws {
        let lines = playlist.split(separator: "\n")
        let audioTracks = lines.compactMap { $0.starts(with: playlistTrackIdentifier) ? $0.dropFirst(playlistTrackIdentifier.count) : nil }
        tracks = try audioTracks.map { try parseTrack(from: String($0)) }
    }
    
    private func parseTrack(from metadata: String) throws -> HLSMediaTrack {
        let attributes = try parseTrackAttributes(from: metadata)
        
        guard let typeRawValue = attributes["TYPE"] else { throw HLSError.missingTrackMediaType }
        guard let type = HLSMediaType(rawValue: typeRawValue) else { throw HLSError.unknownTrackMediaType }
        guard let groupId = attributes["GROUP-ID"] else { throw HLSError.missingTrackGroupId }
        guard let name = attributes["NAME"] else { throw HLSError.missingTrackName }
        let isDefault = attributes["DEFAULT"] != "NO"
        let isAutoSelect = attributes["AUTOSELECT"] == "YES"
        
        // If the AUTOSELECT attribute is present, its value MUST be YES if the value of the DEFAULT attribute is YES.
        if attributes["AUTOSELECT"] != nil, isDefault, !isAutoSelect { throw HLSError.invalidTrackAutoSelectAttribute }
        
        var trackUri: URL?
        if let trackUriString = attributes["URI"] {
            trackUri = URL(string: trackUriString, relativeTo: url)
        }
        let trackData = try parseTrackData(from: trackUri)
        
        // If the TYPE is CLOSED-CAPTIONS, the URI attribute MUST NOT be present.
        guard trackUri == nil || type != .closedCaptions else { throw HLSError.invalidTrackUriAttribute }
        
        return HLSMediaTrack(type: type, groupId: groupId, name: name, isDefault: isDefault, isAutoSelect: isAutoSelect, url: trackUri, data: trackData)
    }
    
    private func parseTrackAttributes(from metadata: String) throws -> [String: String] {
        let step1 = metadata.split(separator: ",")
        let step2 = step1.map { $0.split(separator: "=") }
        return step2.reduce([String: String]()) { current, next -> [String: String] in
            guard let key = next[safe: 0],
                let value = next[safe: 1] else { return current }
            let valueString = String(value).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
            if !valueString.isEmpty {
                var new = current
                new[String(key)] = valueString
                return new
            }
            return current
        }
    }
    
    private func parseTrackData(from uri: URL?) throws -> HLSMediaTrackData? {
        guard let uri = uri else { return nil }
        
        let playlist = try String(contentsOf: uri).trimmingCharacters(in: .whitespacesAndNewlines)
        guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
        
        
        return HLSMediaTrackData(version: 1, allowsCache: true, targetDuration: 1, averageBitrate: 1, peakBitrate: 1, segments: [])
    }
}
