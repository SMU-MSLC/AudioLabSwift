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
        BUFFER_SIZE = 0 // unused

    }
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        if let manager = self.audioManager{
            manager.play()
        }
    }
    
    
    func togglePlaying(){
        if let manager = self.audioManager, let reader=self.fileReader{
            if manager.playing{
                manager.pause() // pause audio processing
                reader.pause() // stop buffering the song file
            }else{
                manager.play() // start both again!
                reader.play()
            }
        }
    }
    
    func setVolume(val:Float){
        self.volume = val
    }
    
    // public function for playing from a file reader file
    func startProcesingAudioFileForPlayback(){
        // set the output block to read from and play the audio file
        if let manager = self.audioManager,
           let fileReader = self.fileReader{
            manager.outputBlock = self.handleSpeakerQueryWithAudioFile
            fileReader.play() // tell file Reader to start filling its buffer
        }
    }
    //MARK: File Reader object has three functions that we will use:
    //      init(), find the audio file and make sure we can see it
    //      play(), go to the file and start decoding samples
    //      retrieveFreshAudio(...), load new samples buffer by buffer into an array

    
    //==========================================
    // MARK: Private Properties
    
    private var volume:Float = 1.0 // internal storage for volume
    
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
    }()
    
    
    
    //==========================================
    // MARK: Private Methods
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
            print("Audio file succesfully loaded for \(url)")
            return tmpFileReader
        }else{
            print("Could not initialize audio input file")
            return nil
        }
    }()
    
    //==========================================
    // MARK: Model Callback Methods
    
    
   
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    
    private func handleSpeakerQueryWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>,
                                                 numFrames:UInt32,
                                                 numChannels: UInt32){
        if let file = self.fileReader{
            
            // read from file, loading into data (a float pointer)
            if let arrayData = data{
                // get samples from audio file, pass array by reference
                file.retrieveFreshAudio(arrayData,
                                        numFrames: numFrames,
                                        numChannels: numChannels)
                // that is it! The file was just loaded into the data array
                
                // adjust volume of audio file output
                vDSP_vsmul(arrayData, 1, &(self.volume), arrayData, 1, vDSP_Length(numFrames*numChannels))
                
            }
            
            
            
        }
    }
    
    
}
