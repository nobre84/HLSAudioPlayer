//
//  HLSParser.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

let playlistHeaderIdentifier = "#EXTM3U"
let playlistTrackIdentifier = "#EXT-X-MEDIA"
let playlistAudioTypeIdentifier = "TYPE=AUDIO"

public class HLSParser {
    
    private var url: URL
    private var playlist: String
    
    public var tracks: [HLSAudioTrack] = []
    
    public init(url: URL) throws {
        self.url = url
        
        let contents = try String(contentsOf: url)
        let playlist = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        guard playlist.count > 0, playlist.starts(with: playlistHeaderIdentifier) else { throw HLSError.invalidPlaylist }
        
        self.playlist = playlist
        
        parseTracks()
    }
    
    private func parseTracks() {
        let lines = playlist.split(separator: "\n")
        let audioTracks = lines.compactMap { $0.starts(with: playlistTrackIdentifier) && $0.contains(playlistAudioTypeIdentifier) ? $0 : nil }
        tracks = audioTracks.map { _ in HLSAudioTrack() }
    }
}
