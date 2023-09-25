//
//  Module1ViewController.swift
//  AudioLabSwift
//
//  Created by William Landin on 9/24/23.
//  Copyright © 2023 Eric Larson. All rights reserved.
//

//This is our view controller for Module 1, this is where it will listen to frequencies, when the "stop"
// button is pressed it will display the 1st and second highest frequencies.

import UIKit

class Module1ViewController: UIViewController {

    
    //button to pause recording and make 2 other labels appear.
    @IBOutlet weak var lock_Hz_button: UIButton!
    
    //This is the label gives the user instructions of how to use our screen
    @IBOutlet weak var module_1_desc_button: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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

}
