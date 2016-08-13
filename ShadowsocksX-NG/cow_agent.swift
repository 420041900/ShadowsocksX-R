//
//  cow_agent.swift
//  ShadowsocksX-R
//
//  Created by 称一称 on 16/8/12.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Foundation


let cow_plist_name = "com.yicheng.ShadowsocksX-R.cow.plist"

func generateCowLauchAgentPlist() -> Bool {
    let cow_path = NSBundle.mainBundle().pathForResource("cow", ofType: nil)
    let cow_dir  = NSBundle.mainBundle().resourcePath

    let launchAgentDirPath = NSHomeDirectory() + LAUNCH_AGENT_DIR
    let plistFilepath = launchAgentDirPath + cow_plist_name

    // Ensure launch agent directory is existed.
    let fileMgr = NSFileManager.defaultManager()
    if !fileMgr.fileExistsAtPath(launchAgentDirPath) {
        try! fileMgr.createDirectoryAtPath(launchAgentDirPath, withIntermediateDirectories: true, attributes: nil)
    }

    let dict: NSMutableDictionary = [
        "Label": "com.yicheng.ShadowsocksX-R.cow",
        "WorkingDirectory": cow_dir!,
        "KeepAlive": true,
        "ProgramArguments": [cow_path!],
    ]

    dict.writeToFile(plistFilepath, atomically: true)


// write config file

    let cow_conf_dir = NSHomeDirectory() + "/.cow"
    if !fileMgr.fileExistsAtPath(cow_conf_dir) {
        try! fileMgr.createDirectoryAtPath(cow_conf_dir, withIntermediateDirectories: true, attributes: nil)
    }

    let defaults = NSUserDefaults.standardUserDefaults()
    let socks5Port = defaults.integerForKey("LocalSocks5.ListenPort")
    let config_path = NSBundle.mainBundle().pathForResource("cow", ofType: "conf")
    let config = NSData(contentsOfFile: config_path!)
    var config_str = String(data: config!,encoding: NSUTF8StringEncoding)!
    config_str = config_str.stringByReplacingOccurrencesOfString("__PROT__", withString: "\(socks5Port)")
        config_str = config_str.stringByReplacingOccurrencesOfString("__COWPORT__", withString: "7777")
    do{
        try config_str.dataUsingEncoding(NSUTF8StringEncoding)?.writeToFile(NSHomeDirectory() + "/.cow/rc", options: .DataWritingAtomic)
    }catch{
        print("write cow conf fail")
        return false
    }
    StartCow()
    return true
}


func ReloadCow() {
    let bundle = NSBundle.mainBundle()
    let installerPath = bundle.pathForResource("cow.sh", ofType: nil)
    let task = NSTask.launchedTaskWithLaunchPath(installerPath!, arguments: ["reload"])
    task.waitUntilExit()


    if task.terminationStatus == 0 {
        NSLog("Start cow succeeded.")
    } else {
        NSLog("Start cow failed.")
    }
}

func StartCow() {
    let bundle = NSBundle.mainBundle()
    let installerPath =   bundle.pathForResource("cow", ofType: "sh")
    let task = NSTask.launchedTaskWithLaunchPath(installerPath!, arguments: ["start"])
    task.waitUntilExit()
    CowReloader.shard.start()
    if task.terminationStatus == 0 {
        NSLog("Start cow succeeded.")
    } else {
        NSLog("Start cow failed.")
    }
}

func StopCow() {
    CowReloader.shard.end()
    let bundle = NSBundle.mainBundle()
    let installerPath = bundle.pathForResource("cow.sh", ofType: nil)
    let task = NSTask.launchedTaskWithLaunchPath(installerPath!, arguments: ["stop"])
    task.waitUntilExit()
    if task.terminationStatus == 0 {
        NSLog("Stop cow succeeded.")
    } else {
        NSLog("Stop cow failed.")
    }
}

func test(){
    print("test")
}


class CowReloader:NSObject {
    static let shard = CowReloader()
    var timer:NSTimer?

    func start(){
        timer = NSTimer.scheduledTimerWithTimeInterval(18000, target: self, selector: #selector(CowReloader.restart_cow), userInfo: nil, repeats: true)
    }

    func restart_cow(){
        ReloadCow()
    }

    func end(){
        timer?.invalidate()
        timer = nil
    }


}
