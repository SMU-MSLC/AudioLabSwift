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

let AUDIO_BUFFER_SIZE = 1024*4


class ViewController: UIViewController {

    // setup audio model
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add in a graph for displaying the audio
        graph?.addGraph(withName: "time",
            shouldNormalize: false,
            numPointsInGraph: AUDIO_BUFFER_SIZE)
        
        graph?.addGraph(withName: "sq_time",
        shouldNormalize: false,
        numPointsInGraph: AUDIO_BUFFER_SIZE)
        
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
        
        var timeData = self.audio.timeData
        
        vDSP_vsq(timeData, 1, &timeData, 1, vDSP_Length(timeData.count))
        
        self.graph?.updateGraph(
            data: timeData,
            forKey: "sq_time"
        )
        
    }
    
    

}

