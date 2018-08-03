//
//  ValidatorsVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/1/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ValidatorsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView?
    var validators: [Validator] = []
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        //validators = QuorumManager.validatorsNodes
        //self.title = "All Validators (\(validators.count))"
        self.tableView?.rowHeight = ValidatorCell.desiredHieght
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
    }
    
    // MARK: Table View
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return validators.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ValidatorCell = tableView.dequeueReusableCell(withIdentifier: "ValidatorCell", for: indexPath) as! ValidatorCell
        cell.updateWithModel(validator: validators[indexPath.row])
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ValidatorCell.desiredHieght
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView?.deselectRow(at: indexPath, animated: true)
        
        let storyboard = UIStoryboard(name: "QuorumVC", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QuorumVC") as! QuorumVC
        vc.validator = validators[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
