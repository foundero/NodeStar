//
//  ClusterDetailVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/15/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//


import UIKit

class ClusterDetailVC: UITableViewController {
    var cluster: Cluster!
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Cluster"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
    
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.rowHeight = ValidatorCell.desiredHieght
        ValidatorCell.registerWithTableView(tableView: tableView)
    }
    
    // MARK: Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = ["Validators in Cluster", "Incoming Validators", "Outgoing Validators"]
        return title[section]
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionValidators[section].count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ValidatorCell.dequeFromTableView(tableView: tableView, indexPath: indexPath)
        let validator = sectionValidators[indexPath.section][indexPath.row]
        
        if QuorumManager.validatorForId(id: validator.publicKey) != nil {
            cell.accessoryType = .disclosureIndicator
        }
        else {
            // Unknown Validator
            cell.accessoryType = .none
        }
        cell.updateWithModel(validator: validator)
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let validator = sectionValidators[indexPath.section][indexPath.row]
        if QuorumManager.validatorForId(id: validator.publicKey) != nil {
            let vc = QuorumVC.newVC()
            vc.validator = validator
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ValidatorCell.desiredHieght
    }
    lazy private var sectionValidators: [[Validator]] = {
        var tempSectionValidators: [[Validator]] = []
        tempSectionValidators.append(orderedValidatorsForSet(set: cluster.nodes))
        tempSectionValidators.append(orderedValidatorsForSet(set: cluster.incoming))
        tempSectionValidators.append(orderedValidatorsForSet(set: cluster.outgoing))
        return tempSectionValidators
    }()
    private func orderedValidatorsForSet(set: Set<String>) -> ([Validator]) {
        var validators: [Validator] = []
        var unknownValidators: [Validator] = []
        for publicKey in set {
            if let validator = QuorumManager.validatorForId(id: publicKey) {
                validators.append(validator)
            }
            else {
                let validator = Validator()
                validator.publicKey = publicKey
                unknownValidators.append(validator)
            }
        }
        validators = QuorumManager.sortedValidators(validatorsToSort: validators)
        unknownValidators = QuorumManager.sortedValidators(validatorsToSort: unknownValidators)
        validators.append(contentsOf: unknownValidators)
        return validators
    }
}

