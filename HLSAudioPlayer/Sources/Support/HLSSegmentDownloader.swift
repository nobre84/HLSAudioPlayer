//
//  HLSSegmentDownloader.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 24/10/18.
//

import UIKit

public class HLSSegmentDownloader {
    private let queue: OperationQueue = OperationQueue()
    private var writers: [URL: FileHandle] = [:]
    
    public init() {
    }
    
    public func downloadSegments(of track: HLSMediaTrackData, completion: @escaping (() throws -> [URL]) -> Void) {
        track.segments.forEach { segment in
            var urlRequest = URLRequest(url: segment.uri)
            if let byteRange = segment.byteRange {
                urlRequest.addValue("bytes=\(byteRange.location)-\(byteRange.length)", forHTTPHeaderField: "Range")
            }
            
            URLSession.shared.dataTask(with: urlRequest, completionHandler: { data, response, error in
                if let error = error {
                    return completion { throw error }
                }
                if let data = data {
                    do {
                        var writer = self.writers[segment.uri]
                        if writer == nil {
                            writer = try FileHandle(forUpdating: segment.uri)
                            self.writers[segment.uri] = writer
                        }
                        writer?.seek(toFileOffset: UInt64(segment.byteRange?.location ?? 0))
                        writer?.write(data)
                    }
                    catch {
                        print(error)
                        completion { throw error }
                    }
                }
            }).resume()
        }
    }
}
