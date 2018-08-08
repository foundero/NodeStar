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
    
    var validator: Validator!
    
    // MARK -- View Controller Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Validator - " + QuorumManager.handleForNodeId(id: validator.publicKey)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        updateWithModel(validator: validator)
    }
    
    func updateWithModel(validator: Validator) {
        var raw: [String: Any] = validator.rawData
        raw["quorumSet"] = nil
        dataLabel?.text = "\(raw as AnyObject)"
    }
    
    @IBAction func tapQuorumSetButton() {
        let vc = QuorumVC.newVC()
        vc.validator = validator
        navigationController?.pushViewController(vc, animated: true)
    }
}

