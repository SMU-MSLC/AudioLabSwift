//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal


let AUDIO_BUFFER_SIZE = 1024*4



class ViewController: UIViewController {

    @IBOutlet weak var ToneOne: UILabel!
    @IBOutlet weak var ToneTwo: UILabel!
    
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add in graphs for display
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
        
        graph?.addGraph(withName: "time",
            shouldNormalize: false,
            numPointsInGraph: AUDIO_BUFFER_SIZE)
        

        
        // just start up the audio model here
        audio.startMicrophoneProcessing(withFps: 10)
        //audio.startProcesingAudioFileForPlayback()
        audio.startProcessingSinewaveForPlayback(withFreq: 200)
        //audio.startProcessingSinewaveForPlayback(withFreq: 651.0)
        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.05, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)
        // run the loop for updating the frequency of the two loudest tones
        Timer.scheduledTimer(timeInterval: 1, target: self,
            selector: #selector(self.updateFreq),
            userInfo: nil,
            repeats: true)
        
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        audio.pause()
    }
      
    
    
    
    @objc
    func updateGraph(){
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
        
    }
    
    @objc
    func updateFreq(){
        ToneOne.text = String(self.audio.twoFreq[0])
        ToneTwo.text = String(self.audio.twoFreq[1])
    }
    

}

