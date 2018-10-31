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
                let handle = FileHandle(forReadingAtPath: OHPathForFile("stub.ts", type(of: self))!)
                handle?.seek(toFileOffset: UInt64(range.location))
                let segmentData = handle?.readData(ofLength: range.length)
                return OHHTTPStubsResponse(data: segmentData!, statusCode:206, headers:["Content-Type": "video/MP2T"])
            }

            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        // Tests it can run without caches first
        do {
            try clearCaches()
        }
        catch {
            fail("Failed to clear caches")
        }
        
        downloadExpectations()
        
        // Now test again, with a warm cache
        
        downloadExpectations()
        
    }
    
    private func downloadExpectations() {
        expect { () -> Void in
            let parser = try HLSParser(url: URL(string: "https://stub.com/hls_index.m3u8")!)
            let trackData = parser.tracks[0].data!
            
            waitUntil { done in
                self.downloader.downloadSegments(of: trackData) { response in
                    expect { () -> Void in
                        let urls = try response()
                        expect(urls.count) == 1
                        expect(urls[0].isFileURL) == true
                        let segmentData = try Data(contentsOf: urls[0])
                        let totalSize = trackData.segments.map { $0.byteRange?.length ?? 0 }.reduce(0, +)
                        expect(segmentData.count) == totalSize
                        let stubbedData = Stubs.data(from: "stub", extension: "ts")
                        expect(stubbedData) == segmentData
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
    
    private func clearCaches() throws {
        let manager = FileManager.default
        let cachesDir = try manager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let files = try manager.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: nil)
        print("Clearing cache with \(files) files")
        for url in files {
            try manager.removeItem(at: url)
        }
    }
    
}
