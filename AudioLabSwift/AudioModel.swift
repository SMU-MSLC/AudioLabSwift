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
    var isPlaying = false
    private var BUFFER_SIZE:Int
    
    // MARK: Public Methods
    init() {
        BUFFER_SIZE = 0 // unused

    }
    
    // public function for playing from a file reader file
    func startProcesingAudioFileForPlayback(){
        // set the output block to read from and play the audio file
        if let manager = self.audioManager,
           let fileReader = self.fileReader{
            manager.outputBlock = self.handleSpeakerQueryWithAudioFile
            fileReader.play()
        }
    }
    
    
    // You must call this when you want the audio to start being handled by our model
    func play(){
        self.audioManager?.play()
        self.isPlaying = true
    }
    
    func togglePlaying(){
        if self.isPlaying{
            self.audioManager?.pause()
            self.isPlaying = false
        }else{
            self.audioManager?.play()
            self.isPlaying = true
        }
    }
    
    

    
    
    //==========================================
    // MARK: Private Properties
    private lazy var audioManager:Novocaine? = {
        return Novocaine.audioManager()
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
    
    
   
    
    //==========================================
    // MARK: Audiocard Callbacks
    // in obj-C it was (^InputBlock)(float *data, UInt32 numFrames, UInt32 numChannels)
    // and in swift this translates to:
    
    private func handleSpeakerQueryWithAudioFile(data:Optional<UnsafeMutablePointer<Float>>,
                                                 numFrames:UInt32,
                                                 numChannels: UInt32){
        if let file = self.fileReader{
            
            // read from file, loading into data (a float pointer)
            file.retrieveFreshAudio(data,
                                    numFrames: numFrames,
                                    numChannels: numChannels)
            // that is it! The file was just loaded into the data array
            
            
            
        }
    }
    
    
}
