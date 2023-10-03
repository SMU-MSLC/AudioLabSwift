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
        
        audio.startProcessingSinewaveForPlayback(withFreq: 1000)
        audio.play()
       
    }
    
    
    @IBOutlet weak var freqLabel: UILabel!
    @IBAction func changeFrequency(_ sender: UISlider) {
        self.audio.sineFrequency = sender.value
        freqLabel.text = "Frequency: \(sender.value)"
    }
    
    @IBOutlet weak var volLabel: UILabel!
    @IBAction func changeVolume(_ sender: UISlider) {
        self.audio.volume = sender.value
        volLabel.text = "Volume: \(sender.value)"
    }
}

