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
    var motionStat:Int //to reflect the current motion
    var intervalFreq:Float //Hz every index
    var timeData:[Float]
    var fftData:[Float]
    var twoFreq:[Float]
    

    
    
    // MARK: Public Methods
    init(buffer_size:Int) {
        
        BUFFER_SIZE = buffer_size
        intervalFreq = 40000/Float(BUFFER_SIZE)
        // anything not lazily instatntiated should be allocated here
        timeData = Array.init(repeating: 0.0, count: BUFFER_SIZE)
        fftData = Array.init(repeating: 0.0, count: BUFFER_SIZE/2)
        twoFreq = Array.init(repeating:0.0, count:2) //to record the two loudest tones
        
        motionStat = 0 
    }
    
    // public function for starting processing of microphone data
    func startMicrophoneProcessing(withFps:Double){
        self.audioManager?.inputBlock = self.handleMicrophone
        
        // repeat this fps times per second using the timer class
        Timer.scheduledTimer(timeInterval: 1.0/withFps, target: self,
                            selector: #selector(self.runEveryInterval),
                            userInfo: nil,
                            repeats: true)
        
    }
    
    // public function for playing from a file reader file
    func startProcesingAudioFileForPlayback(){
        self.audioManager?.outputBlock = self.handleSpeakerQueryWithAudioFile
        self.fileReader?.play()
    }
    
    func startProcessingSinewaveForPlayback(withFreq:Float=330.0){
        sineFrequency = withFreq
        // Two examples are given that use either objective c or that use swift
        //   the swift code for loop is slightly slower thatn doing this in c,
        //   but the implementations are very similar
        //self.audioManager?.outputBlock = self.handleSpeakerQueryWithSinusoid // swift for loop
        self.audioManager?.setOutputBlockToPlaySineWave(sineFrequency) // c for loop
    }
    
    
    // public function for playing from a saved audio
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        self.audioManager?.play()
        
    }
    
    // call this when you want to pause the audio 
    func pause(){
        self.audioManager?.pause()
    }
    
    // call this when you want to end/reset the audio
    func tearDown(){
        self.audioManager?.teardownAudio()
    }
    
    // Here is an example function for getting the maximum frequency
    func getMaxFrequencyMagnitude() -> (Float,Float){
        // this is the slow way of getting the maximum...
        // you might look into the Accelerate framework to make things more efficient
        
        var max: Float = .nan
        var maxi: vDSP_Length = 0
        vDSP_maxvi(fftData, 1, &max, &maxi, vDSP_Length(fftData.count))
        let frequency = Float(maxi) / Float(BUFFER_SIZE) * Float(self.audioManager!.samplingRate)
        print(frequency)
        return (max,frequency)
    }
    // for sliding max windows, you might be interested in the following: vDSP_vswmax
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    private lazy var fftHelper:FFTHelper? = {
        return FFTHelper.init(fftSize: Int32(BUFFER_SIZE))
    }()
    
    private lazy var outputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numOutputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    private lazy var inputBuffer:CircularBuffer? = {
        return CircularBuffer.init(numChannels: Int64(self.audioManager!.numInputChannels),
                                   andBufferSize: Int64(BUFFER_SIZE))
    }()
    
    //==========================================
    // MARK: Private Methods
    private lazy var fileReader:AudioFileReader? = {
        
        if let url = Bundle.main.url(forResource: "satisfaction", withExtension: "mp3"){
            var tmpFileReader:AudioFileReader? = AudioFileReader.init(audioFileURL: url,
                                                   samplingRate: Float(audioManager!.samplingRate),
                                                   numChannels: audioManager!.numOutputChannels)
            
            tmpFileReader!.currentTime = 0.0
            print("Audio file succesfully loaded for \(url)")
            return tmpFileReader
        }else{
            print("Could not initialize audio input file")
            return nil
        }
    }()
    
    //==========================================
    // MARK: Model Callback Methods
    @objc
    private func runEveryInterval(){
        if inputBuffer != nil {
            // copy data to swift array
            self.inputBuffer!.fetchFreshData(&timeData, withNumSamples: Int64(BUFFER_SIZE))
            
            // now take FFT and display it
            fftHelper!.performForwardFFT(withData: &timeData,
                                         andCopydBMagnitudeToBuffer: &fftData)
            
            let max_freq = getMaxFrequencyMagnitude().1
            intervalFreq = max_freq/Float(BUFFER_SIZE/2)
            
            localPeakFinding(windowSize: 5) //before knowing what the frequency is, i have put the default window size to 50, and it should vary based on the total frequency there is. Besides that, the output/result of this function are two Integers representing the Indices of the two LOUDEST tones located on the FFT's frequency axis
            
        }
    }
    
    // local peak finding
    private func localPeakFinding (windowSize:Int=50){
        
        let windowCount = BUFFER_SIZE/2 - windowSize  //calculate how many times the calculation will happen
        var output = [(Int, Float)]()
        
        for i in 0...windowCount-1 {//for this many iterations to find the local max
            
            var c: Float = .nan
            var a = [Float](repeating: 0.0, count: windowSize)
            var index: vDSP_Length = 0
            for j in 0...windowSize-1{//find the max in the range of (windowSize) amount
                a[j] = fftData[i+j]
            }
            vDSP_maxvi(a, 1, &c, &index, vDSP_Length(windowSize))
            if (index == windowSize/2){//if index sits in the middle
                //print("found local max at")
                let currIndex = Int(index) + i //find the current index
                output.append((currIndex, fftData[currIndex]))
                //print(currIndex)
            }
        }
        let sortedOutput = output.sorted { (lhs, rhs) in
            return lhs.1 > rhs.1
        }
        if (sortedOutput.count > 1){
            //using the current window size, display the position of top two tones in the FFT buffer
            //calculate the frequency based on the max
            twoFreq[0] = Float(sortedOutput[0].0) * intervalFreq
            twoFreq[1] = Float(sortedOutput[1].0) * intervalFreq //update the array passing as an output
        }
    }
    
    func calculateMotion(currFreq:Float) -> (Float){
        if (fftData[0] == 0.1){ //todo: currently intentionally disabled due to a bug that line 198 would have a buffer overflow ( sampleSize exceeds bufferSize)
            let freqIndex = currFreq/intervalFreq //calculate the location of the interval in buffer
            let sampleSize = Int(freqIndex/250) //calculate the sample size will help finding the average value on the left & right side of the current frequency
            
            //print("sampleSize is " + String(sampleSize) + " freqIndex is " + String(freqIndex))
            //to figure out if object is close to the microphone, will need to check the left&right of freq 20k on the FFT
            var lhsData = Array.init(repeating: Float(0), count: sampleSize+1)
            var rhsData = Array.init(repeating: Float(0), count: sampleSize+1)
            for i in 0...sampleSize{
                lhsData[i] = fftData[Int(freqIndex) - sampleSize + i]
                rhsData[i] = fftData[Int(freqIndex) + i]
            }
            let stride = vDSP_Stride(1)
            var lhsMean: Float = .nan
            var rhsMean: Float = .nan
            //taking average of the two sets of data
            vDSP_meanv(lhsData, stride, &lhsMean, vDSP_Length(lhsData.count))
            vDSP_meanv(rhsData, stride, &rhsMean, vDSP_Length(rhsData.count))
            return rhsMean - lhsMean
        }
        return 0
    }
    
    
    //looking for the changes around 20kHz to detect if an object is moving
   
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    private func handleMicrophone (data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32) {
        // copy samples from the microphone into circular buffer
        self.inputBuffer?.addNewFloatData(data, withNumSamples: Int64(numFrames))
    }
    
    private func handleSpeakerQueryWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        if let file = self.fileReader{
            
            // read from file, loaidng into data (a float pointer)
            file.retrieveFreshAudio(data,
                                    numFrames: numFrames,
                                    numChannels: numChannels)
            
            // set samples to output speaker buffer
            self.outputBuffer?.addNewFloatData(data,
                                         withNumSamples: Int64(numFrames))
        }
    }
    
    //    _     _     _     _     _     _     _     _     _     _
    //   / \   / \   / \   / \   / \   / \   / \   / \   / \   /
    //  /   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/   \_/
    var sineFrequency:Float = 0.0 { // frequency in Hz (changeable by user)
        didSet{
            // if using swift for generating the sine wave: when changed, we need to update our increment
            //phaseIncrement = Float(2*Double.pi*sineFrequency/audioManager!.samplingRate)
            
            // if using objective c: this changes the frequency in the novocain block
            self.audioManager?.sineFrequency = sineFrequency
        }
    }
    private var phase:Float = 0.0
    private var phaseIncrement:Float = 0.0
    private var sineWaveRepeatMax:Float = Float(2*Double.pi)
    
    private func handleSpeakerQueryWithSinusoid(data:Optional<UnsafeMutablePointer<Float>>, numFrames:UInt32, numChannels: UInt32){
        // while pretty fast, this loop is still not quite as fast as
        // writing the code in c, so I placed a function in Novocaine to do it for you
        // use setOutputBlockToPlaySineWave() in Novocaine
        if let arrayData = data{
            var i = 0
            while i<numFrames{
                arrayData[i] = sin(phase)
                phase += phaseIncrement
                if (phase >= sineWaveRepeatMax) { phase -= sineWaveRepeatMax }
                i+=1
            }
        }
    }
}
