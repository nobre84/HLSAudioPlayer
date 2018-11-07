//
//  String+Slicing.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 26/10/18.
//

extension String {
    
    func slice(from: String, to: String? = nil) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            if let to = to {
                return (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                    String(self[substringFrom..<substringTo])
                }
            }
            else {
                return String(self[substringFrom...])
            }
        }
    }
    
}
