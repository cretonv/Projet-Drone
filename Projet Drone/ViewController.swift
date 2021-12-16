//
//  ViewController.swift
//  Projet Drone
//
//  Created by Vincent Creton on 01/12/2021.
//

import UIKit
import simd
import AVFoundation
import Starscream

class ViewController: UIViewController {

    var isRecording = false
    var isPredicting = false
    
    var isListening = true
    var tapSum = 0
    var timer: Timer?
    var textToDisplay = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // WebSocketManager.instance.addSocket(url: "http://172.17.129.0:4000",path: "toto")
        SocketIOManager.instance.setup()
        SocketIOManager.instance.connect {
            print("Connecté")
        }
        
        SharedToyBox.instance.setActives()
        
        var currentAccData = [Double]()
        
        for bolt in SharedToyBox.instance.bolts {
            bolt.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
            bolt.sensorControl.interval = 1
            bolt.setStabilization(state: SetStabilization.State.off)
            if bolt.isActive {
                bolt.makePanelGreen()
            } else {
                bolt.makePanelRed()
            }
            bolt.sensorControl.onDataReady = { data in
                DispatchQueue.main.async {
                    
                    if self.isRecording || self.isPredicting {
                        
                        if(self.isListening) {
                            if let acceleration = data.accelerometer?.filteredAcceleration {
                                // PAS BIEN!!!
                                currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
                                let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                                if absSum > 6 && bolt.isActive == true {
                                    print("Secousse")
                                    self.timer?.invalidate()
                                    self.isListening = false
                                    self.delay(0.25) {
                                        self.tapSum += 1
                                        self.isListening = true
                                        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { t in
                                            print("tapSum: \(self.tapSum)")
                                            if(self.tapSum == 3) {
                                                bolt.textToDisplay += "3"
                                            } else if(self.tapSum == 5) {
                                                bolt.textToDisplay += "5"
                                            } else if(self.tapSum == 10) {
                                                SocketIOManager.instance.writeValue("user-\(bolt.indexId!) : \(bolt.textToDisplay)", toChannel: "send_message") {
                                                    print("Message envoyé")
                                                }
                                                bolt.textToDisplay = ""
                                                bolt.makePanelGreen()
                                                SharedToyBox.instance.changeActives()
                                            } else {
                                                bolt.textToDisplay += String(self.tapSum)
                                            }
                                            bolt.scrollMatrix(text: bolt.textToDisplay, color: .blue, speed: 10, loop: .noLoop)
                                            self.tapSum = 0
                                        }
                                    }
                                }else{
                                    
                                }
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    func delay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    @IBAction func startListening(_ sender: Any) {
        isRecording = true
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        SocketIOManager.instance.writeValue("Test message", toChannel: "send_message") {
            print("user-1 : Message from sphero 1")
        }
    }
}

