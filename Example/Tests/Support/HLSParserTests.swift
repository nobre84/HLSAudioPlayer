//
//  HLSParserTests.swift
//  HLSAudioPlayer_Tests
//
//  Created by Rafael Nobre on 24/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import Nimble
import HLSAudioPlayer

class HLSParserTests: XCTestCase {

    func testCanBeInitializedWithValidPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index"))
        }.notTo(throwError())
    }
    
    func testParserCannotBeInitializedWithEmptyPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "empty"))
        }.to(throwError(HLSError.invalidPlaylist))
    }
    
    func testParserCannotBeInitializedWithInvalidPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid"))
        }.to(throwError(HLSError.invalidPlaylist))
    }
    
    func testParserCantExtrackAudioTracksFromNonMasterPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_a192K_v4"))
            expect(parser.tracks).to(beEmpty())
        }.notTo(throwError())
    }
    
    func testParserCanExtractAudioTracksFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            expect(parser.tracks).notTo(beEmpty())
        }.notTo(throwError())
    }
    
    func testParserCanUnderstandAnyKindOfNewlineCharacters() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index_newline_characters"))
            expect(parser.tracks).notTo(beEmpty())
        }.notTo(throwError())
    }
    
    func testParserCanExtractAudioTracksWithURLsFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            expect(parser.tracks).notTo(beEmpty())
            let firstTrack = parser.tracks.first!
            expect(firstTrack.type) == .audio
            expect(firstTrack.groupId) == "audio-0"
            expect(firstTrack.name) == "Default"
            expect(firstTrack.isAutoSelect) == true
            expect(firstTrack.isDefault) == true
            expect(firstTrack.uri).notTo(beNil())
            // TODO check track data
        }.notTo(throwError())
    }
    
    func testParserMustFailToParsePlaylistsIncludingUrisForClosedCaptionsTracks() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_uri"))
            }.to(throwError(HLSError.invalidTrackUriAttribute))
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackType() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_type"))
            }.to(throwError(HLSError.missingTrackMediaType))
    }
    
    func testParserMustFailToParsePlaylistsUnknownTrackType() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_unknown_type"))
        }.to(throwError(HLSError.unknownTrackMediaType))
    }
    
    func testParserMayIgnorePartiallyFilledUnknownTrackAttributes() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_unknown_attribute"))
        }.notTo(throwError())
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackName() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_name"))
        }.to(throwError(HLSError.missingTrackName))
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackGroupId() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_group_id"))
        }.to(throwError(HLSError.missingTrackGroupId))
    }
    
    func testParserMustFailToParsePlaylistsWithPresentAutoSelectAttributeWhichIsNotTrueWhenDefaultAttributeIsTrue() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_invalid_autoselect_value"))
        }.to(throwError(HLSError.invalidTrackAutoSelectAttribute))
    }
    
    func testParserMustParseTrackDataWhenUriIsPresent() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            expect(parser.tracks.first?.data).notTo(beNil())
            
        }.notTo(throwError())
    }
    
    func testParserMayNotParseTrackDataWhenUriIsAbsent() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index_no_track_uris"))
            expect(parser.tracks.first?.data).to(beNil())
        }.notTo(throwError())
    }
    
    func testParserCanFollowRelativeUriToTrackData() {
        
    }
    
    func testParserCanFollowAbsoluteUriToTrackData() {
        
    }
    
    func testParserCanExtractAudioTracksBitratesFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
//            expect(parser.tracks.first?.data?.averageBitrate) > 100
//            expect(parser.tracks.first?.data?.peakBitrate) > 100
        }.notTo(throwError())
    }
    
    func testParserCanExtractAudioTracksSegmentsFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
//            expect(parser.tracks.first?.data?.segments).notTo(beEmpty())
        }.notTo(throwError())
    }

}
