//
//  TableViewController.swift
//  AudioLabSwift
//
//  Created by Arthur Zhang on 10/3/22.
//  Copyright © 2022 Eric Larson. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Module A", for: indexPath)
            cell.textLabel?.text = "Module A"
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "Module B", for: indexPath)
            cell.textLabel?.text = "Module B"
            return cell
        }
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
