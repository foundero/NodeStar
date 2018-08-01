//
//  ValidatorDetailVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ValidatorDetailVC: UIViewController {

    @IBOutlet weak var dataLabel: UILabel?
    
    var node: Validator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Validator Detail"
        updateWithModel(node: self.node)
    }
    
    func updateWithModel(node: Validator) {
        dataLabel?.text = "Public Key: \(node.publicKey)\n\n"
            + "IP: \(node.ip)\n\n"
            + "City: \(node.city as String?)\n\n"
            + "Lat: \(node.latitude as String?)\n\n"
            + "Long: \(node.longitude as String?)\n\n"
            + "Host: \(node.host as String?)\n\n"
            + "Name: \(node.name as String?)\n\n"
            + "Verified: \(node.verified)\n\n"
    }
}

