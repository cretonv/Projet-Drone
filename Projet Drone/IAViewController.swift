//
//  IAViewController.swift
//  Projet Drone
//
//  Created by Vincent Creton on 02/12/2021.
//

import UIKit
import simd
import AVFoundation

class IAViewController: UIViewController {
    
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

    @IBOutlet weak var gyroChart: GraphView!
    @IBOutlet weak var acceleroChart: GraphView!
    var movementData = [Classes:[[Float]]]()
    var selectedClass = Classes.Carre
    var isPredicting = false


    override func viewDidLoad() {
        super.viewDidLoad()
        
        var currentAccData = [Double]()
        var currentGyroData = [Double]()
        
        SocketIOManager.instance.setRoom()
        SocketIOManager.instance.connect {
            print("Connecté")
            
            SocketIOManager.instance.listenToChannel(channel: "start_detection") { str in
                print("Received \(str)")
                // SharedToyBox.instance.bolt?.clearMatrix()
                // SharedToyBox.instance.bolt?.displayArrow(color: .green)

                self.delay(3) {
                    print("GOOOOOOOOOOOOOOOOOOOOOOOO")
                    if(!self.isPredicting && str == SharedToyBox.instance.bolt?.boltNum) {
                        currentAccData = []
                        currentGyroData = []
                        SharedToyBox.instance.bolt?.clearMatrix()
                        SharedToyBox.instance.bolt?.displayArrow(color: .green)
                        self.isPredicting = true
                        
                    }
                }
                self.delay(2) {
                    SharedToyBox.instance.bolt?.clearMatrix()
                    SharedToyBox.instance.bolt?.displayOne(color: .red)
                }
                self.delay(1) {
                    SharedToyBox.instance.bolt?.clearMatrix()
                    SharedToyBox.instance.bolt?.displayTwo(color: .red)
                }
                SharedToyBox.instance.bolt?.clearMatrix()
                SharedToyBox.instance.bolt?.displayThree(color: .red)
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
                if self.isPredicting {
                    
                    if let acceleration = data.accelerometer?.filteredAcceleration {
                        // PAS BIEN!!!
                        currentAccData.append(contentsOf: [acceleration.x!, acceleration.y!, acceleration.z!])
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
                        currentGyroData.append(contentsOf: [Double(gyro.x!), Double(gyro.y!), Double(gyro.z!)])
                        self.gyroChart.add(rotationRate)
                    }
                    
                    print(currentAccData.count)
                    
                    if currentAccData.count+currentGyroData.count >= 3600 {
                        print("Data ready for network!")
                        
                        //SharedToyBox.instance.bolt?.displayArrow(color: .red)
                            self.isPredicting = false
                            
                            // Normalisation
                            let minAcc = currentAccData.min()!
                            let maxAcc = currentAccData.max()!
                            let normalizedAcc = currentAccData.map { Float(($0 - minAcc) / (maxAcc - minAcc)) }
                            let minGyr = currentGyroData.min()!
                            let maxGyr = currentGyroData.max()!
                            let normalizedGyr = currentGyroData.map { Float(($0 - minGyr) / (maxGyr - minGyr)) }
                            
                            let prediction = try! self.neuralNet?.update(inputs: normalizedAcc)
                            
                            let index = prediction?.index(of: (prediction?.max()!)!)! // [0.89,0.03,0.14]
                            
                            
                            let recognizedClass = Classes(rawValue: index!)!
                            print(recognizedClass)
                            print(prediction!)
                            
                            var str = "Je pense que c'est un "
                            switch recognizedClass {
                            case .Carre:
                                str = str+"carré!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "D", color: .green, speed: 6, loop: .loopForever)
                                self.delay(10) {
                                    SharedToyBox.instance.bolt?.clearMatrix()
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Lune:
                                str = str+"lune!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "I", color: .green, speed: 6, loop: .loopForever)
                                self.delay(10) {
                                    SharedToyBox.instance.bolt?.clearMatrix()
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Vague:
                                str = str+"vague!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "E", color: .green, speed: 6, loop: .loopForever)
                                self.delay(10) {
                                    SharedToyBox.instance.bolt?.clearMatrix()
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            case .Triangle:
                                str = str+"triangle!"
                                SharedToyBox.instance.bolt?.scrollMatrix(text: "A", color: .green, speed: 6, loop: .loopForever)
                                self.delay(10) {
                                    SharedToyBox.instance.bolt?.clearMatrix()
                                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
                                }
                            }
                            let utterance = AVSpeechUtterance(string: str)
                            utterance.voice = AVSpeechSynthesisVoice(language: "fr-Fr")
                            utterance.rate = 0.4
                            
                            let synthesizer = AVSpeechSynthesizer()
                            synthesizer.speak(utterance)
                            currentAccData = []
                            currentGyroData = []
                        }
                }
            }
        }
    }
    
    func saveNN() {
        let now = Date()

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        
        

        let datetime = formatter.string(from: now)
        print(datetime)
        neuralNet?.write(FFNN.getFileURL(datetime))
    }
    
    func delay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
    
    func loadNN() {
        neuralNet = FFNN.read(FFNN.getFileURL("tata"))
        let url = FFNN.getFileURL("tata")
        print(url)
        print(FFNN.read(url))
    }
    
    @IBAction func trainButtonClicked(_ sender: Any) {
        
        trainNetwork()
        
    }
    
    
    @IBAction func predictButtonClicked(_ sender: Any) {
        self.isPredicting = true
    }
    
    func trainNetwork() {
        
        // --------------------------------------
        // TRAINING
        // --------------------------------------
        for i in 0...20 {
            print(i)
            if let selectedClass = movementData.randomElement(),
                let input = selectedClass.value.randomElement(){
                let expectedResponse = selectedClass.key.neuralNetResponse()
                
                let floatInput = input.map{ Float($0) }
                let floatRes = expectedResponse.map{ Float($0) }
                
                try! neuralNet?.update(inputs: floatInput) // -> [0.23,0.67,0.99]
                try! neuralNet?.backpropagate(answer: floatRes)
                
            }
        }
        
        // --------------------------------------
        // VALIDATION
        // --------------------------------------
        for k in movementData.keys {
            print("Inference for \(k)")
            let values = movementData[k]!
            for v in values {
                let floatInput = v.map{ Float($0) }
                let prediction = try! neuralNet?.update(inputs:floatInput)
                print(prediction!)
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        SharedToyBox.instance.bolt?.sensorControl.disable()
    }

    @IBAction func segementedControlChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if let s  = Classes(rawValue: index){
            selectedClass = s
        }
    }
    
    @IBAction func startButtonClicked(_ sender: Any) {
        
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        saveNN()
    }
    
    @IBAction func loadButtonClicked(_ sender: Any) {
        loadNN()
    }
}
