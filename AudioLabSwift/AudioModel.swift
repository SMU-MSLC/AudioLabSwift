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
    
    // MARK: Properties
    private var BUFFER_SIZE:Int

    
    // MARK: Public Methods
    init() {
        BUFFER_SIZE = 0

    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(){
        self.audioManager?.inputBlock = self.handleMicrophone
    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        self.audioManager?.play()
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    
    //==========================================
    // MARK: Private Methods
   
    
    //==========================================
    // MARK: Model Callback Methods
    
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        if let arrayData = data{
            // just print out the first audio sample
            print(arrayData[0])
            
            // bonus: vDSP example
            //var max:Float = 0
            //vDSP_maxv(arrayData, 1, &max,vDSP_Length(numFrames))
            //print(max)
        }
        
    }
    
    
}
