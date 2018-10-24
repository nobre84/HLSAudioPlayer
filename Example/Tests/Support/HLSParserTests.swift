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
    
    func testParserCanExtractAudioTracksWithURLsFromValidPlaylist() {
        // TODO
    }
    
    func testParserCanExtractAudioTracksAverageBitrateFromValidPlaylist() {
        // TODO
    }
    
    func testParserCanExtractAudioTracksSegmentsFromValidPlaylist() {
        // TODO
    }

}
