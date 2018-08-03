//
//  QuorumNode.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import Foundation


class QuorumManager {
    static var validators: [Validator] = []
    static func validatorForId(id: String) -> Validator? {
        for v in validators {
            if v.publicKey == id {
                return v
            }
        }
        return nil
    }
    static func handleForNodeId(id: String) -> String {
        for index in 0...validators.count {
            if validators[index].publicKey == id {
                return "\(index+1)"
            }
        }
        return "?"
    }
}


protocol QuorumNode {
    var identifier: String { get }
    var threshold: Int { get }
    var quorumNodes: [QuorumNode] { get }
    
    // TODO: Computed metrics of this node relative to root QuorumSet
    // Affect()
    // Required()
    // Influence()
    // do we need rootNode reference?
    // do we need parentNode reference?
    // is it helpful to have current depth?
    
    // Info about Quorum from this node through all children & subtrees
    var maxDepth: Int { get }
    var eventualValidators: Set<String> { get } // using public key for now -- later use object itself
    var leafValidators: Int { get } // count of all leaf validator nodes
}


class QuorumSet : QuorumNode {
    var hashKey: String! = ""
    
    // MARK: QuorumNode Protocol
    var quorumNodes: [QuorumNode] = []
    var threshold: Int = 0
    var identifier: String {
        return self.hashKey
    }
    var maxDepth: Int {
        var tempMax = 0
        for qn in self.quorumNodes {
            let qnMaxDepth = qn.maxDepth
            if qnMaxDepth + 1 > tempMax {
                tempMax = qnMaxDepth + 1
            }
        }
        return tempMax
    }
    var eventualValidators: Set<String> {
        var tempValidators: Set<String> = []
        for qn in self.quorumNodes {
            tempValidators.formUnion(qn.eventualValidators)
        }
        return tempValidators
    }
    var leafValidators: Int {
        var tempLeafs = 0
        for qn in self.quorumNodes {
            tempLeafs += qn.leafValidators
        }
        return tempLeafs
    }
    
    // MARK: Parsing
    class func nodeFromDictionary(dict: [String: AnyObject]?) -> QuorumSet? {
        let node: QuorumSet = QuorumSet()
        if dict == nil {
            //print("Empty quorum set :(")
            return node
        }
        node.hashKey = dict!["hashKey"] as! String
        node.threshold = dict!["threshold"] as! Int
        
        var tempQuorumNodes: [QuorumNode] = []
        
        // Validators
        for v in dict!["validators"] as! [String] {
            tempQuorumNodes.append(QuorumValidator.nodeFromPublicKey(publicKey: v)!)
        }
        
        // Inner Quorum Sets
        for iqs in dict!["innerQuorumSets"] as! [[String: AnyObject]] {
            tempQuorumNodes.append(nodeFromDictionary(dict: iqs)!)
        }
        
        node.quorumNodes = tempQuorumNodes
        return node
    }
}


class QuorumValidator : QuorumNode {
    var publicKey: String!
    
    // MARK: QuorumNode Protocol
    let quorumNodes: [QuorumNode] = []
    let threshold: Int = 0
    var identifier: String {
        return self.publicKey!
    }
    var maxDepth: Int {
        return 0
    }
    var eventualValidators: Set<String> {
        return [self.identifier]
    }
    var leafValidators: Int {
        return 1
    }
    
    // MARK: Parsing
    class func nodeFromPublicKey(publicKey: String) -> QuorumValidator? {
        let node: QuorumValidator = QuorumValidator()
        node.publicKey = publicKey
        return node
    }
}
