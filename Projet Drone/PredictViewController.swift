//
//  PredictViewController.swift
//  Projet Drone
//
//  Created by Vincent Creton on 13/12/2021.
//

import UIKit
import simd
import AVFoundation

class PredictViewController: UIViewController {

    @IBOutlet weak var resultLabel: UILabel!
    
    var neuralNet:FFNN? = nil
    var isPredicting = false
    
    var currentAccData = [Double]()
    var currentGyroData = [Double]()
    
    enum Classes:Int {
        case Carre,Triangle,Lune,Vague
        
        func neuralNetResponse() -> [Double] {
            switch self {
            case .Carre: return [1.0,0.0,0.0,0.0]
            case .Triangle: return [0.0,1.0,0.0,0.0]
            case .Lune: return [0.0,0.0,1.0,0.0]
            case .Vague: return [0.0,0.0,0.0,1.0]
            }
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in }
        isPredicting = false
    }
    
    @IBAction func loadNNClicked(_ sender: Any) {
        loadNN()
    }
    func loadNN() {
        neuralNet = FFNN.read(FFNN.getFileURL("toto"))
        let url = FFNN.getFileURL("toto")
        print(url)
        print(FFNN.read(url))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //qSharedToyBox.instance.bolt?.setBoltNum(num: "1")
        
        SocketIOManager.instance.setRoom()
        SocketIOManager.instance.connect {
            print("Connecté")
            SocketIOManager.instance.listenToChannel(channel: "start_detection") { str in
                print("Received \(str)")
                if(!self.isPredicting && str == SharedToyBox.instance.bolt?.boltNum) {
                    self.currentAccData = []
                    self.currentGyroData = []
                    SharedToyBox.instance.bolt?.displayArrow(color: .green)
                    self.isPredicting = true
                }
            }
        }
        
        neuralNet = FFNN(inputs: 1800, hidden: 20, outputs: 4, learningRate: 0.3, momentum: 0.2, weights: nil, activationFunction: .Sigmoid, errorFunction:.crossEntropy(average: false))// .default(average: true))
        neuralNet = FFNN.read(FFNN.getFileURL("toto"))
        
        
       
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.displayArrow(color: .red)

        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                if self.isPredicting {
                    print(self.currentAccData.count)
                    if let acceleration = data.accelerometer?.filteredAcceleration {
                        // PAS BIEN!!!
                        self.currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
                        let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                        let dataToDisplay: double3 = [acceleration.x!, acceleration.y!, acceleration.z!]
                        
                    }
                    
                    if let gyro = data.gyro?.rotationRate {
                        // TOUJOURS PAS BIEN!!!
                        let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                        self.currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                    }
                    
                    print(self.currentAccData.count)
                    if self.currentAccData.count + self.currentGyroData.count >= 3600 {
                        if self.isPredicting {
                            self.isPredicting = false
                            
                            // Normalisation
                            let minAcc = self.currentAccData.min()!
                            let maxAcc = self.currentAccData.max()!
                            let normalizedAcc = self.currentAccData.map { Float(($0 - minAcc) / (maxAcc - minAcc)) }
                            
                            let prediction = try! self.neuralNet?.update(inputs: normalizedAcc)
                            
                            let index = prediction?.index(of: (prediction?.max()!)!)! // [0.89,0.03,0.14]
                            
                            
                            let recognizedClass = Classes(rawValue: index!)!
                            print(recognizedClass)
                            print(prediction!)
                            
                            var str = "Je pense que c'est un "
                            /*switch recognizedClass {
                            case .Carre:
                                str = str+"carré!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "D", color: .green, speed: 3, loop: .noLoop)
                                self.delay(5) {
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Lune:
                                str = str+"lune!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "I", color: .green, speed: 3, loop: .noLoop)
                                self.delay(5) {
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Vague:
                                str = str+"vague!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "E", color: .green, speed: 3, loop: .noLoop)
                                self.delay(5) {
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Triangle:
                                str = str+"triangle!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "A", color: .green, speed: 3, loop: .noLoop)
                                self.delay(5) {
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            }*/
                            self.resultLabel.text = str
                            
                            SharedToyBox.instance.bolt?.displayArrow(color: .red)
                            
                            let utterance = AVSpeechUtterance(string: str)
                            utterance.voice = AVSpeechSynthesisVoice(language: "fr-Fr")
                            utterance.rate = 0.4
                            
                            let synthesizer = AVSpeechSynthesizer()
                            synthesizer.speak(utterance)
                            self.currentAccData = []
                            self.currentGyroData = []
                        }
                    }
                }
            }
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
    
    func delay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    
    @IBAction func predict(_ sender: UIButton) {
        self.currentAccData = []
        self.currentGyroData = []
        SharedToyBox.instance.bolt?.displayArrow(color: .green)
        self.isPredicting = true
        /*delay(0.5) {
            
        }*/
       
    }
    
    @IBAction func testWriting(_ sender: Any) {
        SocketIOManager.instance.listenToChannel(channel: "start_detection") { str in
            print("Received")
            print(str)
        }
    }
    
}
