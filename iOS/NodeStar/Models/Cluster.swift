//
//  Cluster.swift
//  NodeStar
//
//  Created by JEFF DITULLIO on 8/15/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import Foundation


// Cluster: is a set of validators who all have exactly the same:
//   - eventual validators (set of nodes they eventually use)
//   - eventual dependents (set of nodes that eventually uses this)
class Cluster {
    var nodes: Set<String> = []
    var incoming: Set<String> = []
    var outgoing: Set<String> = []
    var outgoingClusters: [Cluster] = []
    
    init(validatorPublicKey: String) {
        if let v = QuorumManager.validatorForId(id: validatorPublicKey) {
            outgoing = v.uniqueEventualValidators
            incoming = v.uniqueEventualDependents
            nodes = [validatorPublicKey]
            outgoingClusters = []
        }
    }
    lazy var outgoingUnknown: Set<String> = {
        var tempOutgoing = outgoing
        for c in outgoingClusters {
            if c !== self {
                tempOutgoing.subtract(c.outgoing)
            }
            tempOutgoing.subtract(c.nodes)
        }
        return tempOutgoing
    }()
    lazy var incomingCountWithoutSelf: Int = {
        if outgoingClusters.contains(where: {$0===self}) {
            return incoming.count - nodes.count
        }
        return incoming.count
    }()
    
    class func buildClusters() -> [Cluster] {
        // Create the raw set of clusters
        var clusters: [Cluster] = []
        for v in QuorumManager.validators {
            let newCluster = Cluster.init(validatorPublicKey: v.publicKey)
            let matchedCluster = clusters.first(where: { (cluster) -> Bool in
                return newCluster.incoming == cluster.incoming && newCluster.outgoing == cluster.outgoing
            })
            if matchedCluster != nil {
                matchedCluster!.nodes.formUnion([v.publicKey])
            }
            else {
                clusters.append(newCluster)
            }
        }
        
        // Add the connections between clusters
        for i in clusters {
            var decendentClusters: [Cluster] = []
            for potentialDecendent in clusters {
                if i.outgoing.isSuperset(of: potentialDecendent.nodes) {
                    decendentClusters.append(potentialDecendent)
                }
            }
            for potentialChild in decendentClusters {
                // only add it if it's a child
                var isChild = true
                for j in decendentClusters {
                    if potentialChild === j || j === i {
                        continue
                    }
                    if j.outgoing.isSuperset(of: potentialChild.nodes) {
                        isChild = false
                        break
                    }
                }
                if isChild {
                    i.outgoingClusters.append(potentialChild)
                }
            }
        }
        
        // Order them
        clusters.sort {
            if $0.incomingCountWithoutSelf != $1.incomingCountWithoutSelf {
                return $0.incomingCountWithoutSelf < $1.incomingCountWithoutSelf
            }
            if $0.incoming.count != $1.incoming.count {
                return $0.incoming.count < $1.incoming.count
            }
            return $0.outgoing.count < $1.outgoing.count
        }
        return clusters
    }
    
    // Expects ordered list of clusters
    class func bestClusterIncomingCount(clusters: [Cluster]) -> Int {
        if clusters.last != nil {
            return clusters.last!.incoming.count
        }
        return 0
    }
}
