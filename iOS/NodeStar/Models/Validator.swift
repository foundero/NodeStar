//
//  Validator.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import Foundation

class Validator {
    
    var publicKey: String! = ""
    var ip: String! = ""
    var city: String?
    var latitude: String?
    var longitude: String?
    var name: String?
    var host: String?
    var verified: Bool! = false
    
    var quorumSet: QuorumSet!

    var rawData: [String: Any]!
    
    // TODO: Computed Metrics from QuorumSet
    // Is it safe? stellar core has some way of computing this
    
    class func nodeFromDictionary(dict: [String: AnyObject]) -> Validator? {
        let node: Validator = Validator()
        node.publicKey = dict["publicKey"] as! String
        node.ip = dict["ip"] as! String
        node.city = dict["city"] as? String
        node.latitude = dict["latitude"] as? String
        node.longitude = dict["longitude"] as? String
        node.name = dict["name"] as? String
        node.host = dict["host"] as? String
        node.verified = dict["verified"] as! Bool
        
        // stellarbeat.io returns empty string -- we'd rather have nil
        if node.ip == "" { node.ip = nil }
        if node.city == "" { node.city = nil }
        if node.latitude == "" { node.latitude = nil }
        if node.longitude == "" { node.longitude = nil }
        if node.name == "" { node.name = nil }
        if node.host == "" { node.host = nil }
        
        // recursively parse the QuorumSet as QuorumNodes (QuorumSet, QuorumValidator)
        let parsedQuorumSet = QuorumSet.nodeFromDictionary(dict: dict["quorumSet"] as? [String: AnyObject])
        node.quorumSet = parsedQuorumSet ?? QuorumSet()
        
        node.rawData = dict
        
        return node
    }
}
