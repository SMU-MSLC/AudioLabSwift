//
//  ModuleAViewController.swift
//  AudioLabSwift
//
//  Created by William Landin on 9/24/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//

//This is our view controller for Module 1, this is where it will listen to frequencies, when the "stop"
// button is pressed it will display the 1st and second highest frequencies.

import UIKit

class ModuleAViewController: UIViewController {

    
    @IBOutlet weak var firstHzLabel: UILabel!
    //button to pause recording and make 2 other labels appear.
    @IBOutlet weak var secondHzLabel: UILabel!
    @IBOutlet weak var lock_Hz_button: UIButton!
    
    @IBOutlet weak var graphView: UIView!
    //This is the label gives the user instructions of how to use our screen
    @IBOutlet weak var module_1_desc_button: UILabel!
    
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()
    
    struct ModuleBAudioConstants {
        static let AUDIO_BUFFER_SIZE = 1024 * 4
    }
    
    // Create AudioModel Object With Specified Buffer Size
    let audio = AudioModel(buffer_size: ModuleBAudioConstants.AUDIO_BUFFER_SIZE)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        graph?.addGraph(withName: "fft",
            shouldNormalizeForFFT: true,
            numPointsInGraph: ModuleBAudioConstants.AUDIO_BUFFER_SIZE / 2)
        graph?.addGraph(withName: "time",
            numPointsInGraph: ModuleBAudioConstants.AUDIO_BUFFER_SIZE)
        
        audio.startMicrophoneProcessing(withFps: 20)
        
        audio.play()
        
        Timer.scheduledTimer(timeInterval: 1.0/20.0, target: self, selector: #selector(runOnInterval), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
        Timer.scheduledTimer(withTimeInterval: 1.0/20.0, repeats: true) { _ in
            self.updateView()
        }
    }
    @objc func runOnInterval(){
//        print("Hello World")
        if audio.isLoudSound(cutoff: 1.0) {
            secondHzLabel.text = "LOUD SOUND"
//            print("Loud Sound")
        } else {
            secondHzLabel.text = "NO Loud Sound"
        }
    }
    
    @objc func updateView() {
        self.graph?.updateGraph(
            data: self.audio.frozenFftData,
            forKey: "fft"
        )
        self.graph?.updateGraph(
            data: self.audio.frozenTimeData,
            forKey: "time"
        )
    }
    
    @IBAction func lockFreqPressed(_ sender: Any) {
        module_1_desc_button.text = "Below are the 2 highest Hz  of the sound you made. Exit and return to this page to try a different sound"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func viewWillDisappear(_ animated: Bool) {
        audio.pause()
    }

}
