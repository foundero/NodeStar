//
//  ValidatorCell.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ValidatorCell: UITableViewCell {
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedCheckmark: UIView!
    @IBOutlet weak var publicKeyLabel: UILabel!
    @IBOutlet weak var quorumSetHashLabel: UILabel!
    @IBOutlet weak var rootThresholdLabel: UILabel!
    @IBOutlet weak var nodesLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var usagesLabel: UILabel!
    
    class var desiredHieght: CGFloat {
        return 72.0
    }
    
    open func updateClear() {
        nameLabel.text = ""
        cityLabel.text = ""
        publicKeyLabel.text = ""
        quorumSetHashLabel.text = ""
        verifiedCheckmark.isHidden = true
        rootThresholdLabel.text = ""
        nodesLabel.text = ""
        depthLabel.text = ""
        usagesLabel.text = ""
    }
    
    open func updateWithModel(validator: Validator) {
        nameLabel.text = "\(QuorumManager.handleForNodeId(id: validator.publicKey)). \(validator.name ?? "")"
        cityLabel.text = validator.city ?? "[City]"
        publicKeyLabel.text = "pk: " + validator.publicKey
        quorumSetHashLabel.text = "qsh: " + validator.quorumSet.hashKey
        verifiedCheckmark.isHidden = !validator.verified
        
        if validator.quorumSet == nil {
            rootThresholdLabel.text = "?/?"
            nodesLabel.text = "n=?,?"
            depthLabel.text = "d=?"
        }
        else {
            nodesLabel.text = "n=\(validator.quorumSet.uniqueValidators.count),\(validator.uniqueEventualValidators.count)"
            depthLabel.text = "d=\(validator.quorumSet.maxDepth)"
            let thresholdString = "\(validator.quorumSet.threshold)/\(validator.quorumSet.quorumNodes.count)"
            if ( validator.quorumSet.maxDepth ) > 1 {
                rootThresholdLabel.text = "*" + thresholdString
            }
            else {
                rootThresholdLabel.text = thresholdString
            }
        }
        usagesLabel.text = "u=\(validator.uniqueDependents.count),\(validator.uniqueEventualDependents.count)"
    }
    open func updateWithModel(node: QuorumNode) {
        // Limited QuorumNode (QuorumSet or ValidatorNode) info
        if node is QuorumValidator {
            publicKeyLabel.text = "pk: " + node.identifier
            if nameLabel.text == "" {
                nameLabel.text = "?. Unkonwn Validator"
            }
        }
        else {
            quorumSetHashLabel.text = "qsh: " + node.identifier
            if nameLabel.text == "" {
                nameLabel.text = "Quorum Set"
            }
        }
             
        let thresholdString = "\(node.threshold)/\(node.quorumNodes.count)"
        if ( node.maxDepth ) > 1 {
            rootThresholdLabel.text = "*" + thresholdString
        }
        else {
            rootThresholdLabel.text = thresholdString
        }
    }
    
    class func registerWithTableView(tableView: UITableView) {
        tableView.register(UINib(nibName: "ValidatorCell", bundle: nil), forCellReuseIdentifier: "ValidatorCell")
    }
    class func dequeFromTableView(tableView: UITableView, indexPath: IndexPath) -> ValidatorCell {
        return tableView.dequeueReusableCell(withIdentifier: "ValidatorCell",
                                                                for: indexPath) as! ValidatorCell
    }
}
