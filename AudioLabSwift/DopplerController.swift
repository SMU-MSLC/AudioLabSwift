//
//  DopplerController.swift
//  AudioLabSwift
//
//  Created by Arthur Zhang on 10/9/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit
import Metal





class DopplerController: UIViewController {

    var freq = Float(20000)
    @IBOutlet weak var MotionStatus: UILabel!
    var last_status = Float(0)
    var status_array = Array.init(repeating: Float(0), count: 0)
    
    let audio = AudioModel(buffer_size: AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(mainView: self.view)
    }()
    
    @IBAction func sliderDidSlide(_ sender: UISlider){
        
        freq = sender.value * Float(1000)
        //audio.pause()
        audio.startProcessingSinewaveForPlayback(withFreq: freq)
        audio.play()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add in graphs for display
        graph?.addGraph(withName: "fft",
                        shouldNormalize: true,
                        numPointsInGraph: AUDIO_BUFFER_SIZE/2)
        
        graph?.addGraph(withName: "time",
            shouldNormalize: false,
            numPointsInGraph: AUDIO_BUFFER_SIZE)
        

        
        // start up the audio model
        audio.startMicrophoneProcessing(withFps: 10)
        //audio.startProcesingAudioFileForPlayback()
        print(freq)
        audio.startProcessingSinewaveForPlayback(withFreq: 20000)
        audio.play()
        
        // run the loop for updating the graph peridocially
        Timer.scheduledTimer(timeInterval: 0.02, target: self,
            selector: #selector(self.updateGraph),
            userInfo: nil,
            repeats: true)

        // run the loop to quickly update curr_status - last_status
        Timer.scheduledTimer(timeInterval: 0.02, target: self,
            selector: #selector(self.quicklyUpdateStatus),
            userInfo: nil,
            repeats: true)
        // run the loop to update status
        Timer.scheduledTimer(timeInterval: 1, target: self,
            selector: #selector(self.updateStatus),
            userInfo: nil,
            repeats: true)
        
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        audio.pause()
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
    
    @objc
    func updateStatus(){ //update the text labels
        
        if (status_array.count > 50){
//            print (status_array.count)
            var statusMean: Float = .nan
            //taking average of the two sets of data
            vDSP_meanv(status_array, vDSP_Stride(1), &statusMean, vDSP_Length(status_array.count))
            let statusInc = 100+statusMean*100 //increase the statusMean to make it easier for the following logic
//            MotionStatus.text = String(statusInc)
            if (statusInc>101){//frequency bounce-back increase when gesturing towards the device, means that curr_status > last_status as the hand is approaching the mic
                MotionStatus.text = "Approach"
            }
            else if (statusInc < 99){//frequency bounce-back decrease when gesturing away the device, means that curr_status > last_status as the hand is approaching the mic
                MotionStatus.text = "Away"
            }
            else{ //static, or hand is out of bound of detection
                MotionStatus.text = "Static"
            }
            status_array.removeAll()
        }
        
        
    }
    
    @objc
    func quicklyUpdateStatus(){
        // this is where we frequently call the calculateMotion function to fill an array within a time interval, so that we can calculate the motion within this time based on the average of (curr_status - last_status)
        let curr_status = audio.calculateMotion(currFreq: freq) //current status is (rhsData - lhsData),
        // meaning that if curr_Status >0, object is close to the mic, <0 means further
        status_array.append(curr_status - last_status) //when curr-last > 0, it means approaching, when <0, away
        last_status = curr_status// update the "last status" for future comparison
    }
    

}
