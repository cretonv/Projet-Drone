//
//  WebSocketManager.swift
//  SparkPerso
//
//  Created by Vincent Creton on 01/12/2021.
//  Copyright © 2021 AlbanPerli. All rights reserved.
//

import Foundation
import Starscream

class WebSocketManager:WebSocketDelegate {
    
    static let instance = WebSocketManager()
    var sockets = [String:WebSocket]()
    
    var receivedData: ((String)->())?
    
    func addSocket(url:String,path:String) {
        var request = URLRequest(url: URL(string: url+path)!)
        request.timeoutInterval = 5
        let socket = WebSocket(request: request)
        socket.delegate = self
        socket.connect()
        
        sockets[path] = socket
    }
    
    func didReceivedData(callback:@escaping (String)->()) {
        self.receivedData = callback
    }
    
    func sendOn(path:String, value:String){
        sockets[path]?.write(string: value, completion: {
            print("Send completion from socket manager")
        })
    }

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected(let headers):
            
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            if let callback = self.receivedData{
                callback(string)
            }
        case .binary(let data):
            print("Received data: \(data.count)")
        case .ping(_):
            break
        case .pong(_):
            break
        case .viabilityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled: break
            
        case .error(let error): break
        }
    }
}

