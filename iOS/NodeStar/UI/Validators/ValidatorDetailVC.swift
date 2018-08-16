//
//  ValidatorDetailVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ValidatorDetailVC: UITableViewController {
    var validator: Validator!
    
    let actionKeys = ["Cluster", "Quorum Set", "Direct Outgoing Validators", "Indirect Outgoing Validators",
                      "Direct Incoming Validators", "Indirect Incoming Validators"]
    lazy var actionValues: [String] = {
        return ["",
                "n=\(validator.quorumSet.uniqueValidators.count),d=\(validator.quorumSet.maxDepth)",
                "n=\(validator.quorumSet.uniqueValidators.count)",
                "n'=\(validator.uniqueEventualValidators.count)",
                "u=\(validator.uniqueDependents.count)",
                "u'=\(validator.uniqueEventualDependents.count)"]
    }()
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Validator Detail"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        
        tableView.cellLayoutMarginsFollowReadableWidth = false
        ValidatorCell.registerWithTableView(tableView: tableView)
    }
    
    // MARK: Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        let title = ["","Explore", "Metadata"]
        return title[section]
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            return actionKeys.count
        }
        return validator.rawData.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = ValidatorCell.dequeFromTableView(tableView: tableView, indexPath: indexPath)
            cell.selectionStyle = .none
            cell.backgroundColor = nodeStarBlue.withAlphaComponent(0.3)
            cell.updateWithModel(validator: validator)
            return cell
        }
        else if indexPath.section == 1 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell")
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "ActionCell")
                cell!.tintColor = UIColor.black
                cell!.textLabel?.adjustsFontSizeToFitWidth = true
                cell!.textLabel?.minimumScaleFactor = 0.3
                cell!.detailTextLabel?.adjustsFontSizeToFitWidth = true
                cell!.detailTextLabel?.minimumScaleFactor = 0.3
                cell!.detailTextLabel?.textColor = nodeStarBlue
                cell!.detailTextLabel?.font = UIFont.systemFont(ofSize: 13.0)
                cell!.accessoryType = .disclosureIndicator
            }
            cell!.textLabel?.text = actionKeys[indexPath.row]
            cell!.detailTextLabel?.text = actionValues[indexPath.row]
            return cell!
        }
        else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "DataCell")
            if cell == nil {
                cell = UITableViewCell(style: UITableViewCellStyle.value2, reuseIdentifier: "DataCell")
                cell!.tintColor = UIColor.black
                cell!.textLabel?.adjustsFontSizeToFitWidth = true
                cell!.textLabel?.minimumScaleFactor = 0.3
                cell!.detailTextLabel?.adjustsFontSizeToFitWidth = true
                cell!.detailTextLabel?.minimumScaleFactor = 0.3
                cell!.detailTextLabel?.textColor = nodeStarBlue
                cell!.selectionStyle = .none
            }
            let index = validator.rawData.index(validator.rawData.startIndex, offsetBy: indexPath.row)
            let (key,value) = validator.rawData[index]
            cell!.textLabel?.text = key + ":"
            cell!.detailTextLabel?.text = "\(value)"
            return cell!
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Cluster
            let vc = ClusterVC.newVC()
            vc.clusters = QuorumManager.clusters
            vc.selectClusterForInitialValidator = validator
            navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.row == 1 {
            // Quorum Set
            let vc = QuorumVC.newVC()
            vc.validator = validator
            navigationController?.pushViewController(vc, animated: true)
        }
        else {
            // Rows 3-6
            let vc = ValidatorsVC.newVC()
            let handle = QuorumManager.handleForNodeId(id: validator.publicKey)
            vc.title = actionKeys[indexPath.row] + " of \(handle)"
            var set: Set<String>  = []
            if indexPath.row == 2 {
                set = validator.quorumSet.uniqueValidators
            }
            else if indexPath.row == 3 {
                set = validator.uniqueEventualValidators
            }
            else if indexPath.row == 4 {
                set = validator.uniqueDependents
            }
            else {
                set = validator.uniqueEventualDependents
            }
            vc.validators = QuorumManager.orderedValidatorsForPublicKeySet(set: set)
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

