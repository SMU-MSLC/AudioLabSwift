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
    // thse properties are for interfaceing with the API
    // the user can access these arrays at any time and plot them if they like
    var timeData:[Float]
    var fftData:[Float]
    var ptsData:[Float]
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        ptsData = Array.init(repeating: 0.0, count: 20)
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
            
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    func pause(){
        if let manager = self.audioManager{
            manager.pause()
        }
    }
    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    
    //==========================================
    // MARK: Private Methods
    // NONE for this model
    
    //==========================================
    // MARK: Model Callback Methods
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData, // copied into this array
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData) // fft result is copied into fftData array
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            let a = BUFFER_SIZE/40
            
            for i in 0...19 {
                let b = i * a
                var max:Float = -1000.0
                for j in b...(b + a) {
                    if (fftData[j] > max) { max = fftData[j]}
                }
                ptsData[i] = max
            }
            
        }
    }
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    
}
