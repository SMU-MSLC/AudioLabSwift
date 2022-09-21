//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal



class ViewController: UIViewController {

    
    let audio = AudioModel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
    }
    
    

    @IBAction func play(_ sender: UIButton) {
        
        // just start up the audio model here
        audio.startProcesingAudioFileForPlayback()
        audio.togglePlaying()
    }
    
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        audio.setVolume(val: sender.value)
    }
    
}

