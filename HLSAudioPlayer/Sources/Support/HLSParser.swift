//
//  HLSParser.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

// Tags
let playlistTagIdentifier = "#EXT"
let playlistHeaderIdentifier = "#EXTM3U"
let playlistTrackIdentifier = "#EXT-X-MEDIA:"
let playlistSegmentIdentifier = "#EXTINF:"
let playlistSegmentByteRangeIdentifier = "#EXT-X-BYTERANGE:"
let playlistTrackAllowCacheIdentifier = "#EXT-X-ALLOW-CACHE"
let playlistTrackMediaSequenceIdentifier = "#EXT-X-MEDIA-SEQUENCE"
let playlistTrackVersionIdentifier = "#EXT-X-VERSION"
let playlistTrackTargetDurationIdentifier = "#EXT-X-TARGETDURATION"
let playlistEnumerationYes = "YES"
let playlistEnumerationNo = "NO"
let playlistEndIdentifier = "#EXT-X-ENDLIST"

let segmentDurationKey = "SEGMENT_DURATION"
let segmentTitleKey = "SEGMENT_TITLE"
let segmentByteRangeLengthKey = "SEGMENT_BYTERANGE_LENGTH"
let segmentByteRangeOffsetKey = "SEGMENT_BYTERANGE_OFFSET"
let segmentUriKey = "SEGMENT_URI"

public class HLSParser {
    
    private var url: URL?
    private var playlist: String?
    
    public var tracks: [HLSMediaTrack] = []
    
    public init(url: URL) throws {
        self.url = url
        try parse()
    }
    
    init() {
    }
    
    public func parse() throws {
        if let url = url {
            let playlist = try String(contentsOf: url).trimmingCharacters(in: .whitespacesAndNewlines)
            guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
            
            self.playlist = playlist
            
            try parseTracks(from: playlist)
        }
    }
    
    func parseTrack(from metadata: String) throws -> HLSMediaTrack {
        let attributes = try parseTrackAttributes(from: metadata)
        
        // Required tags
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
    
    func parseTrackData(from playlist: String) throws -> HLSMediaTrackData {
        let headerTags = try parseTrackDataHeaderTags(from: playlist.slice(from: playlistHeaderIdentifier, to: playlistSegmentIdentifier))
        
        // Required tags
        guard let versionString = headerTags[playlistTrackVersionIdentifier] else { throw HLSError.missingTrackDataVersion }
        guard let version = Int(versionString) else { throw HLSError.invalidTrackDataVersion }
        guard let targetDurationString = headerTags[playlistTrackTargetDurationIdentifier] else { throw HLSError.missingTrackDataTargetDuration }
        guard let targetDuration = Int(targetDurationString) else { throw HLSError.invalidTrackDataTargetDuration }
        
        let allowsCacheString = headerTags[playlistTrackAllowCacheIdentifier]
        let allowsCache = allowsCacheString != nil ? allowsCacheString == playlistEnumerationYes : nil
        let mediaSequenceString = headerTags[playlistTrackMediaSequenceIdentifier] ?? "0"
        guard let mediaSequence = Int(mediaSequenceString) else { throw HLSError.invalidTrackDataMediaSequence }
        
        let segments = try parseTrackSegments(from: playlist)
        
        return HLSMediaTrackData(version: version, mediaSequence: mediaSequence, allowsCache: allowsCache, targetDuration: targetDuration, segments: segments)
    }
    
    func parseTrackSegments(from playlist: String) throws -> [HLSMediaSegment] {
        var segments = [HLSMediaSegment]()
        var currentSegmentData = [String: String]()
        var currentError: Error?
        playlist.enumerateLines { line, stop in
            if line.starts(with: playlistSegmentIdentifier) || line.starts(with: playlistEndIdentifier) {
                if !currentSegmentData.isEmpty {
                    do {
                        segments.append(try self.parseSegment(from: currentSegmentData))
                        currentSegmentData.removeAll()
                    }
                    catch {
                        currentError = error
                        stop = true
                    }
                }
                let attributes = line[playlistSegmentIdentifier.endIndex...].split(separator: ",")
                currentSegmentData[segmentDurationKey] = attributes[safe: 0].flatMap { String($0) }
                currentSegmentData[segmentTitleKey] = attributes[safe: 1].flatMap { String($0) }
            }
            else if line.starts(with: playlistSegmentByteRangeIdentifier) {
                let attributes = line[playlistSegmentByteRangeIdentifier.endIndex...].split(separator: "@")
                currentSegmentData[segmentByteRangeLengthKey] = attributes[safe: 0].flatMap { String($0) }
                currentSegmentData[segmentByteRangeOffsetKey] = attributes[safe: 1].flatMap { String($0) }
            }
            else if !line.starts(with: playlistTagIdentifier) {
                currentSegmentData[segmentUriKey] = line
            }
        }
        if let currentError = currentError {
            throw currentError
        }
        return segments
    }
    
    private func parseSegment(from segmentData: [String: String]) throws -> HLSMediaSegment {
        guard let durationString = segmentData[segmentDurationKey] else { throw HLSError.missingSegmentDuration }
        guard let duration = Double(durationString) else { throw HLSError.invalidSegmentDuration }
        let title = segmentData[segmentTitleKey]
        guard let uriString = segmentData[segmentUriKey] else { throw HLSError.missingSegmentUri }
        guard let uri = URL(string: uriString, relativeTo: url) else { throw HLSError.invalidSegmentUri }
        
        let byteRange = try parseSegmentByteRange(lengthString: segmentData[segmentByteRangeLengthKey], offsetString: segmentData[segmentByteRangeOffsetKey])
        
        return HLSMediaSegment(duration: duration, uri: uri, byteRange: byteRange, title: title)
    }
    
    private func parseSegmentByteRange(lengthString: String?, offsetString: String?) throws -> NSRange? {
        guard let lengthString = lengthString else { return nil }
        guard let length = Int(lengthString) else { throw HLSError.invalidSegmentByteRange }
        var range = NSRange(location: 0, length: length)
        if let offsetString = offsetString,
            let offset = Int(offsetString) {
            range.location = offset
        }
        return range
    }
    
    private func parseTracks(from playlist: String) throws {
        let lines = playlist.components(separatedBy: .newlines)
        let audioTracks = lines.compactMap { $0.starts(with: playlistTrackIdentifier) ? $0.dropFirst(playlistTrackIdentifier.count) : nil }
        tracks = try audioTracks.map { try parseTrack(from: String($0)) }
    }
    
    private func reduceToStringDict(_ splitArray: [[String.SubSequence]]) -> [String: String] {
        return splitArray.reduce([String: String]()) { current, next -> [String: String] in
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
    
    private func parseTrackAttributes(from metadata: String) throws -> [String: String] {
        let step1 = metadata.split(separator: ",")
        let step2 = step1.map { $0.split(separator: "=") }
        return reduceToStringDict(step2)
    }
    
    private func parseTrackData(from uri: URL?) throws -> HLSMediaTrackData? {
        guard let uri = uri else { return nil }
        let playlist = try String(contentsOf: uri).trimmingCharacters(in: .whitespacesAndNewlines)
        guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
        return try parseTrackData(from: playlist)
    }
    
    private func parseTrackDataHeaderTags(from header: String?) throws -> [String: String] {
        guard let header = header?.trimmingCharacters(in: .whitespacesAndNewlines), header.count > 0 else { throw HLSError.missingTrackDataHeaders }
        
        let step1 = header.components(separatedBy: .newlines)
        let step2 = step1.map { $0.split(separator: ":") }
        return reduceToStringDict(step2)
    }
}
