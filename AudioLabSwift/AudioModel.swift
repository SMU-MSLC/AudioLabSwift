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
    lazy var samplingRate:Int = {
        return Int(self.audioManager!.samplingRate)
    }()
    
    var sineFrequency1:Float = 300.0
    var sineFrequency2:Float = 650.0
    var sineFrequency3:Float = 1000.0
    
    private var phase1:Float = 0.0
    private var phase2:Float = 0.0
    private var phase3:Float = 0.0
    private var phaseIncrement1:Float = 0.0
    private var phaseIncrement2:Float = 0.0
    private var phaseIncrement3:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    var pulsing:Bool = false
    private var pulseValue:Int = 0
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager,
            let fileReader = self.fileReader{
            manager.inputBlock = self.handleMicrophone
            manager.outputBlock = self.handleSpeakerQueryWithSinusoids
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
            
            Timer.scheduledTimer(withTimeInterval: 1.0/5.0, repeats: true) { _ in
                // set to opposite
                self.pulseValue += 1
                if self.pulseValue > 5{
                    self.pulseValue = 0
                }
            }
            
            fileReader.play()
            
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    func stop(){
        if let manager = self.audioManager{
            manager.pause()
            manager.inputBlock = nil
            manager.outputBlock = nil
        }
        
        if let file = self.fileReader{
            file.pause()
            file.stop()
        }
        
        if let buffer = self.inputBuffer{
            buffer.clear() // just makes zeros
        }
        inputBuffer = nil
        fftHelper = nil
        fileReader = nil
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
    
    private lazy var fileReader:AudioFileReader? = {
            // find song in the main Bundle
            if let url = Bundle.main.url(forResource: "satisfaction", withExtension: "mp3"){
                // if we could find the url for the song in main bundle, setup file reader
                // the file reader is doing a lot here becasue its a decoder
                // so when it decodes the compressed mp3, it needs to know how many samples
                // the speaker is expecting and how many output channels the speaker has (mono, left/right, surround, etc.)
                var tmpFileReader:AudioFileReader? = AudioFileReader.init(audioFileURL: url,
                                                       samplingRate: Float(audioManager!.samplingRate),
                                                       numChannels: audioManager!.numOutputChannels)
                
                tmpFileReader!.currentTime = 0.0 // start from time zero!
                
                return tmpFileReader
            }else{
                print("Could not initialize audio input file")
                return nil
            }
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
    
    private func handleSpeakerQueryWithSinusoids(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
            if let arrayData = data, let manager = self.audioManager{
                
                var addFreq:Float = 0
                var mult:Float = 1.0
                if pulsing && pulseValue==1{
                    addFreq = 1000.0
                }else if pulsing && pulseValue > 1{
                    mult = 0.0
                }
                
                if let file = self.fileReader{
                    // get samples from audio file, pass array by reference
                    file.retrieveFreshAudio(arrayData,
                                numFrames: numFrames,
                                numChannels: numChannels)
                    
                    // adjust volume of audio file output
                    var volume:Float = mult*0.15 // zero out song also, if needed
                    vDSP_vsmul(arrayData, 1, &(volume), arrayData, 1, vDSP_Length(numFrames*numChannels))
                                    
                }
                
                phaseIncrement1 = Float(2*Double.pi*Double(sineFrequency1+addFreq)/manager.samplingRate)
                phaseIncrement2 = Float(2*Double.pi*Double(sineFrequency2+addFreq)/manager.samplingRate)
                phaseIncrement3 = Float(2*Double.pi*Double(sineFrequency3+addFreq)/manager.samplingRate)
                
                
                var i = 0
                let chan = Int(numChannels)
                let frame = Int(numFrames)
                if chan==1{
                    while i<frame{
                        arrayData[i] += (0.9*sin(phase1)+0.4*sin(phase2)+0.1*sin(phase3))*mult
                        phase1 += phaseIncrement1
                        phase2 += phaseIncrement2
                        phase3 += phaseIncrement3
                        if (phase1 >= sineWaveRepeatMax) { phase1 -= sineWaveRepeatMax }
                        if (phase2 >= sineWaveRepeatMax) { phase2 -= sineWaveRepeatMax }
                        if (phase3 >= sineWaveRepeatMax) { phase3 -= sineWaveRepeatMax }
                        i+=1
                    }
                }else if chan==2{
                    let len = frame*chan
                    while i<len{
                        arrayData[i] += (0.9*sin(phase1)+0.4*sin(phase2)+0.1*sin(phase3))*mult
                        arrayData[i+1] = arrayData[i]
                        phase1 += phaseIncrement1
                        phase2 += phaseIncrement2
                        phase3 += phaseIncrement3
                        if (phase1 >= sineWaveRepeatMax) { phase1 -= sineWaveRepeatMax }
                        if (phase2 >= sineWaveRepeatMax) { phase2 -= sineWaveRepeatMax }
                        if (phase3 >= sineWaveRepeatMax) { phase3 -= sineWaveRepeatMax }
                        i+=2
                    }
                }
                
            }
        }
    
    
}
