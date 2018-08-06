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
    
    // Info about Quorum from this node through all children & subtrees
    var maxDepth: Int { get }
    var eventualValidators: Set<String> { get } // using public key for now -- later use object itself
    var leafValidators: Int { get } // count of all leaf validator nodes
    
    // Impact Metrics
    func quorumMetricsForNode(node: QuorumNode) -> QuorumMetrics
}

struct QuorumMetrics {
    var combinations: Int = 0 // Combinations, given Validator truthiness aka 2^(othervalidators-1)
    var truthsGivenValidatorTrue: Int = 0
    var truthsGivenValidatorFalse: Int = 0
    var falsesGivenValidatorTrue: Int { return combinations - truthsGivenValidatorTrue }
    var falsesGivenValidatorFalse: Int { return combinations - truthsGivenValidatorFalse }
    
    var validatorEffected: Int {
        return truthsGivenValidatorTrue + falsesGivenValidatorFalse - combinations
    }
    var validatorAffect: Double {
        return Double(validatorEffected) / Double(combinations)
    }
    var validatorRequire: Double {
        return Double(validatorEffected) / Double(truthsGivenValidatorTrue)
    }
    var validatorInfluence: Double {
        return Double(validatorEffected) / Double(falsesGivenValidatorFalse)
    }
    
    func printMetrics() {
        var b = String(format: "%.0f",validatorAffect*100)
        var c = String(format: "%.0f",validatorRequire*100)
        var d = String(format: "%.0f",validatorInfluence*100)
        print("Effected: \(validatorEffected)")
        print("Affect: \(b)%")
        print("Require: \(c)%")
        print("Influence: \(d)%")
    }
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
    
    private var quorumMetricsCache: [String:QuorumMetrics] = [:]
    func quorumMetricsForNode(node: QuorumNode) -> QuorumMetrics {
        // Check Cache
        if quorumMetricsCache[node.identifier] != nil {
            return quorumMetricsCache[node.identifier]!
        }
        
        var metrics = QuorumMetrics()
        
        // Split leafs from inner qs at this level and remove subject validator
        var validatorNodes: [QuorumNode] = []
        var quorumSetNodes: [QuorumNode] = []
        var includesSubjectValidator: Int = 0
        for quorumNode in self.quorumNodes {
            if quorumNode.identifier == node.identifier {
                includesSubjectValidator = 1
            }
            else if quorumNode is QuorumSet {
                quorumSetNodes.append(quorumNode)
            }
            else {
                validatorNodes.append(quorumNode)
            }
        }
        
        // Combinations
        metrics.combinations = 2 << (validatorNodes.count-1) // AKA 2^(n) -- note the extra -1
        for qsNode in quorumSetNodes {
            metrics.combinations *= qsNode.quorumMetricsForNode(node: node).combinations
        }
        
        // For all combinations of qs nodes t/f -- represented by bits in i
        for i in UInt(0)...(UInt(2)<<(quorumSetNodes.count-1) - UInt(1)) {
            let trueQSNodes = bitcount(n: i)
            var neededValidators = threshold - trueQSNodes - includesSubjectValidator
            if neededValidators < 0 {
                neededValidators = 0
            }
            if neededValidators > validatorNodes.count {
                continue
            }
            for trueValidators in neededValidators...validatorNodes.count {
                let binomialTerm: Int = binomial(n: validatorNodes.count, k: trueValidators)
                var truthsGivenValidatorTrue = 0
                var falsesGivenValidatorFalse = 0
                
                // Given validator true
                if trueQSNodes + trueValidators + includesSubjectValidator >= threshold {
                    truthsGivenValidatorTrue = binomialTerm
                }
                // Given validator false
                if trueQSNodes + trueValidators >= threshold {
                    falsesGivenValidatorFalse = binomialTerm
                }
                
                // Now multiply out the qsNodes
                for (qsIndex, qsNode) in quorumSetNodes.enumerated() {
                    let innerMetrics = qsNode.quorumMetricsForNode(node: node) // Recursion
                    
                    if i & 2<<(qsIndex-1) > 0 { // Truth of qsNode[qsIndex]
                        // qs node in question is true
                        truthsGivenValidatorTrue *= innerMetrics.truthsGivenValidatorTrue
                        falsesGivenValidatorFalse *= innerMetrics.truthsGivenValidatorFalse
                    }
                    else { // qs is false
                        truthsGivenValidatorTrue *= innerMetrics.falsesGivenValidatorTrue
                        falsesGivenValidatorFalse *= innerMetrics.falsesGivenValidatorFalse
                    }
                }
                metrics.truthsGivenValidatorTrue += truthsGivenValidatorTrue
                metrics.truthsGivenValidatorFalse += falsesGivenValidatorFalse
            }
        }
        
        // Cache it
        quorumMetricsCache[node.identifier] = metrics
        return metrics
    }
    
    // MARK: Private utils
    private func binomial(n: Int, k: Int) -> Int {
        precondition(k >= 0 && n >= 0)
        if (k > n) { return 0 }
        var result = 1
        for i in 0 ..< min(k, n-k) {
            result = (result * (n - i))/(i + 1)
        }
        return result
    }
    private func bitcount(n: UInt) -> Int {
        var tempN = n
        var count: Int = 0
        while tempN != 0 {
            tempN = tempN & (tempN-1)
            count += 1
        }
        return count
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
    
    func quorumMetricsForNode(node: QuorumNode) -> QuorumMetrics {
        if node.identifier == self.identifier {
            return QuorumMetrics(combinations: 1,
                                 truthsGivenValidatorTrue: 1,
                                 truthsGivenValidatorFalse: 0)
        }
        else {
            return QuorumMetrics(combinations: 2,
                                 truthsGivenValidatorTrue: 1,
                                 truthsGivenValidatorFalse: 1)
        }
    }
    
    // MARK: Parsing
    class func nodeFromPublicKey(publicKey: String) -> QuorumValidator? {
        let node: QuorumValidator = QuorumValidator()
        node.publicKey = publicKey
        return node
    }
}
