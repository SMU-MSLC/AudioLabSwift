//
//  AudioModel.swift
//  AudioLabSwift
//
//  Created by Eric Larson
//  Copyright © 2020 Eric Larson. All rights reserved.
//
//  Lab Two: Audio Filtering, FFT, Doppler Shifts
//  Trevor Dohm, Will Landin, Ray Irani, Alex Shockley
//

// Import Statements
import Foundation
import Accelerate

class AudioModel {
    
    // ================
    // MARK: Properties
    // ================
    
    // These Properties Are For Interfacing With Novocaine, FFTHelper, Etc.
    // User Can Access These Arrays Whenever Necessary And Plot Them
    private var BUFFER_SIZE:Int
    var timeData:[Float]
    var fftData:[Float]
    var frozenFftData:[Float]
    var frozenTimeData:[Float]
    
    private var weights:[Float]
    private var weightsSum:Float
    private var prevMaxTimeData:[Float] = []
    // ====================
    // MARK: Public Methods
    // ====================
    private var lookback:Int
    private func weightFunc(x:Float,numVals:Int) -> Float{
//        return Float(((-1 * x) + numVals)/Float(numVals))
        return ((-1 * x) + Float(numVals + 1)) / Float(numVals + 1)
    }
    // Anything Not Lazily Instantiated Should Be Allocated Here
    init(buffer_size:Int,lookback:Int=10) {
        BUFFER_SIZE = buffer_size
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE / 2)
        weights = []
        weightsSum = 0
        frozenFftData = []
        frozenTimeData = []
        self.lookback = lookback
        for i in 1...lookback {
            let wt = weightFunc(x: Float(i),numVals: lookback)
            weights.append(wt)
            weightsSum += wt
        }
        
//        print(weights)
//        print("weights : \(weightsSum)")
//
//        print(weights,weightsSum)
    }

    ///Check if a sufficiently large sound was detected by the microphone (above a certain float threshold for average sin wave)
    public func isLoudSound(cutoff:Float) -> Bool {
        var maxTimeVal:Float = 0.0
        vDSP_maxv(timeData, 1, &maxTimeVal, vDSP_Length(timeData.count))
        var isTrue = false
        var weightedTimeVals:[Float] = prevMaxTimeData
        vDSP_vmul(prevMaxTimeData, 1, weights, 1, &weightedTimeVals, 1, vDSP_Length(prevMaxTimeData.count))
//        print(weightedTimeVals)
        let wtAvg = vDSP.sum(weightedTimeVals) / weightsSum
    
        let pctDiff = (maxTimeVal - wtAvg) / wtAvg
        
        print("wtAvg: \(wtAvg) | currMax: \(maxTimeVal) | pctDiff \(pctDiff)")
        
        if pctDiff > cutoff {
            isTrue = true
            self.frozenFftData = fftData
            self.frozenTimeData = timeData
        }
        prevMaxTimeData.insert(maxTimeVal, at: 0)
        if prevMaxTimeData.count > self.lookback {
            prevMaxTimeData.popLast()
        }
        
        return isTrue
    }
    
    // Public Function For Starting Processing Microphone Data
    func startMicrophoneProcessing(withFps:Double) {

        // Setup Microphone For Copy To Circular Buffer
        // Note: We Don't Use "?" Operator Here Since We
        // Don't Want Timer To Run If Microphone Not Handled
        if let manager = self.audioManager {
            manager.inputBlock = self.handleMicrophone
            
            // Repeat FPS Times / Second Using Timer Class
            Timer.scheduledTimer(withTimeInterval: 1.0 / withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
        }
    }
    
    // Public Function For Starting Processing For Both Microphone, Speaker Data
    func startDualProcessing(withFps:Double, withFreq:Float = 17500.0) {
        
        // Setup Microphone, Speaker For Copy To Circular Buffer
        // Note: See Above For "If Let" Reasoning, Discussion
        if let manager = self.audioManager {
            manager.inputBlock = self.handleMicrophone

            // Set Sinewave Frequency To Current Slider Value
            sineFrequency = withFreq
            
            // Use Novocaine Implementation (C) Rather Than Swift Implementation (Swift)
            // Similar Methods, But In Terms Of Speed, C > Swift
            // manager.outputBlock = self.handleSpeakerQueryWithSinusoids
            manager.setOutputBlockToPlaySineWave(sineFrequency)
            
            // Repeat FPS Times / Second Using Timer Class
            Timer.scheduledTimer(withTimeInterval: 1.0 / withFps, repeats: true) { _ in
                self.runEveryInterval()
            }
        }
    }
    
    // Set Inaudible Tone Frequency
    func setToneFrequency(_ frequency: Float) {
        sineFrequency = frequency
    }
    
    // Get Circular Buffer
    func retrieveInputBuffer() -> CircularBuffer? {
        return inputBuffer
    }
    
    // Start Handling Audio
    func play() {
        self.audioManager?.play()
    }
    
    // Stop Handling Audio
    func pause(){
        self.audioManager?.pause()
    }
    
    // ========================
    // MARK: Private Properties
    // ========================
    
    // Instantiate Novocaine AudioManager
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    // Instantiate FFTHelper
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    // Instantiate Input CircularBuffer (Input Buffer For AudioManager)
    // Can Create More With This Logic If Necessary
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    // ============================
    // MARK: Model Callback Methods
    // ============================
    
    // Call This Every FPS Times Per Second
    // See Timer That We Previously Created
    private func runEveryInterval() {
        if inputBuffer != nil {

            // Copy Time Data To Swift Array
            // timeData: Raw Audio Samples
            self.inputBuffer!.fetchFreshData(&timeData,
                                             withNumSamples: Int64(BUFFER_SIZE))
            
            // Copy FFT Data To Swift Array
            // fftData: FFT Of Those Same Samples
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            // FIXME Calculate Maximums Here!
            
        }
    }
    
    // =========================
    // MARK: Audiocard Callbacks
    // =========================
    
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
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
