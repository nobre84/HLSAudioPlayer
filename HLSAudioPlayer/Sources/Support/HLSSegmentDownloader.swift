//
//  HLSSegmentDownloader.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit
import RNConcurrentBlockOperation

let HLSSegmentDownloaderCachesFolder = "HLSSegmentDownloaderCache"

public class HLSSegmentDownloader {

    public var progressHandler: ((_ percentDone: Double) -> Void)?
    
    private var writers: [URL: FileHandle] = [:]
    private var maxConcurrentDownloadCount: Int
    
    public init(maxConcurrentDownloadCount: Int = 2) {
        self.maxConcurrentDownloadCount = maxConcurrentDownloadCount
    }
    
    public func downloadSegments(of track: HLSMediaTrackData, completion: @escaping (@escaping () throws -> [URL]) -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = maxConcurrentDownloadCount
        
        var operations = [Operation]()
        var errors = [Error]()
        
        let totalSize = Double(track.segments.map { $0.byteRange?.length ?? 0 }.reduce(0, +))
        var totalDownloadedSize: Double = 0
        
        track.segments.forEach { segment in
            operations.append(RNConcurrentBlockOperation() { finished in
                var urlRequest = URLRequest(url: segment.uri)
                if let byteRange = segment.byteRange {
                    urlRequest.addValue(self.createRangeHeader(with: byteRange), forHTTPHeaderField: "Range")
                }

                URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
                    if let error = error {
                        errors.append(error)
                        finished?(nil)
                        return
                    }
                    if let data = data {
                        do {
                            let writerUrl = try self.localUri(for: segment.uri)
                            let writer = try self.writer(for: writerUrl)
                            try self.write(data, at: segment.byteRange?.location, with: writer, url: writerUrl)
                            finished?(nil)
                            let segmentSize = Double(segment.byteRange?.length ?? 0)
                            totalDownloadedSize += segmentSize
                            DispatchQueue.main.async {
                                self.progressHandler?(totalDownloadedSize / totalSize)
                            }
                        }
                        catch {
                            errors.append(error)
                            finished?(nil)
                        }
                    }
                }).resume()
            })
        }
        
        let joinOperation = RNConcurrentBlockOperation() { finished in
            if !errors.isEmpty {
                completion { throw HLSParserError.multipleErrors(errors) }
            }
            else {
                completion { return Array(self.writers.keys) }
            }
            finished?(nil)
        }
        
        operations.forEach {
            joinOperation?.addDependency($0)
            queue.addOperation($0)
        }
        
        queue.addOperation(joinOperation!)
    }
    
    public static func clearCaches() throws {
        let manager = FileManager.default
        let cachesDir = try manager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(HLSSegmentDownloaderCachesFolder, isDirectory: true)
        let files = try manager.contentsOfDirectory(at: cachesDir, includingPropertiesForKeys: nil)
        print("Clearing cache with \(files) files")
        for url in files {
            try manager.removeItem(at: url)
        }
    }
    
    func createRangeHeader(with range: NSRange) -> String {
        return "bytes=\(range.location)-\(range.location + range.length)"
    }
    
    private func localUri(for segmentUri: URL) throws -> URL {
        let manager = FileManager.default
        let cachesDir = try manager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(HLSSegmentDownloaderCachesFolder, isDirectory: true)
        try manager.createDirectory(atPath: cachesDir.path, withIntermediateDirectories: true, attributes: nil)
        
        return cachesDir.appendingPathComponent(segmentUri.lastPathComponent)
    }
    
    private func writer(for writerUri: URL) throws -> FileHandle {
        guard let writer = writers[writerUri] else {
            // FileHandle is unable to create the file itself, so we must create an empty one beforehand.
            if !FileManager.default.fileExists(atPath: writerUri.path) {
                try Data().write(to: writerUri)
            }
            let writer = try FileHandle(forWritingTo: writerUri)
            writers[writerUri] = writer
            return writer
        }
        return writer
    }
    
    private func write(_ data: Data, at offset: Int?, with writer: FileHandle, url: URL) throws {
        let offset = UInt64(offset ?? 0)
        writer.seek(toFileOffset: offset)
        writer.write(data)
    }
    
}
