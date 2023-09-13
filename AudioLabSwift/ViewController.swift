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
    
    @IBOutlet weak var volumeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Why this way?
        // There are easier ways to play a song, but this version give so much control over the audio samples, which is what we want for this class!
       
    }
    
    

    @IBAction func play(_ sender: UIButton) {
        
        // just start up the audio model here
        audio.startProcesingAudioFileForPlayback()
        audio.togglePlaying()
        
    }
    
    
    @IBAction func volumeChanged(_ sender: UISlider) {
        // set the volumen using the audio model, this controls the output block
        audio.setVolume(val: sender.value)
        // let the user know what the volume is!
        volumeLabel.text = String(format: "Volume: %.1f", sender.value )
    }
    
}

