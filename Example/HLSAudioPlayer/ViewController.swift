//
//  ViewController.swift
//  HLSAudioPlayer
//
//  Created by Rafael Nobre on 10/24/2018.
//  Copyright (c) 2018 Rafael Nobre. All rights reserved.
//

import UIKit
import HLSAudioPlayer

class ViewController: UIViewController {

    @IBOutlet private weak var audioPlayer: HLSAudioPlayer!
    @IBOutlet private weak var centerXConstraint: NSLayoutConstraint!
    @IBOutlet private weak var centerYConstraint: NSLayoutConstraint!
    private lazy var gestureHelper: HLSGestureHelper = {
        return HLSGestureHelper(targetView: audioPlayer, centerXConstraint: centerXConstraint, centerYConstraint: centerYConstraint)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioPlayer.url = URL(string: "http://pubcache1.arkiva.de/test/hls_index.m3u8")

        gestureHelper.isDraggingEnabled = true
        gestureHelper.isSnappingEnabled = true
    }

}

