//
//  Resources.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 06/11/18.
//

import UIKit

class Resources {
    static var iconPlay: UIImage {
        return Resources.bundledImage(named: "icon_play")
    }
    static var iconPause: UIImage {
        return Resources.bundledImage(named: "icon_pause")
    }
    static var iconMask: UIImage {
        return Resources.bundledImage(named: "icon_play")
    }
    
    private static func bundledImage(named name: String) -> UIImage {
        return UIImage(named: name, in: Bundle(for: self), compatibleWith: nil)!
    }
}
