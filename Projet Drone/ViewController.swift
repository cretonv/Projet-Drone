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
            
            SocketIOManager.instance.listenToChannel(channel: "button_event") { str in
                print("Button event from server: \(str)")
                
                let parsingData = str?.components(separatedBy: ":")
                
                let buttonId = parsingData?[0]
                let buttonType = parsingData?[1]
                
                if let id = buttonId {
                    if (id == SharedToyBox.instance.getIdOfActive()) {

                        var user: String = ""
                        var message: String = ""
                        
                        user = "user-\(SharedToyBox.instance.getIdOfActive())"
                        message = SharedToyBox.instance.getTextOfActive()
                        
                        if let type = buttonType {
                            switch type {
                            case "submit":
                                self.sendMessage(message: "\(user) : \(message)")
                                
                                SharedToyBox.instance.resetTextOfActive()
                                SharedToyBox.instance.greenTheActive()
                                
                            case "delete":
                                SharedToyBox.instance.resetTextOfActive()
                                // TODO: Display the information on the sphero
                                
                                
                            default:
                                break
                            }
                            
                        }
                        
                    }
                }
            }
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
                                                self.sendMessage(message: "user-\(bolt.indexId!) : \(bolt.textToDisplay)")
                                                
                                                // TODO: Refacto
                                                bolt.textToDisplay = ""
                                                bolt.makePanelGreen()
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
        SocketIOManager.instance.writeValue("message", toChannel: "send_message") {
            print("Message: message sended")
        }
    }
    
    
    func sendMessage(message: String) {
        SocketIOManager.instance.writeValue(message, toChannel: "send_message") {
            print("Message: \(message) sended")
        }
        
        SharedToyBox.instance.changeActives()
    }
}

