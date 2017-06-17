//
//  ServerProfile.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

import Cocoa



class ServerProfile: NSObject {
    var uuid: String
    
    var serverHost: String = ""
    var serverPort: uint16 = 8379
    var method:String = "aes-128-cfb"
    var password:String = ""
    var remark:String = ""


    var obfs:String = "plain"
    var obfspara:String = ""
    var protocols:String = "origin"

    var latency:String?

    override init() {
        uuid = UUID().uuidString
    }
    
    init(uuid: String) {
        self.uuid = uuid
    }
    
    static func fromDictionary(_ data:[String:AnyObject]) -> ServerProfile {
        let cp = {
            (profile: ServerProfile) in
            profile.serverHost = data["ServerHost"] as! String
            profile.serverPort = (data["ServerPort"] as! NSNumber).uint16Value
            profile.method = data["Method"] as! String
            profile.password = data["Password"] as! String

            profile.obfs = data["obfs"] as! String
            profile.protocols = data["protocol"] as! String

            if let remark = data["Remark"] {
                profile.remark = remark as! String
            }

            if let obfspara = data["obfspara"] {
                profile.obfspara = obfspara as! String
            }

        }
        
        if let id = data["Id"] as? String {
            let profile = ServerProfile(uuid: id)
            cp(profile)
            return profile
        } else {
            let profile = ServerProfile()
            cp(profile)
            return profile
        }
    }
    
    func toDictionary() -> [String:AnyObject] {
        var d = [String:AnyObject]()
        d["Id"] = uuid as AnyObject
        d["ServerHost"] = serverHost as AnyObject
        d["ServerPort"] = NSNumber(value: serverPort as UInt16)
        d["Method"] = method as AnyObject
        d["Password"] = password as AnyObject
        d["Remark"] = remark as AnyObject
        d["obfs"] = obfs as AnyObject
        d["protocol"] = protocols as AnyObject
        d["obfspara"] = obfspara as AnyObject
//        d["OTA"] = ota
        return d
    }
    
    func toJsonConfig() -> [String: AnyObject] {
        var conf: [String: AnyObject] = ["server": serverHost as AnyObject,
                                         "server_port": NSNumber(value: serverPort as UInt16),
                                         "password": password as AnyObject,
                                         "method": method as AnyObject,
                                         "protocol":protocols as AnyObject,
                                         "obfs":obfs as AnyObject,
                                         "obfs_param":obfspara as AnyObject
                                         ]
        
        let defaults = UserDefaults.standard
        conf["local_port"] = NSNumber(value: UInt16(defaults.integer(forKey: "LocalSocks5.ListenPort")) as UInt16)
        conf["local_address"] = defaults.string(forKey: "LocalSocks5.ListenAddress") as AnyObject
        conf["timeout"] = NSNumber(value: UInt32(defaults.integer(forKey: "LocalSocks5.Timeout")) as UInt32)
//        conf["auth"] = NSNumber(bool: ota)

        return conf
    }
    
    func isValid() -> Bool {
        func validateIpAddress(_ ipToValidate: String) -> Bool {
            
            var sin = sockaddr_in()
            var sin6 = sockaddr_in6()
            
            if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
                // IPv6 peer.
                return true
            }
            else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
                // IPv4 peer.
                return true
            }
            
            return false;
        }
        
        func validateDomainName(_ value: String) -> Bool {
            let validHostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"
            
            if (value.range(of: validHostnameRegex, options: .regularExpression) != nil) {
                return true
            } else {
                return false
            }
        }
        
        if !(validateIpAddress(serverHost) || validateDomainName(serverHost)){
            return false
        }
        
        if password.isEmpty {
            return false
        }
        
        return true
    }

    func base64(_ string:String,url_safe:Bool=true)->String{

        var encode_str = string.data(using: String.Encoding.utf8)!.base64EncodedString(options: NSData.Base64EncodingOptions())
        if(url_safe){
            encode_str = encode_str.replacingOccurrences(of: "+", with: "-")
            encode_str = encode_str.replacingOccurrences(of: "/", with: "_")
            encode_str = encode_str.replacingOccurrences(of: "=", with: "");
        }
        return encode_str
    }
    
    func URL() -> Foundation.URL? {
//        服务器:端口:协议:加密方式:混淆方式:base64（密码）？obfsparam= Base64(混淆参数)&remarks=Base64(备注)
        if obfs == "plain" && protocols == "origin"{
            let parts = "\(method):\(password)@\(serverHost):\(serverPort)"
            return Foundation.URL(string: "ss://\(base64(parts,url_safe: false))")
        }
        let parts = "\(serverHost):\(serverPort):\(protocols):\(method):\(obfs):\(base64(password))?obfsparam=\(base64(obfspara))&remarks=\(base64(remark))"
            return Foundation.URL(string: "ssr://\(base64(parts))")
    }
}
