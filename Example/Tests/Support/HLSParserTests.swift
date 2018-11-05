//
//  HLSParserTests.swift
//  HLSAudioPlayer_Tests
//
//  Created by Rafael Nobre on 24/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import Nimble
import OHHTTPStubs
@testable import HLSAudioPlayer

class HLSParserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        OHHTTPStubs.onStubActivation() { request, stub, _ in
            print("Stubbing \(request) with \(stub)")
        }
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testCanBeInitializedWithValidPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index"))
        }.notTo(throwError())
    }
    
    func testParserCannotBeInitializedWithEmptyPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "empty"))
        }.to(throwError(HLSParserError.invalidPlaylist))
    }
    
    func testParserCannotBeInitializedWithInvalidPlaylist() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid"))
        }.to(throwError(HLSParserError.invalidPlaylist))
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
            let parser = try HLSParser(url: Stubs.url(of: "hls_index_crlf_newlines"))
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
        }.to(throwError(HLSParserError.invalidTrackUriAttribute))
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackType() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_type"))
        }.to(throwError(HLSParserError.missingTrackMediaType))
    }
    
    func testParserMustFailToParsePlaylistsUnknownTrackType() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_unknown_type"))
        }.to(throwError(HLSParserError.unknownTrackMediaType))
    }
    
    func testParserMayIgnorePartiallyFilledUnknownTrackAttributes() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_unknown_attribute"))
        }.notTo(throwError())
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackName() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_name"))
        }.to(throwError(HLSParserError.missingTrackName))
    }
    
    func testParserMustFailToParsePlaylistsMissingTrackGroupId() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_missing_group_id"))
        }.to(throwError(HLSParserError.missingTrackGroupId))
    }
    
    func testParserMustFailToParsePlaylistsWithPresentAutoSelectAttributeWhichIsNotTrueWhenDefaultAttributeIsTrue() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "invalid_track_invalid_autoselect_value"))
        }.to(throwError(HLSParserError.invalidTrackAutoSelectAttribute))
    }
    
    func testParserMustIgnoreInvalidDefaultValue() {
        let trackAttributes = """
        TYPE=AUDIO,GROUP-ID="audio-0",NAME="Default",AUTOSELECT=BANANA,DEFAULT=BANANA
        """
        expect { () -> Void in
            let parser = HLSParser()
            let track = try parser.parseTrack(from: trackAttributes)
            expect(track.isDefault) == true
        }.to(throwError())
    }
    
    func testParserMustIgnoreInvalidAutoselectValue() {
        let trackAttributes = """
        TYPE=AUDIO,GROUP-ID="audio-0",NAME="Default",AUTOSELECT=BANANA,DEFAULT=YES
        """
        expect { () -> Void in
            let parser = HLSParser()
            let track = try parser.parseTrack(from: trackAttributes)
            expect(track.isAutoSelect) == false
        }.to(throwError())
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
    
    func testParserCanFollowRemoteUriToTrackData() {
        stub(condition: isHost("stub.com")) { request in
            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        expect { () -> Void in
            _ = try HLSParser(url: URL(string: "https://stub.com/hls_index.m3u8")!)
        }.notTo(throwError())
    }
    
    func testParserMustFailToParseTrackDataWithoutHeader() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_invalid_track"))
        }.to(throwError(HLSParserError.invalidPlaylist))
    }
    
    func testParserMustFailToParseTrackDataWithoutHeaders() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_no_track_data_headers"))
        }.to(throwError(HLSParserError.missingTrackDataHeaders))
    }
    
    func testParserMustFailToParseTrackDataWithoutVersion() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_missing_track_data_version"))
        }.to(throwError(HLSParserError.missingTrackDataVersion))
    }
    
    func testParserMustFailToParseTrackDataWithInvalidVersion() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_invalid_track_data_version"))
        }.to(throwError(HLSParserError.invalidTrackDataVersion))
    }
    
    func testParserMustFailToParseTrackDataWithoutTargetDuration() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_missing_target_duration"))
        }.to(throwError(HLSParserError.missingTrackDataTargetDuration))
    }
    
    func testParserMustFailToParseTrackDataWithInvalidTargetDuration() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_invalid_target_duration"))
            }.to(throwError(HLSParserError.invalidTrackDataTargetDuration))
    }
    
    func testParserMayParseTrackDataWithoutMediaSequence() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index_missing_media_sequence"))
            expect(parser.tracks.first?.data?.mediaSequence) == 0
        }.notTo(throwError())
    }
    
    func testParserMustFailToParseTrackDataWithInvalidMediaSequence() {
        expect { () -> Void in
            _ = try HLSParser(url: Stubs.url(of: "hls_index_invalid_media_sequence"))
        }.to(throwError(HLSParserError.invalidTrackDataMediaSequence))
    }
    
    func testParserMayParseTrackDataWithoutAllowCache() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.allowsCache).to(beNil())
        }.notTo(throwError())
    }
    
    func testParserMustParseTrackDataWithValidAllowCacheValue() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXT-X-ALLOW-CACHE:YES
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.allowsCache) == true
        }.notTo(throwError())
    }
    
    func testParserCanParseTrackBitratesFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            let hls192AvgBitrate = parser.tracks[0].data?.averageBitrate
            let hls192PeakBitrate = parser.tracks[0].data?.peakBitrate
            let hls256AvgBitrate = parser.tracks[1].data?.averageBitrate
            let hls256PeakBitrate = parser.tracks[1].data?.peakBitrate
            expect(hls192AvgBitrate) == 210 ± 1
            expect(hls192PeakBitrate) > hls192AvgBitrate!
            expect(hls256AvgBitrate) == 282 ± 1
            expect(hls256PeakBitrate) > hls256AvgBitrate!
        }.notTo(throwError())
    }
    
    func testParserCanParseTrackSegmentsFromValidPlaylist() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            expect(parser.tracks[0].data?.segments.count) == 23
            expect(parser.tracks[1].data?.segments.count) == 23
        }.notTo(throwError())
    }

    func testParserCanParseTrackSegmentsWithTitles() {
        expect { () -> Void in
            let parser = try HLSParser(url: Stubs.url(of: "hls_index"))
            expect(parser.tracks.first?.data?.segments).notTo(beEmpty())
        }.notTo(throwError())
    }
    
    func testParserMustFailToParseSegmentWithoutDuration() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:,
        #EXT-X-BYTERANGE:272976@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            _ = try parser.parseTrackData(from: trackDataHeaders)
        }.to(throwError(HLSParserError.missingSegmentDuration))
    }
    
    func testParserMustFailToParseSegmentWithInvalidDuration() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:abc
        #EXT-X-BYTERANGE:272976@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            _ = try parser.parseTrackData(from: trackDataHeaders)
        }.to(throwError(HLSParserError.invalidSegmentDuration))
    }
    
    func testParserMustParseSegmentWithTitle() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,"UTF8 title 😀"
        #EXT-X-BYTERANGE:272976@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.segments[0].title) == "\"UTF8 title 😀\""
        }.notTo(throwError())
    }
    
    func testParserMustFailToParseSegmentWithoutUri() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976@0
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            _ = try parser.parseTrackData(from: trackDataHeaders)
        }.to(throwError(HLSParserError.missingSegmentUri))
    }
    
    func testParserMustFailToParseSegmentWithInvalidUri() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976@0
        invalid uri with spaces.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            _ = try parser.parseTrackData(from: trackDataHeaders)
        }.to(throwError(HLSParserError.invalidSegmentUri))
    }
    
    func testParserMayParseSegmentWithoutByteRange() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.segments[0].byteRange).to(beNil())
            expect(trackData.averageBitrate) == 0
            expect(trackData.peakBitrate) == 0
            expect(trackData.segments[0].bitrate) == 0
        }.notTo(throwError())
    }
    
    func testParserMayParseSegmentWithoutByteRangeOffset() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.segments[0].byteRange?.location) == 0
        }.notTo(throwError())
    }
    
    func testParserMustParseSegmentWithByteRangeFully() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:272976@1024
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            let trackData = try parser.parseTrackData(from: trackDataHeaders)
            expect(trackData.segments[0].byteRange?.length) == 272976
            expect(trackData.segments[0].byteRange?.location) == 1024
        }.notTo(throwError())
    }
    
    func testParserMustFailToParseSegmentWithInvalidByteRange() {
        let trackDataHeaders = """
        #EXTM3U
        #EXT-X-VERSION:4
        #EXT-X-TARGETDURATION:11
        #EXTINF:10.100689,
        #EXT-X-BYTERANGE:abcd@0
        hls_a192K.ts
        #EXT-X-ENDLIST
        """
        expect { () -> Void in
            let parser = HLSParser()
            _ = try parser.parseTrackData(from: trackDataHeaders)
        }.to(throwError(HLSParserError.invalidSegmentByteRange))
    }
    
}
