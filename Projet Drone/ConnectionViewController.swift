//
//  ConnectionViewController.swift
//  Projet Drone
//
//  Created by Vincent Creton on 01/12/2021.
//

import UIKit

class ConnectionViewController: UIViewController {

    @IBOutlet weak var connectionStateSpheroLabel: UILabel!
    let SSID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // SPHERO CONNECTION
    @IBAction func connectionSpheroButtonClicked(_ sender: Any) {
        SharedToyBox.instance.searchForBoltsNamed(["SB-5D1C", "SB-808F"]) { err in
            if err == nil {
                self.connectionStateSpheroLabel.text = "Connected"
                SharedToyBox.instance.giveIndexIdToBolts()
            }
        }
    }
    @IBAction func goToListening(_ sender: Any) {
        self.performSegue(withIdentifier: "goToListening", sender: nil)
    }
    
    @IBAction func goToIA(_ sender: Any) {
        self.performSegue(withIdentifier: "goToIA", sender: nil)
    }
    
    @IBAction func goToPredict(_ sender: Any) {
        self.performSegue(withIdentifier: "goToPredict", sender: nil)
    }
}
