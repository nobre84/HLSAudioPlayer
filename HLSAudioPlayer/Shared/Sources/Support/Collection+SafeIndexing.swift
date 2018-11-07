//
//  Collection+SafeIndexing.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 26/10/18.
//

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
