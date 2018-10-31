//
//  Stubs.swift
//  HLSAudioPlayer_Example
//
//  Created by Rafael Nobre on 24/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

class Stubs {
    
    static func data(from resource: String, `extension`: String) -> Data {
        guard let url = Bundle.test.url(forResource: resource, withExtension: `extension`),
            let content = try? Data(contentsOf: url) else {
                fatalError("Failed fetching data Stub for resource \(resource) with extension \(`extension`)")
        }
        return content
    }
        
    static func from(_ resource: String, `extension`: String = "m3u8") -> String {
        let content = self.data(from: resource, extension: `extension`)
        guard let string = String(bytes: content, encoding: .utf8) else {
            fatalError("Failed fetching string Stub for resource \(resource) with extension \(`extension`)")
        }
        return string
    }
    
    static func url(of resource: String, `extension`: String = "m3u8") -> URL {
        guard let url = Bundle.test.url(forResource: resource, withExtension: `extension`) else {
                fatalError("Failed fetching URL for resource \(resource) with extension \(`extension`)")
        }
        return url
    }
}
