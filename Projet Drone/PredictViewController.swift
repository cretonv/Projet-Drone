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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        neuralNet = FFNN.read(FFNN.getFileURL("toto"))
        
        var currentAccData = [Double]()
        var currentGyroData = [Double]()
        
        SharedToyBox.instance.bolt?.sensorControl.enable(sensors: SensorMask.init(arrayLiteral: .accelerometer,.gyro))
        SharedToyBox.instance.bolt?.sensorControl.interval = 1
        SharedToyBox.instance.bolt?.setStabilization(state: SetStabilization.State.off)
        SharedToyBox.instance.bolt?.displayArrow(color: .red)
        
        SharedToyBox.instance.bolt?.sensorControl.onDataReady = { data in
            DispatchQueue.main.async {
                if self.isPredicting {
                    
                    SharedToyBox.instance.bolt?.displayArrow(color: .green)

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
                        
                    }
                    if currentAccData.count+currentGyroData.count >= 1800 {
                        if self.isPredicting {
                            self.isPredicting = false
                            
                            // Normalisation
                            let minAcc = currentAccData.min()!
                            let maxAcc = currentAccData.max()!
                            let normalizedAcc = currentAccData.map { Float(($0 - minAcc) / (maxAcc - minAcc)) }
                            
                            let prediction = try! self.neuralNet?.update(inputs: normalizedAcc)
                            
                            let index = prediction?.index(of: (prediction?.max()!)!)! // [0.89,0.03,0.14]
                            
                            
                            let recognizedClass = Classes(rawValue: index!)!
                            print(recognizedClass)
                            print(prediction!)
                            
                            var str = "Je pense que c'est un "
                            switch recognizedClass {
                            case .Carre: str = str+"carré!"
                            case .Lune: str = str+"lune!"
                            case .Vague: str = str+"vague!"
                            case .Triangle: str = str+"triangle!"
                            }
                            self.resultLabel.text = str
                            
                            let utterance = AVSpeechUtterance(string: str)
                            utterance.voice = AVSpeechSynthesisVoice(language: "fr-Fr")
                            utterance.rate = 0.4
                            
                            let synthesizer = AVSpeechSynthesizer()
                            synthesizer.speak(utterance)
                            currentAccData = []
                            currentGyroData = []
                            SharedToyBox.instance.bolt?.displayArrow(color: .red)
                        }
                    }
                } else {
                    SharedToyBox.instance.bolt?.displayArrow(color: .red)
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
    
    
    @IBAction func predict(_ sender: UIButton) {
        self.isPredicting = true
    }
    

}
