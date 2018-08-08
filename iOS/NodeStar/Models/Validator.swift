//
//  Validator.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import Foundation

class Validator {
    
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssz"
        return dateFormatter
    }()
    
    var publicKey: String! = ""
    var ip: String! = ""
    var city: String?
    var latitude: String?
    var longitude: String?
    var name: String?
    var host: String?
    var verified: Bool! = false
    var updatedAt: Date!
    
    var quorumSet: QuorumSet!

    var rawData: [String: Any]!
    
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
        node.updatedAt = dateFormatter.date(from: dict["updated_at"] as! String + "z")
        
        // stellarbeat.io returns empty string -- we'd rather have nil
        if node.ip == "" { node.ip = nil }
        if node.city == "" { node.city = nil }
        if node.latitude == "" { node.latitude = nil }
        if node.longitude == "" { node.longitude = nil }
        if node.name == "" { node.name = nil }
        if node.host == "" { node.host = nil }
        
        // recursively parse the QuorumSet as QuorumNodes (QuorumSet, QuorumValidator)
        let parsedQuorumSet = QuorumSet.nodeFromDictionary(dict: dict["quorumSet"] as? [String: AnyObject])
        node.quorumSet = parsedQuorumSet
        
        node.rawData = dict
        
        return node
    }
    
    // Return number of validators (including self) that use this validator in their quorum set
    func usagesInValidatorQuorumSets() -> Int {
        var usages: Int = 0
        for validator in QuorumManager.validators {
            if validator.quorumSet.uniqueValidators.contains(publicKey) {
                usages += 1
            }
        }
        return usages
    }
}
