//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import Foundation
import Accelerate

class AudioModel {
    // this is a minimal example of the Audio Model,
    // here we only setup the audio to read from
    
    // MARK: Properties
    // no public properties to interact with yet

    private var BUFFER_SIZE:Int

    
    // MARK: Public Methods
    init() {
        BUFFER_SIZE = 0 // not setting up any buffers here

    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(){
        if let manager = self.audioManager{
            // this sets the input block whenever the manager is played
            manager.inputBlock = self.handleMicrophone
        }
    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager() // alloc and init Novocaine
    }()
    
    
    //==========================================
    // MARK: Private Methods
   
    
    //==========================================
    // MARK: Model Callback Methods
    
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>,
                                   numFrames:UInt32,
                                   numChannels: UInt32) {
        if let arrayData = data{
            //---------------------------------------
            // just print out the first audio sample
            print(arrayData[0])
            // 🎙️ -> 📉 grab first element in the buffer
            
            //---------------------------------------
            // bonus: vDSP example (will cover in next lecture)
            // here is an example using iOS accelerate to quickly handle the array
            // Let's use the accelerate framework
//            var max:Float = 0
//            vDSP_maxv(arrayData, 1, &max, vDSP_Length(numFrames))
//            print(max)
            
            // 🎙️ -> 📉 get max element in the buffer
        }
        
    }
    
    
}
