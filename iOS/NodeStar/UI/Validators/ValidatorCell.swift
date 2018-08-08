//
//  ValidatorCell.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ValidatorCell: UITableViewCell {
    
    @IBOutlet weak var cityLabel: UILabel?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var verifiedCheckmark: UIView?
    @IBOutlet weak var publicKeyLabel: UILabel?

    @IBOutlet weak var rootThresholdLabel: UILabel?
    @IBOutlet weak var nodesLabel: UILabel?
    @IBOutlet weak var depthLabel: UILabel?
    
    class var desiredHieght: CGFloat {
        return 72.0
    }
    
    open func updateWithModel(validator: Validator) {
        nameLabel?.text = "\(QuorumManager.handleForNodeId(id: validator.publicKey)). \(validator.name ?? "")"
        cityLabel?.text = validator.city ?? "[City]"
        publicKeyLabel?.text = "pk: " + validator.publicKey
        verifiedCheckmark?.isHidden = !validator.verified
        
        nodesLabel?.text = "n=\(validator.quorumSet.uniqueValidators.count)"
        depthLabel?.text = "d=\(validator.quorumSet.maxDepth)"
        let thresholdString = "\(validator.quorumSet.threshold)/\(validator.quorumSet.quorumNodes.count)"
        if ( validator.quorumSet.maxDepth ) > 1 {
            rootThresholdLabel?.text = "*" + thresholdString
        }
        else {
            rootThresholdLabel?.text = thresholdString
        }
    }
}
