//
//  ModuleBViewController.swift
//  AudioLabSwift
//
//  Created by William Landin on 9/25/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//
//  Lab Two: Audio Filtering, FFT, Doppler Shifts
//  Trevor Dohm, Will Landin, Ray Irani, Alex Shockley
//

// Import Statements
import UIKit

class ModuleBViewController: UIViewController {
    
    // Outlets Defined On Storyboard - Hopefully Self-Explanatory!
    @IBOutlet weak var gesture_label: UILabel!
    @IBOutlet weak var decibel_label: UILabel!
    @IBOutlet weak var tone_slider_label: UILabel!
    @IBOutlet weak var tone_slider: UISlider!
    @IBOutlet weak var graphView: UIView!
    
    // Action When Tone Slider Value Changed
    @IBAction func ToneSliderValueChanged(_ sender: UISlider) {
        audio.setToneFrequency(sender.value)
        
//        // Reset For New Baseline Calculation
//        sumArray = [0.0, 0.0]
//        baselineCount = 0
        
        // Update Slider Label Text With Current Slider Value
        tone_slider_label.text = String(format: "Tone Slider: %.2f kHz", sender.value / 1000.0)
    }
    
    // Create AudioConstants For Module B
    // (Structure With Any Constants Necessary To Run AudioModel)
    struct ModuleBAudioConstants {
        static let AUDIO_BUFFER_SIZE = 1024 * 4
        static let BASELINE_COUNT = 128
    }
    
    // Create AudioModel Object With Specified Buffer Size
    let audio = AudioModel(buffer_size: ModuleBAudioConstants.AUDIO_BUFFER_SIZE)
    
    // Instantiate Timer Object
    var updateViewTimer: Timer?
    
    // Lazy Instantiation For Graph
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()
    
//    // Sums Over LHS / RHS
//    var sumArray: [Float] = [0.0, 0.0]
//
//    // Target Peaks For LHS / RHS
//    var peakArray: [Float] = [0.0, 0.0]
//
//    // Incrementor (To Constant)
//    var baselineCount = 0
    
    // Runs When View Loads (With Super Method)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Graphs For Display
        graph?.addGraph(withName: "fft",
            shouldNormalizeForFFT: true,
            numPointsInGraph: ModuleBAudioConstants.AUDIO_BUFFER_SIZE / 2)
        graph?.addGraph(withName: "time",
            numPointsInGraph: ModuleBAudioConstants.AUDIO_BUFFER_SIZE)
        
        // Querying Microphone, Speaker From AudioModel With Preferred
        // Calculations (Gestures, FFT, Doppler Shifts) Per Second
        audio.startDualProcessing(withFps: 20)
        
        // Set Initial Tone Frequency Based On Slider Value
        audio.setToneFrequency(tone_slider.value)

        // Handle Audio
        audio.play()
        
        // Run Loop For Updating View Periodically
        updateViewTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] (updateViewTimer) in
            self?.updateView()
        }
    }
    
    // Stop Audio, Invalidate Timer Object - Good Practice
    // To Call Super Function After Local Deallocation
    override func viewDidDisappear(_ animated: Bool) {
        audio.pause()
        updateViewTimer?.invalidate()
        super.viewDidDisappear(animated)
    }
    
    // Run Periodic Updates
    @objc func updateView() {
        updateGraphs()
        updateMaxDecibels()
        
        // Unpack Side Averages From Model Call
        let (lAvg, rAvg) = audio.localAverages(sliderFreq: tone_slider.value)
        
        measureDopplerEffect(lAvg: lAvg, rAvg: rAvg)
        
        // Create Baseline, Then Measure Doppler Effect
//        if baselineCount < ModuleBAudioConstants.BASELINE_COUNT {
//            sumArray = [sumArray[0] + lAvg, sumArray[1] + rAvg]
//            gesture_label.text = "Establishing Baseline..."
//        } else if baselineCount == ModuleBAudioConstants.BASELINE_COUNT {
//            peakArray = [sumArray[0] / Float(ModuleBAudioConstants.BASELINE_COUNT),
//                         sumArray[1] / Float(ModuleBAudioConstants.BASELINE_COUNT)]
//        } else {
//            measureDopplerEffect(lAvg: lAvg, rAvg: rAvg)
//        }
//
//        // Increment Baseline Count
//        baselineCount += 1
    }
    
    // Update Graphs
    private func updateGraphs() {
        self.graph?.updateGraph(data: self.audio.fftData, forKey: "fft")
        self.graph?.updateGraph(data: self.audio.timeData, forKey: "time")
    }
    
    // Calculate Max Decibels, Update Label
    private func updateMaxDecibels() {
        decibel_label.text = String(format: "%.2f", audio.getMaxDecibels())
    }
    
    // Measure Doppler Effect Based On Baseline Calculation
    private func measureDopplerEffect(lAvg:Float, rAvg:Float) {
//        let changeLeftPeak = abs(lAvg - peakArray[0])
//        let changeRightPeak = abs(rAvg - peakArray[1])
//        let changePeak = abs(lAvg - rAvg)
        
        // Decide Gesture (Based On Range)
        if -3.65 < lAvg - rAvg && lAvg - rAvg < 6.35 {
            gesture_label.text = "Still"
        } else if lAvg - rAvg >= 6.35 {
            gesture_label.text = "Moving Closer!"
        } else {
            gesture_label.text = "Moving Farther!"
        }
        
//        if changePeak <= 0.07 {
//            gesture_label.text = "Still"
//        } else if changeRightPeak > changeLeftPeak{
//            gesture_label.text = "Moving Closer!"
//        } else if changeRightPeak > changeLeftPeak{
//            gesture_label.text = "Moving Farther!"
//        }
    }
}
