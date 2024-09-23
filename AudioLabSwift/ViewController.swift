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
    
    // setup audio model, tell it how large to make a buffer
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    
    // setup a view to show the different graphs
    // this is like the canvas we will use to draw!
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add in a graph for displaying the audio
        if let graph = self.graph {
            // create a graph called "time" that we can update
            graph.addGraph(withName: "time",
                           numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            // make some nice vertical grids on the graph
            graph.makeGrids()
        }
        
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing() // setup for microphone
        audio.play() // and begin!
        
        // run the loop for updating the graph peridocially
        // 0.05 is about 20FPS update
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraph()
        }
       
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateGraph(){
        // display the audio data
        if let graph = self.graph {
            // provide some fresh samples from model for graphing
            graph.updateGraph(
                data: self.audio.timeData, // graph the data
                forKey: "time" // for this graph key (we only have one)
            )
        }
        
    }
    
    

}

