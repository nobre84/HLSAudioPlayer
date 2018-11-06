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

    @IBOutlet weak var audioPlayer: HLSAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        audioPlayer.url = URL(string: "http://pubcache1.arkiva.de/test/hls_index.m3u8")

    }

}

