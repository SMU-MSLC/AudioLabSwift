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

    //MARK: 1. The instantiaiton of the Audio Model
    let audio = AudioModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // just start up the audio model here
        audio.startMicrophoneProcessing()

        // start doing whatever the audio model is supposed to do
        audio.play()
        
       //TODO: LOOK AT THE PLIST FOR RECORDING PERMISSIONS
    }
    
    

}

