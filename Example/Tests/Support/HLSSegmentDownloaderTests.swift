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
            // Stubbing segments
            if let range = self.parseRange(from: request.value(forHTTPHeaderField: "Range")) {
                let handle = FileHandle(forReadingAtPath: OHPathForFile("stub.ts", type(of: self))!)
                handle?.seek(toFileOffset: UInt64(range.location))
                let segmentData = handle?.readData(ofLength: range.length)
                return OHHTTPStubsResponse(data: segmentData!, statusCode:206, headers:["Content-Type": "video/MP2T"])
            }
            // Stubbing playlists
            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        // Tests it can run without caches first
        do {
            try HLSSegmentDownloader.clearCaches()
        }
        catch {
            fail("Failed to clear caches")
        }
        
        expectationsForTestCanDownloadSegmentData()
        
        // Now test again, with a warm cache
        
        expectationsForTestCanDownloadSegmentData()
    }
    
    private func expectationsForTestCanDownloadSegmentData() {
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
    
    func testDownloaderFailsWithoutNetwork() {
        stub(condition: isHost("stub.com")) { request in
            // Stubbing segments
            if self.parseRange(from: request.value(forHTTPHeaderField: "Range")) != nil {
                let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
                return OHHTTPStubsResponse(error: notConnectedError)
            }
            // Stubbing playlists
            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        expect { () -> Void in
            let parser = try HLSParser(url: URL(string: "https://stub.com/hls_index.m3u8")!)
            let trackData = parser.tracks[0].data!
            
            waitUntil { done in
                self.downloader.downloadSegments(of: trackData) { response in
                    expect { () -> Void in
                        _ = try response()
                    }.to(throwError())
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
    
    func testDownloaderCallsProgressHandlerWhenProvided() {
        stub(condition: isHost("stub.com")) { request in
            // Stubbing segments
            if let range = self.parseRange(from: request.value(forHTTPHeaderField: "Range")) {
                let handle = FileHandle(forReadingAtPath: OHPathForFile("stub.ts", type(of: self))!)
                handle?.seek(toFileOffset: UInt64(range.location))
                let segmentData = handle?.readData(ofLength: range.length)
                return OHHTTPStubsResponse(data: segmentData!, statusCode:206, headers:["Content-Type": "video/MP2T"])
            }
            // Stubbing playlists
            let stubPath = OHPathForFile(request.url!.lastPathComponent, type(of: self))
            return fixture(filePath: stubPath!, headers: ["Content-Type":"application/x-mpegURL"])
        }
        
        expect { () -> Void in
            let parser = try HLSParser(url: URL(string: "https://stub.com/hls_index.m3u8")!)
            let trackData = parser.tracks[0].data!
            
            waitUntil { done in
                var calledCount = 0
                var lastProgress: Double = 0
                self.downloader.progressHandler = { progress in
                    expect(progress) != lastProgress
                    expect(progress) >= 0
                    expect(progress) <= 1
                    calledCount += 1
                    lastProgress = progress
                }
                self.downloader.downloadSegments(of: trackData) { response in
                    expect { () -> Void in
                        _ = try response()
                    }.notTo(throwError())
                    expect(calledCount) == 23
                    expect(lastProgress) == 1
                    done()
                }
            }
        }.notTo(throwError())
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
