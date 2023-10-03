//
//  ViewController.swift
//  AudioLabSwift
//
//  Created by Eric Larson 
//  Copyright © 2020 Eric Larson. All rights reserved.
//

import UIKit
import Metal





class ViewController: UIViewController {

    @IBOutlet weak var userView: UIView!
    struct AudioConstants{
        static let AUDIO_BUFFER_SIZE = 1024*4
    }
    
    // setup audio model
    let audio = AudioModel(buffer_size: AudioConstants.AUDIO_BUFFER_SIZE)
    lazy var graph:MetalGraph? = {
        return MetalGraph(userView: self.userView)
    }()
    var timer:Timer? = nil
    
    var frequency1:Float = 300 {
        didSet{
            audio.sineFrequency1 = frequency1
            labelF1.text = "F1: \(frequency1)"
        }
    }
    var frequency2:Float = 300 {
        didSet{
            audio.sineFrequency2 = frequency2
            labelF2.text = "F2: \(frequency2)"
        }
    }
    var frequency3:Float = 300 {
        didSet{
            audio.sineFrequency3 = frequency3
            labelF3.text = "F3: \(frequency3)"
        }
    }
    
    @IBOutlet weak var labelF1: UILabel!
    @IBOutlet weak var labelF2: UILabel!
    @IBOutlet weak var labelF3: UILabel!
    
    @IBAction func setClose(_ sender: Any) {
        let diff = abs(frequency1-frequency2)
        if diff > 100 {
            frequency2 = frequency1 + 99
        }else if diff > 60{
            frequency2 = frequency1 + 51
        }else if diff > 30{
            frequency2 = frequency1 + 10
        }else{
            frequency2 = frequency1 + 300
        }
    }
    
    @IBAction func shouldPulse(_ sender: UISwitch) {
        audio.pulsing = sender.isOn
    }
    
    @IBAction func sliderF1(_ sender: UISlider) {
        frequency1 = sender.value
    }
    
    @IBAction func sliderF2(_ sender: UISlider) {
        frequency2 = sender.value
    }
    
    @IBAction func sliderF3(_ sender: UISlider) {
        frequency3 = sender.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frequency1 = 18000
        frequency2 = 18500
        frequency3 = 19000
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let graph = self.graph{
            graph.setBackgroundColor(r: 0, g: 0, b: 0, a: 1)
            
            // add in graphs for display
            // note that we need to normalize the scale of this graph
            // because the fft is returned in dB which has very large negative values and some large positive values
            
            // BONUS: lets also display a version of the FFT that is zoomed in
            graph.addGraph(withName: "fftZoomed",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: 300) // 300 points to display
            
            
            graph.addGraph(withName: "fft",
                            shouldNormalizeForFFT: true,
                            numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE/2)
            
            graph.addGraph(withName: "time",
                numPointsInGraph: AudioConstants.AUDIO_BUFFER_SIZE)
            
            
            
            graph.makeGrids() // add grids to graph
        }
        
        // start up the audio model here, querying microphone
        audio.startMicrophoneProcessing(withFps: 20) // preferred number of FFT calculations per second

        audio.play()
        
        // run the loop for updating the graph peridocially
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            self.updateGraph()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        timer?.invalidate()
        graph?.teardown()
        graph = nil
        audio.stop()
        super.viewDidDisappear(animated)
        
    }
    
    // periodically, update the graph with refreshed FFT Data
    func updateGraph(){
        
        if let graph = self.graph{
            graph.updateGraph(
                data: self.audio.fftData,
                forKey: "fft"
            )
            
            graph.updateGraph(
                data: self.audio.timeData,
                forKey: "time"
            )
            
            // BONUS: show the zoomed FFT
            // we can start at about 150Hz and show the next 300 points
            // actual Hz = f_0 * N/F_s
            let minfreq = min(min(frequency1,frequency2),frequency3)
            let startIdx:Int = (Int(minfreq)-50) * AudioConstants.AUDIO_BUFFER_SIZE/audio.samplingRate
            let subArray:[Float] = Array(self.audio.fftData[startIdx...startIdx+300])
            graph.updateGraph(
                data: subArray,
                forKey: "fftZoomed"
            )
            
            
        }
        
    }
    
    

}

