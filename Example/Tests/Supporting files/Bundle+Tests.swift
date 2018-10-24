//
//  Bundle+Tests.swift
//  HLSAudioPlayer_Example
//
//  Created by Rafael Nobre on 24/10/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

extension Bundle {
    static var test: Bundle {
        return Bundle(for: BundleGrabber.self)
    }
}

fileprivate class BundleGrabber {}
