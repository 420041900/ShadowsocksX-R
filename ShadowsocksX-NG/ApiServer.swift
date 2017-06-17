//
//  ApiServer.swift
//  ShadowsocksX-R
//
//  Created by CYC on 2016/10/9.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation
import GCDWebServer



class ApiMgr{
    static let shard = ApiMgr()
    
    let apiserver = GCDWebServer()
    let SerMgr = ServerProfileManager.instance
    let defaults = UserDefaults.standard
    let appdeleget = NSApplication.shared().delegate as! AppDelegate
    let api_port:UInt = 9528
    
    func start(){
        setRouter()
        do{
            try apiserver?.start(options: [GCDWebServerOption_Port:api_port,"BindToLocalhost":true])
        }catch{
            NSLog("Error:ApiServ start fail")
        }
    }
    
    func setRouter(){
        apiserver?.addHandler(forMethod: "GET", path: "/servers", request: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse(jsonObject: self.serverList())
        })
        
        apiserver?.addHandler(forMethod: "POST", path: "/toggle", request: GCDWebServerRequest.self, processBlock: {request in
            self.toggle()
            return GCDWebServerDataResponse(jsonObject: ["Status":1])
        })
        
        apiserver?.addHandler(forMethod: "POST", path: "/mode", request: GCDWebServerURLEncodedFormRequest.self, processBlock: {request in
            if let arg = ((request as! GCDWebServerURLEncodedFormRequest).arguments["value"])as? String
            {
                switch arg{
                case "auto":self.defaults.setValue("auto", forKey: "ShadowsocksRunningMode")
                case "global":self.defaults.setValue("global", forKey: "ShadowsocksRunningMode")
                case "manual":self.defaults.setValue("manual", forKey: "ShadowsocksRunningMode")
                case "bypasschina":self.defaults.setValue("bypasschina", forKey: "ShadowsocksRunningMode")
                default:return GCDWebServerDataResponse(jsonObject: ["Status":0])
                }
                DispatchQueue.main.async(execute: {
                    self.appdeleget.updateRunningModeMenu()
                });
                return GCDWebServerDataResponse(jsonObject: ["Status":1])
            }
            return GCDWebServerDataResponse(jsonObject: ["Status":0])
        })
        
        apiserver?.addHandler(forMethod: "GET", path: "/mode", request: GCDWebServerRequest.self, processBlock: {request in
            if let current = self.defaults.string(forKey: "ShadowsocksRunningMode"){
                return GCDWebServerDataResponse(jsonObject: ["mode":current])
            }
            return GCDWebServerDataResponse(jsonObject: ["mode":"unknow"])
        })
        
        apiserver?.addHandler(forMethod: "GET", path: "/status", request: GCDWebServerRequest.self, processBlock: {request in
            let current = self.defaults.bool(forKey: "ShadowsocksOn")
            return GCDWebServerDataResponse(jsonObject: ["enable":current])
        })
        
        apiserver?.addHandler(forMethod: "POST", path: "/servers", request: GCDWebServerURLEncodedFormRequest.self, processBlock: {request in
            let uuid = ((request as! GCDWebServerURLEncodedFormRequest).arguments["uuid"])as? String
            if uuid == nil{return GCDWebServerDataResponse(jsonObject: ["status":0])}
            print(uuid)
            self.changeServ(uuid!)
            return GCDWebServerDataResponse(jsonObject: ["status":1])
        })
    }
    
    func serverList()->NSArray{
        var data = [[String:String]]()
        for each in self.SerMgr.profiles{
            data.append(["id":each.uuid,"note":each.remark])
        }
        return data as NSArray
    }
    
    func toggle(){
        var isOn = self.defaults.bool(forKey: "ShadowsocksOn")
        isOn = !isOn
        self.defaults.set(isOn, forKey: "ShadowsocksOn")
        appdeleget.applyConfig()
        DispatchQueue.main.async(execute: {
            self.appdeleget.updateMainMenu()
        });
    }
    
    func changeServ(_ uuid:String){
        for each in SerMgr.profiles{
            if each.uuid == uuid{
                print("checked!")
                SerMgr.setActiveProfiledId(uuid)
                appdeleget.updateServersMenu()
                SyncSSLocal()
                return
            }
        }
    }
}
