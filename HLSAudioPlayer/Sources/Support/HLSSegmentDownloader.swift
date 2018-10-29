//
//  HLSSegmentDownloader.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit
import RNConcurrentBlockOperation

public class HLSSegmentDownloader {
    
    public init() {
    }
    
    public func downloadSegments(of track: HLSMediaTrackData, completion: @escaping (@escaping () throws -> [URL]) -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2
        
        var operations = [Operation]()
        
        var writers: [URL: FileHandle] = [:]
        
        track.segments.forEach { segment in
            operations.append(RNConcurrentBlockOperation() { operationFinished in
                var urlRequest = URLRequest(url: segment.uri)
                if let byteRange = segment.byteRange {
                    urlRequest.addValue(self.createRangeHeader(with: byteRange), forHTTPHeaderField: "Range")
                }
                
                URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
                    if let error = error {
                        completion { throw error }
                        operationFinished?(nil)
                        return
                    }
                    if let data = data {
                        do {
                            var writer = writers[segment.uri]
                            if writer == nil {
                                writer = try FileHandle(forWritingTo: segment.uri)
                                writers[segment.uri] = writer
                            }
                            writer?.seek(toFileOffset: UInt64(segment.byteRange?.location ?? 0))
                            writer?.write(data)
                            operationFinished?(nil)
                        }
                        catch {
                            print(error)
                            completion { throw error }
                            operationFinished?(nil)
                        }
                    }
                }).resume()
            })
        }
        
        let joinOperation = RNConcurrentBlockOperation() { finished in
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
    
    
}
