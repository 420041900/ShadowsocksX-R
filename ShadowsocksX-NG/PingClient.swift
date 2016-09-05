//
//  PingClient.swift
//  ShadowsocksX-R
//
//  Created by 称一称 on 16/9/5.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//


import Foundation

public typealias SimplePingClientCallback = (String?)->()

public class SimplePingClient: NSObject {
    static let singletonPC = SimplePingClient()

    private var resultCallback: SimplePingClientCallback?
    private var pingClinet: SimplePing?
    private var dateReference: NSDate?

    public static func pingHostname(hostname: String, andResultCallback callback: SimplePingClientCallback?) {
        singletonPC.pingHostname(hostname, andResultCallback: callback)
    }

    public func pingHostname(hostname: String, andResultCallback callback: SimplePingClientCallback?) {
        resultCallback = callback
        pingClinet = SimplePing(hostName: hostname)
        pingClinet?.delegate = self
        pingClinet?.start()
    }
}

extension SimplePingClient: SimplePingDelegate {
    public func simplePing(pinger: SimplePing, didStartWithAddress address: NSData) {
        pinger.sendPingWithData(nil)


    }

    public func simplePing(pinger: SimplePing, didFailWithError error: NSError) {
        resultCallback?(nil)
    }

    public func simplePing(pinger: SimplePing, didSendPacket packet: NSData, sequenceNumber: UInt16) {
        dateReference = NSDate()
    }

    public func simplePing(pinger: SimplePing, didFailToSendPacket packet: NSData, sequenceNumber: UInt16, error: NSError) {
        pinger.stop()
        resultCallback?(nil)
    }

    public func simplePing(pinger: SimplePing, didReceiveUnexpectedPacket packet: NSData) {
        pinger.stop()
        resultCallback?(nil)
    }

    public func simplePing(pinger: SimplePing, didReceivePingResponsePacket packet: NSData, sequenceNumber: UInt16 ){
        pinger.stop()

        guard let dateReference = dateReference else {
            print("fail")
            return }

        //timeIntervalSinceDate returns seconds, so we convert to milis
        let latency = NSDate().timeIntervalSinceDate(dateReference) * 1000
        resultCallback?(String(format: "%.f", latency))
    }
}



