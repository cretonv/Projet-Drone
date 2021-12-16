//
//  SocketIOManager.swift
//  SparkPerso
//
//  Created by AL on 30/10/2019.
//  Copyright © 2019 AlbanPerli. All rights reserved.
//

import Foundation
import SocketIO

class SocketIOManager {
    
    struct Ctx {
        var ip:String
        var port:String
        var modeVerbose:Bool = true
        // ...
        func fullIp() -> String {
            return "http://"+ip+":"+port
        }
        
        static func debugContext() -> Ctx {
            return Ctx(ip: "172.17.128.56", port: "4000")
        }
        
        static func newCtx() -> Ctx {
            return Ctx(ip: "172.17.128.56", port: "4000")
        }

    }
    
    static let instance = SocketIOManager()
    
    var manager:SocketManager? = nil
    var socket:SocketIOClient? = nil
        
    func setup() {
        manager = SocketManager(socketURL: URL(string: "http://192.168.2.1:4000")!)
        socket = manager?.defaultSocket
    }
    
    func setRoom() {
        manager = SocketManager(socketURL: URL(string: "http://172.17.128.134:4001")!)
        socket = manager?.defaultSocket
    }
    
    func connect(callBack:@escaping ()->()) {
        listenToConnection(callBack: callBack)
        socket?.connect()
    }
    
    func connectRoom(callBack:@escaping ()->()) {
        listenToConnection(callBack: callBack)
        socket?.connect()
    }
    
    func listenToConnection(callBack:@escaping ()->())  {
        socket?.on(clientEvent: .connect) {data, ack in
            callBack()
        }
    }
    
    func listenToChannel(channel:String,callBack:@escaping (String?)->())  {
        socket?.on(channel) {data, ack in
            
            if let d = data.first,
                let dataStr = d as? String {
               callBack(dataStr)
            }else{
               callBack(nil)
            }
            
            ack.with("Got your currentAmount", "dude")
        }
    }
    
    func writeValue(_ value:String,toChannel channel:String,callBack:@escaping ()->())  {
        socket?.emit(channel, value)
    }

}
