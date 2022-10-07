//
//  AnalyzerModel.swift
//  AudioLabSwift
//
//  Created by Wyatt Saltzman on 10/5/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import Foundation
import Metal

class AnalyzerModel {
//    let AUDIO_BUFFER_SIZE = 1024 * 4
//    let audio = AudioModel(buffer_size: 1024 * 4)
//
//    lazy var maxFreqs:[Float] = {
//        return Array.init(repeating: 0.0, count: 2);
//    }()
//
//    lazy var maxFreqsi:[Int] = {
//        return Array.init(repeating: 0, count: 2);
//    }()
//
//    var graph:MetalGraph?
    
    private var AUDIO_BUFFER_SIZE:Int
    private var audio:AudioModel
    private var graph:MetalGraph?
    
    init(viewGraph: MetalGraph?) {
        AUDIO_BUFFER_SIZE = 1024 * 4
        audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
        graph = viewGraph
    }
    
    func start() {
        let serialQueue = DispatchQueue(label: "serial")
        serialQueue.sync {
            audio.startMicrophoneProcessing(withFps: 10)
            audio.play()
            
            Timer.scheduledTimer(timeInterval: 0.05, target: self,
                selector: #selector(self.updateGraph),
                userInfo: nil,
                repeats: true)
        }
    }
//
    @objc
    func getMaxes() -> ([Float]) {
        return self.audio.maxFreqs
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
}


