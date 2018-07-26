//
//  ValidatorCell.swift
//  NodeStar
//
//  Created by jeff on 7/26/18.
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
    @IBOutlet weak var leafsLabel: UILabel?
    @IBOutlet weak var depthLabel: UILabel?
    
    class var desiredHieght: CGFloat {
        return 72.0
    }
    
    open func updateWithModel(validator: Validator) {
        self.nameLabel?.text = "\(QuorumManager.handleForNodeId(id: validator.publicKey)). \(validator.name ?? "")"
        self.cityLabel?.text = validator.city ?? "[City]"
        self.publicKeyLabel?.text = validator.publicKey
        self.verifiedCheckmark?.isHidden = !validator.verified
        
        self.nodesLabel?.text = "n=\(validator.quorumSet.eventualValidators.count)"
        self.leafsLabel?.text = "l=\(validator.quorumSet.leafValidators)"
        self.depthLabel?.text = "d=\(validator.quorumSet.maxDepth)"
        let thresholdString = "\(validator.quorumSet.threshold)/\(validator.quorumSet.quorumNodes.count)"
        if ( validator.quorumSet.maxDepth ) > 1 {
            self.rootThresholdLabel?.text = "*" + thresholdString
        }
        else {
            self.rootThresholdLabel?.text = thresholdString
        }
    }
}
