//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal
import Accelerate




class ViewController: UIViewController {

    // setup some constants we will use
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add in a graph for displaying the audio
        if let graph = self.graph {
            graph.addGraph(withName: "time",
                           numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            graph.makeGrids()
        }
        
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing()

        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
       
    }
    
    // periodically, update the graph with refreshed FFT Data
    @objc
    func updateGraph(){
        // periodically, display the audio data
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
    }
    
    

}

