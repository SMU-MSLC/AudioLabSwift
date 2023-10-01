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

// Enumerate Gesture Types
enum GestureType {
    case towardsMicrophone
    case awayFromMicrophone
    case noGesture
}

class ModuleBViewController: UIViewController {
    
    // Outlets Defined On Storyboard - Hopefully Self-Explanatory!
    @IBOutlet weak var gesture_label: UILabel!
    @IBOutlet weak var decibel_label: UILabel!
    @IBOutlet weak var tone_slider_label: UILabel!
    @IBOutlet weak var tone_slider: UISlider!
    @IBOutlet weak var graphView: UIView!
    
    // Create AudioConstants For Module B
    // (Structure With Any Constants Necessary To Run AudioModel)
    struct ModuleBAudioConstants {
        static let AUDIO_BUFFER_SIZE = 1024 * 4
    }
    
    // Create AudioModel Object With Specified Buffer Size
    let audio = AudioModel(buffer_size: ModuleBAudioConstants.AUDIO_BUFFER_SIZE)
    
    // Lazy Instantiation For Graph
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.graphView)
    }()
    
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
        
        Timer.scheduledTimer(timeInterval: 1.0 / 20, target: self, selector: #selector(updateDecibelLabel), userInfo: nil, repeats: true)
        
        // Run Loop For Updating View Periodically
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateView()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        audio.pause()
    }
    
    // Run Periodic Updates
    @objc func updateView() {
        self.graph?.updateGraph(
            data: self.audio.fftData,
            forKey: "fft"
        )
        self.graph?.updateGraph(
            data: self.audio.timeData,
            forKey: "time"
        )
    }
    
    // Method to handle gesture detection based on Doppler shifts
    //
    // FIXME (NEED TO CALL A FUNCTION IN AUDIOMODEL FOR THIS)
    //
    private func detectGesture(usingFFT fftData: [Float]) -> GestureType {
        // Implement your gesture detection logic based on Doppler shifts here
        // You can analyze the FFT data to determine gestures towards, away, or no gesture
        // This can involve comparing current and previous FFT data for Doppler shifts.
        // For this example, let's assume a simple threshold-based approach.
        let threshold: Float = 50.0 // Adjust this threshold as needed
        let maxFFTValue = fftData.max() ?? 0.0
        if maxFFTValue > threshold {
            return .towardsMicrophone
        } else {
            return .awayFromMicrophone
        }
    }
    
    // Action When Tone Slider Value Changed
    @IBAction func ToneSliderValueChanged(_ sender: UISlider) {
        audio.setToneFrequency(sender.value)
        
        // Update Slider Label Text With Current Slider Value
        tone_slider_label.text = String(format: "Tone Slider: %.2f kHz", sender.value / 1000.0)
    }

    // Update the label to display FFT magnitude in decibels
    @objc func updateDecibelLabel() {
        let maxDecibels = audio.getMaxDecibels()
        decibel_label.text = "\(maxDecibels)"
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
