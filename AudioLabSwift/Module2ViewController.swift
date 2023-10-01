//
//  Module2ViewController.swift
//  AudioLabSwift
//
//  Created by William Landin on 9/25/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//

import UIKit

enum GestureType {
    case towardsMicrophone
    case awayFromMicrophone
    case noGesture
}

class Module2ViewController: UIViewController {
    
    // Create AudioConstants (Structure With Any
    // Constants Necessary To Run AudioModel)
    struct AudioConstants {
        static let AUDIO_BUFFER_SIZE = 1024 * 4
    }
    
    // Create AudioModel Object With Specified Buffer Size
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)

    // Outlets Defined On Storyboard - Hopefully Self-Explanatory!
    @IBOutlet weak var gesture_label: UILabel!
    @IBOutlet weak var decibel_label: UILabel!
    @IBOutlet weak var tone_slider_label: UILabel!
    @IBOutlet weak var tone_slider: UISlider!

    // Runs When View Loads (With Super Method)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Querying Microphone, Speaker From AudioModel With Preferred
        // Calculations (Gestures, FFT, Doppler Shifts) Per Second
        audio.startDualProcessing(withFps: 20)

        // Handle Audio
        audio.play()
        
        // Set the initial tone frequency based on the slider value
        audio.setToneFrequency(tone_slider.value)
        
        // Add an observer to update tone frequency when the slider is moved
        tone_slider.addTarget(self, action: #selector(toneSliderValueChanged(_:)), for: .valueChanged)
        
        Timer.scheduledTimer(timeInterval: 1.0 / 20, target: self, selector: #selector(updateDecibelLabel), userInfo: nil, repeats: true)
    }
    
    // Method to handle gesture detection based on Doppler shifts
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
    
    // Tone slider value changed
    @objc func toneSliderValueChanged(_ sender: UISlider) {
        audio.setToneFrequency(sender.value)
        
        // Update the slider label text with the current slider value
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
