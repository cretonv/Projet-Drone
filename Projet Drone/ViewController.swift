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
        
        WebSocketManager.instance.addSocket(url: "http://172.17.128.177:8080/",path: "toto")
        
        var currentAccData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                
                if self.isRecording || self.isPredicting {
                    
                    if(self.isListening) {
                        if let acceleration = data.accelerometer?.filteredAcceleration {
                            // PAS BIEN!!!
                            currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
                            let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                            if absSum > 6 {
                                print("Secousse")
                                self.timer?.invalidate()
                                self.isListening = false
                                self.delay(0.25) {
                                    self.tapSum += 1
                                    self.isListening = true
                                    self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { t in
                                        print("tapSum: \(self.tapSum)")
                                        if(self.tapSum == 3) {
                                            self.textToDisplay += "Bonjour"
                                        } else if(self.tapSum == 5) {
                                            self.textToDisplay += "Au Revoir"
                                        /*} else if(self.tapSum == 6) {
                                            for n in 0 ... 7 {
                                                for i in 0 ... 7 {
                                                    SharedToyBox.instance.bolts.map{ $0.drawMatrix(pixel: Pixel(x: n, y: i), color: .green) }
                                                }
                                            }
                                        } else if(self.tapSum == 7) {
                                            SharedToyBox.instance.bolts.map{ $0.drawMatrixLine(from: Pixel(x: 0, y: 3), to: Pixel(x: 0, y: 7), color: .magenta) }
                                            SharedToyBox.instance.bolts.map{ $0.drawMatrixLine(from: Pixel(x: 2, y: 1), to: Pixel(x: 0, y: 7), color: .brown) }
                                            SharedToyBox.instance.bolts.map{ $0.drawMatrixLine(from: Pixel(x: 4, y: 5), to: Pixel(x: 0, y: 7), color: .orange) }*/
                                        } else if(self.tapSum == 10) {
                                            WebSocketManager.instance.sendOn(path: "toto", value: String(self.textToDisplay))
                                            print(self.textToDisplay)
                                            self.textToDisplay = "Message envoyé"
                                        } else {
                                            self.textToDisplay += String(self.tapSum)
                                        }
                                        SharedToyBox.instance.bolts.map{
                                            $0.scrollMatrix(text: self.textToDisplay, color: .blue, speed: 8, loop: .noLoop)
                                        }
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
    
    func delay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    @IBAction func startListening(_ sender: Any) {
        isRecording = true
    }
    
}

