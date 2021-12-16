//
//  XavierViewController.swift
//  Projet Drone
//
//  Created by Vincent Creton on 15/12/2021.
//

import UIKit
import simd
import AVFoundation

class XavierViewController: UIViewController {

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
    
    var neuralNet:FFNN? = nil

    @IBOutlet weak var resultLabel: UILabel!
    
    @IBOutlet weak var gyroChart: GraphView!
    @IBOutlet weak var acceleroChart: GraphView!
    var movementData = [Classes:[[Double]]]()
    var selectedClass = Classes.Carre
    var isRecording = false
    var isPredicting = false
    
    var currentAccData = [Double]()
    var currentGyroData = [Double]()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        SocketIOManager.instance.setRoom()
        SocketIOManager.instance.connect {
            print("Connecté")
            SocketIOManager.instance.listenToChannel(channel: "start_detection") { str in
                print("Received \(str)")
                self.delay(2) {
                    print("GOOOOOOOOOOOOOOOOOOOOOOOO")
                    if(!self.isPredicting && str == SharedToyBox.instance.bolt?.boltNum) {
                        self.currentAccData = []
                        self.currentGyroData = []
                        SharedToyBox.instance.bolt?.displayArrow(color: .green)
                        self.isPredicting = true
                    }
                }
            }
        }

        // Do any additional setup after loading the view.
        neuralNet = FFNN(inputs: 1800, hidden: 20, outputs: 4, learningRate: 0.3, momentum: 0.2, weights: nil, activationFunction: .Sigmoid, errorFunction:.crossEntropy(average: false))// .default(average: true))
        
        movementData[.Carre] = []
        movementData[.Lune] = []
        movementData[.Triangle] = []
        movementData[.Vague] = []
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.displayArrow(color: .red)

        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                if self.isRecording || self.isPredicting {
                    
                    if let acceleration = data.accelerometer?.filteredAcceleration {
                        // PAS BIEN!!!
                        self.currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
//                        if acceleration.x! >= 0.65 {
//                            print("droite")
//                        }else if acceleration.x! <= -0.65 {
//                            print("gauche")
//                        }
                        let absSum = abs(acceleration.x!)+abs(acceleration.y!)+abs(acceleration.z!)
                        let dataToDisplay: double3 = [acceleration.x!, acceleration.y!, acceleration.z!]
                        self.acceleroChart.add(dataToDisplay)
                    }
                    
                                        
                    if let gyro = data.gyro?.rotationRate {
                        // TOUJOURS PAS BIEN!!!
                        let rotationRate: double3 = [Double(gyro.x!)/2000.0, Double(gyro.y!)/2000.0, Double(gyro.z!)/2000.0]
                        self.currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                        self.gyroChart.add(rotationRate)
                    }
                    
                    print(self.currentAccData.count)
                    
                    if self.currentAccData.count+self.currentGyroData.count >= 3600 {
                        print("Data ready for network!")
                        SharedToyBox.instance.bolt?.displayArrow(color: .red)
                        if self.isRecording {
                            self.isRecording = false
                            
                            // Normalisation
                            let minAcc = self.currentAccData.min()!
                            let maxAcc = self.currentAccData.max()!
                            let normalizedAcc = self.currentAccData.map { ($0 - minAcc) / (maxAcc - minAcc) }
                            
                            let minGyr = self.currentGyroData.min()!
                            let maxGyr = self.currentGyroData.max()!
                            let normalizedGyr = self.currentGyroData.map { ($0 - minGyr) / (maxGyr - minGyr) }
                            
                            self.movementData[self.selectedClass]?.append(normalizedAcc)
                            self.currentAccData = []
                            self.currentGyroData = []
                        }
                        if self.isPredicting {
                            self.isPredicting = false
                            
                            // Normalisation
                            let minAcc = self.currentAccData.min()!
                            let maxAcc = self.currentAccData.max()!
                            let normalizedAcc = self.currentAccData.map { Float(($0 - minAcc) / (maxAcc - minAcc)) }
                            let minGyr = self.currentGyroData.min()!
                            let maxGyr = self.currentGyroData.max()!
                            let normalizedGyr = self.currentGyroData.map { Float(($0 - minGyr) / (maxGyr - minGyr)) }
                            
                            let prediction = try! self.neuralNet?.update(inputs: normalizedAcc)
                            
                            let index = prediction?.index(of: (prediction?.max()!)!)! // [0.89,0.03,0.14]
                            
                            
                            let recognizedClass = Classes(rawValue: index!)!
                            print(recognizedClass)
                            print(prediction!)
                            
                            var str = "Je pense que c'est un "
                            switch recognizedClass {
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
                            }
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
    
    func delay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func loadNN() {
        neuralNet = FFNN.read(FFNN.getFileURL("toto"))
        let url = FFNN.getFileURL("toto")
        print(url)
        print(FFNN.read(url))
    }
    
    @IBAction func predictButtonClicked(_ sender: Any) {
        self.isPredicting = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        SharedToyBox.instance.bolt?.sensorControl.disable()
    }
    
    @IBAction func loadButtonClicked(_ sender: Any) {
        loadNN()
    }
}
