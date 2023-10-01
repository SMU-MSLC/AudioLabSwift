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
    
    // These Properties Are For Interfacing With Novocaine, FFTHelper, Etc.
    // User Can Access These Arrays Whenever Necessary And Plot Them
    private var BUFFER_SIZE:Int
    var timeData:[Float]
    var fftData:[Float]
    var binnedFftData:[Float]
    
    // MARK: Public Methods
    
    // Anything Not Lazily Instantiated Should Be Allocated Here
    init(buffer_size:Int) {
        BUFFER_SIZE = buffer_size
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        binnedFftData = Array.init(repeating: 0.0, count: 20)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double) {
        // setup the microphone to copy to circualr buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            
            // FIXME NEW TIMER https://www.swiftanytime.com/blog/ultimate-guide-on-timer-in-swift
            
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
//                self.copyBins(numBins: 20)
            }
            
        }
    }
    
    // Public Function For Starting Processing For Both Microphone, Speaker Data
    func startDualProcessing(withFps:Double, withFreq:Float = 17500.0) {
        
        // Setup Microphone, Speaker For Copy To Circular Buffer
        if let manager = self.audioManager{
            manager.inputBlock = self.handleMicrophone
            manager.outputBlock = self.handleSpeakerQueryWithSinusoids
            
            // repeat this fps times per second using the timer class
            //   every time this is called, we update the arrays "timeData" and "fftData"
            
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
//                self.copyBins(numBins: 20)
            }
            
            // Function for playing the sine wave with specific
            sineFrequency = withFreq
                // Two examples are given that use either objective c or that use swift
                //   the swift code for loop is slightly slower thatn doing this in c,
                //   but the implementations are very similar
                //self.audioManager?.outputBlock = self.handleSpeakerQueryWithSinusoid // swift for loop
            self.audioManager?.setOutputBlockToPlaySineWave(sineFrequency)
            
            
//            Timer.scheduledTimer(withTimeInterval: 1.0/5.0, repeats: true) { _ in
//                // set to opposite
//                self.pulseValue += 1
//                if self.pulseValue > 5{
//                    self.pulseValue = 0
//                }
//            }
        }
    }
    
    // Set the inaudible tone frequency
    func setToneFrequency(_ frequency: Float) {
        sineFrequency = frequency
    }
    
    func startFileProcessing(withFps:Double) {
        if let manager = self.audioManager {
//            manager.inputBlock = self.handleSpeakerQueryWithAudioFile
            manager.outputBlock = self.handleSpeakerQueryWithAudioFile
            Timer.scheduledTimer(withTimeInterval: 1.0/withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
        }
    }
    
    func copyBins(numBins:Int) {
        let stepSize = Int((BUFFER_SIZE/2) / numBins)
        binnedFftData = Array.init(repeating: 0.0, count: 20)
        
        for i in 0...numBins - 1{
            
            
//            fftDataLoc = &fftData
//            print("Iteration\(i) | fftdata len: \(fftData.count) | stepSize: \(stepSize) | i * stepSize: \(i * stepSize) |")
            vDSP_maxv(&fftData + i * stepSize, 1, &binnedFftData + i, vDSP_Length(stepSize))
        }
//        print(self.binnedFftData)
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
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    func pause(){
        audioManager?.pause()
    }
    
    //==========================================
    // MARK: Private Methods
    private lazy var fileReader:AudioFileReader? = {
        if let url = Bundle.main.url(forResource: "satisfaction", withExtension: "mp3") {
            var tmpFileReader:AudioFileReader? = AudioFileReader.init(audioFileURL: url, samplingRate: Float(audioManager!.samplingRate), numChannels: audioManager!.numOutputChannels)
            tmpFileReader?.currentTime = 0.0
            print("Audio File successfully loaded: \(url)")
            return tmpFileReader
        } else {
            print("Could not fetch File")
            return nil
        }

    }()
    
    //==========================================
    // MARK: Model Callback Methods
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy time data to swift array
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            // at this point, we have saved the data to the arrays:
            //   timeData: the raw audio samples
            //   fftData:  the FFT of those same samples
            // the user can now use these variables however they like
            self.copyBins(numBins: 20)
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
    private func handleSpeakerQueryWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>,numFrames:UInt32,numChannels:UInt32) {
        if let file = self.fileReader {
            file.retrieveFreshAudio(data, numFrames: numFrames, numChannels: numChannels)
            var vol = Float(3.0)
            vDSP_vsmul(data!, 1, &vol, data!, 1, vDSP_Length(numFrames * numChannels))
            self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
            
        } else {
            print("Could not fetch file reader")
        }
    }
    private func handleFileInput(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    //    _     _     _     _     _     _     _     _     _     _
    //   / \   / \   / \   / \   / \   / \   / \   / \   / \   /
    //  /   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            
        // if using swift for generating the sine wave: when changed, we need to update our increment
//                    phaseIncrement = Float(2*Double.pi*Double(sineFrequency)/manager.samplingRate)
            self.audioManager?.sineFrequency = sineFrequency
        }
    }
    
    // SWIFT SINE WAVE
    // everything below here is for the swift implementation
    // this can be deleted when using the objective c implementation
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    // Calculate and return the maximum decibel value from FFT data
    func getMaxDecibels() -> Float {
        // Use Accelerate framework to calculate the maximum value in decibels
        var maxDecibels: Float = -Float.greatestFiniteMagnitude
        vDSP_maxv(fftData, 1, &maxDecibels, vDSP_Length(fftData.count))
        
        // Convert from linear scale to decibels
        let maxDecibelsInLinearScale = 20 * log10f(maxDecibels)
        return maxDecibelsInLinearScale
    }
    
    private func handleSpeakerQueryWithSinusoids(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        // while pretty fast, this loop is still not quite as fast as
        // writing the code in c, so I placed a function in Novocaine to do it for you
        // use setOutputBlockToPlaySineWave() in Novocaine
        // EDIT: fixed in 2023
        if let arrayData = data{
            var i = 0
            let chan = Int(numChannels)
            let frame = Int(numFrames)
            if chan==1{
                while i<frame{
                    arrayData[i] = sin(phase)
                    phase += phaseIncrement
                    if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                    i+=1
                }
            }else if chan==2{
                let len = frame*chan
                while i<len{
                    arrayData[i] = sin(phase)
                    arrayData[i+1] = arrayData[i]
                    phase += phaseIncrement
                    if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                    i+=2
                }
            }
        }
    }
}
