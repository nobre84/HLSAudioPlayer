//
//  HLSSegmentDownloader.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit
import RNConcurrentBlockOperation

public class HLSSegmentDownloader {

    private var writers: [URL: FileHandle] = [:]
    
    public init() {
    }
    
    public func downloadSegments(of track: HLSMediaTrackData, completion: @escaping (@escaping () throws -> [URL]) -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        var operations = [Operation]()
        
        do {
            try createSegmentFiles(of: track)
        }
        catch {
            completion { throw error }
        }
        
        track.segments.forEach { segment in
            operations.append(RNConcurrentBlockOperation() { finished in
                var urlRequest = URLRequest(url: segment.uri)
                if let byteRange = segment.byteRange {
                    urlRequest.addValue(self.createRangeHeader(with: byteRange), forHTTPHeaderField: "Range")
                }

                URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
                    if let error = error {
                        completion { throw error }
                        finished?(nil)
                        return
                    }
                    if let data = data {
                        do {
                            let writerUrl = try self.localUri(for: segment.uri)
                            let writer = try self.writer(for: writerUrl)
                            try self.write(data, at: segment.byteRange?.location, with: writer, url: writerUrl)
                            finished?(nil)
                        }
                        catch {
                            completion { throw error }
                            finished?(nil)
                        }
                    }
                }).resume()
            })
        }
        
        let joinOperation = RNConcurrentBlockOperation() { finished in
            completion { return Array(self.writers.keys) }
            finished?(nil)
        }
        
        operations.forEach {
            joinOperation?.addDependency($0)
            queue.addOperation($0)
        }
        
        queue.addOperation(joinOperation!)
    }
    
    func createRangeHeader(with range: NSRange) -> String {
        return "bytes=\(range.location)-\(range.location + range.length)"
    }
    
    func createSegmentFiles(of track: HLSMediaTrackData) throws {
        var fileMap = [URL: Int]()
        for segment in track.segments {
            let url = try self.localUri(for: segment.uri)
            let segmentSize = segment.byteRange?.length ?? 0
            fileMap[url] = (fileMap[url] ?? 0) + segmentSize
        }
        let now = Date()
        for (url, totalSize) in fileMap {
            print("Writing \(totalSize) bytes")
            try Data().write(to: url)
        }
        print(now.timeIntervalSinceNow * -1000)
    }
    
    private func localUri(for segmentUri: URL) throws -> URL {
        let localUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(segmentUri.lastPathComponent)
        return localUrl
    }
    
    private func writer(for writerUri: URL) throws -> FileHandle {
        guard let writer = writers[writerUri] else {
            let writer = try FileHandle(forWritingTo: writerUri)
            writers[writerUri] = writer
            return writer
        }
        return writer
    }
    
    private func write(_ data: Data, at offset: Int?, with writer: FileHandle, url: URL) throws {
        let offset = UInt64(offset ?? 0)
        if !FileManager.default.fileExists(atPath: url.path) {
            try Data().write(to: url)
        }
        writer.seek(toFileOffset: offset)
        writer.write(data)
    }
    
}

private struct FileInfo {
    let uri: URL
    var totalSize: Int
}
