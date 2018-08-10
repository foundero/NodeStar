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
        for (index, validator) in validators.enumerated() {
            if validator.publicKey == id {
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
    var uniqueValidators: Set<String> { get } // using public key for now -- later use object itself
    var allValidatorsCount: Int { get } // count of all (leaf) validator nodes including dups
    
    // Impact Metrics
    func impactOfNode(subjectNode: QuorumNode) -> QuorumMetrics
}

struct QuorumMetrics {
    var combinations: Int = 0 // Combinations, given node truthiness
    var truthsGivenNodeTrue: Int = 0
    var truthsGivenNodeFalse: Int = 0
    var falsesGivenNodeTrue: Int { return combinations - truthsGivenNodeTrue }
    var falsesGivenNodeFalse: Int { return combinations - truthsGivenNodeFalse }
    
    var effected: Int {
        return truthsGivenNodeTrue + falsesGivenNodeFalse - combinations
    }
    var affect: Double {
        return Double(effected) / Double(combinations)
    }
    var require: Double {
        return Double(effected) / Double(truthsGivenNodeTrue)
    }
    var influence: Double {
        return Double(effected) / Double(falsesGivenNodeFalse)
    }
    
    static func percentString(value: Double) -> String {
        return String(format: "%.0f",value*100) + "%"
    }
    static func ratioString(value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value))!
    }
}

class QuorumSet : QuorumNode {
    var hashKey: String! = ""
    
    // MARK: QuorumNode Protocol
    var quorumNodes: [QuorumNode] = []
    var threshold: Int = 0
    var identifier: String {
        return hashKey
    }
    var maxDepth: Int {
        var tempMax = 0
        for qn in quorumNodes {
            let qnMaxDepth = qn.maxDepth
            if qnMaxDepth + 1 > tempMax {
                tempMax = qnMaxDepth + 1
            }
        }
        return tempMax
    }
    var uniqueValidators: Set<String> {
        var tempValidators: Set<String> = []
        for qn in quorumNodes {
            tempValidators.formUnion(qn.uniqueValidators)
        }
        return tempValidators
    }
    var allValidatorsCount: Int {
        var tempLeafs = 0
        for qn in quorumNodes {
            tempLeafs += qn.allValidatorsCount
        }
        return tempLeafs
    }
    
    func progeny(progenyIdentifier: String) -> QuorumNode? {
        for node in quorumNodes {
            if node.identifier == progenyIdentifier {
                return node
            }
            for innerNode in node.quorumNodes {
                if let innerQS = innerNode as? QuorumSet {
                    if let progeny = innerQS.progeny(progenyIdentifier: progenyIdentifier) {
                        return progeny
                    }
                }
            }
        }
        return nil
    }
    
    // Here we calculate the impact of a node on this node's truthiness. In general
    // it's most useful to look at the impact of a node on the root qs of a validator
    // but note that we call this method recursively so intermediate values are useful
    // and cached during the calculation.
    //
    // NOTE: This may not work if a non-root validator node is repeated somewhere in the full quorum set.
    // but there are not currently any instances of this as seen on the home summary screen that
    // there are 0 duplicate references under the Quorum Set Validator Resuse section
    //
    // PERFORMANCE:
    //
    // We've documented 4 ways to calculate the Affect, Require and Influence metrics.
    // General: computed t/f for every combination (2^N)
    // Recursive: for each quorumset level compute t/f for every combination (2^N-nodes-per-qs)
    // Recursive/Binomial Hybrid: for each quorumset level compute t/f for every combination of sub qs node
    //     and use binomial combinations for the validator leafs. (2^N-qs-nodes-per-qs)
    // Binomial: Only works if there is no inner quorum set - simply use binomial combinations
    //
    // We use caching to avoid recomputing the recursive bits
    private var quorumMetricsCache: [String:QuorumMetrics] = [:]
    func impactOfNode(subjectNode: QuorumNode) -> QuorumMetrics {
        // Check Cache
        if quorumMetricsCache[subjectNode.identifier] != nil {
            return quorumMetricsCache[subjectNode.identifier]!
        }
        
        var metrics = QuorumMetrics()
        
        // Impact of self on self is identity metrics
        if identifier == subjectNode.identifier {
            metrics.combinations = 1
            metrics.truthsGivenNodeTrue = 1
            metrics.truthsGivenNodeFalse = 0
            return metrics
        }
        
        // Split leafs from inner qs at this level and remove subject validator
        var validatorNodes: [QuorumNode] = []
        var quorumSetNodes: [QuorumNode] = []
        var includesSubjectValidator: Int = 0
        for node in quorumNodes {
            if node.identifier == subjectNode.identifier {
                includesSubjectValidator = 1
            }
            else if node is QuorumSet {
                quorumSetNodes.append(node)
            }
            else {
                validatorNodes.append(node)
            }
        }
        
        // Combinations
        metrics.combinations = 2 << (validatorNodes.count-1) // AKA 2^(n) -- note the extra -1
        for qsNode in quorumSetNodes {
            metrics.combinations *= qsNode.impactOfNode(subjectNode: subjectNode).combinations
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
                var truthsGivenNodeTrue = 0
                var truthsGivenNodeFalse = 0
                
                // Given validator true
                if trueQSNodes + trueValidators + includesSubjectValidator >= threshold {
                    truthsGivenNodeTrue = binomialTerm
                }
                // Given validator false
                if trueQSNodes + trueValidators >= threshold {
                    truthsGivenNodeFalse = binomialTerm
                }
                
                // Now multiply out the qsNodes
                for (qsIndex, qsNode) in quorumSetNodes.enumerated() {
                    let innerMetrics = qsNode.impactOfNode(subjectNode: subjectNode) // Recursion
                    
                    if i & 2<<(qsIndex-1) > 0 { // Truth of qsNode[qsIndex]
                        // qs node in question is true
                        truthsGivenNodeTrue *= innerMetrics.truthsGivenNodeTrue
                        truthsGivenNodeFalse *= innerMetrics.truthsGivenNodeFalse
                    }
                    else { // qs is false
                        truthsGivenNodeTrue *= innerMetrics.falsesGivenNodeTrue
                        truthsGivenNodeFalse *= innerMetrics.falsesGivenNodeFalse
                    }
                }
                metrics.truthsGivenNodeTrue += truthsGivenNodeTrue
                metrics.truthsGivenNodeFalse += truthsGivenNodeFalse
            }
        }
        
        // Cache it
        quorumMetricsCache[subjectNode.identifier] = metrics
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
        return publicKey!
    }
    var maxDepth: Int {
        return 0
    }
    var uniqueValidators: Set<String> {
        return [identifier]
    }
    var allValidatorsCount: Int {
        return 1
    }
    
    func impactOfNode(subjectNode: QuorumNode) -> QuorumMetrics {
        if subjectNode.identifier == self.identifier {
            return QuorumMetrics(combinations: 1,
                                 truthsGivenNodeTrue: 1,
                                 truthsGivenNodeFalse: 0)
        }
        else {
            return QuorumMetrics(combinations: 2,
                                 truthsGivenNodeTrue: 1,
                                 truthsGivenNodeFalse: 1)
        }
    }
    
    // MARK: Parsing
    class func nodeFromPublicKey(publicKey: String) -> QuorumValidator? {
        let node: QuorumValidator = QuorumValidator()
        node.publicKey = publicKey
        return node
    }
}
