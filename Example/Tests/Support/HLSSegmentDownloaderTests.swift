//
//  HLSSegmentDownloaderTests.swift
//  HLSAudioPlayer_Tests
//
//  Created by Rafael Nobre on 28/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import XCTest
import Nimble
import OHHTTPStubs
@testable import HLSAudioPlayer

class HLSSegmentDownloaderTests: XCTestCase {
    
    let downloader = HLSSegmentDownloader()
    
    func testCanDownloadSegmentData() {
        stub(condition: isHost("stub.com")) { request in
            if let range = self.parseRange(from: request.value(forHTTPHeaderField: "Range")) {
                return OHHTTPStubsResponse(data: Data(count: range.length), statusCode:206, headers:["Content-Type": "video/MP2T"])
            }

            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        expect { () -> Void in
            let parser = try HLSParser(url: URL(string: "https://stub.com/hls_index.m3u8")!)
            let trackData = parser.tracks[0].data!
            
            waitUntil { done in
                self.downloader.downloadSegments(of: trackData) { response in
                    expect { () -> Void in
                        let urls = try response()
                        expect(urls.count) == 1
                    }.notTo(throwError())
                    done()
                }
            }
        }.notTo(throwError())
    }
    
    func testDownloaderCanAddInitialByteRangeRequestCorrectly() {
        let range = NSRange(location: 0, length: 1024)
        expect(self.downloader.createRangeHeader(with: range)) == "bytes=0-1024"
    }
    
    func testDownloaderCanAddIncrementalByteRangeRequestCorrectly() {
        let range = NSRange(location: 1024, length: 1024)
        expect(self.downloader.createRangeHeader(with: range)) == "bytes=1024-2048"
    }
    
    private func parseRange(from httpHeader: String?) -> NSRange? {
        guard let httpHeader = httpHeader else { return nil }
        
        guard let startString = httpHeader.slice(from: "=", to: "-"),
            let start = Int(startString),
            let endString = httpHeader.slice(from: "-"),
            let end = Int(endString) else { return nil }
        return NSRange(location: start, length: end - start)
    }
    
}
