//
//  HomeVC.swift
//  NodeStar
//
//  Created by jeff on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class HomeVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let stellarbeatURLPath: String = "https://stellarbeat.io/nodes/raw"
    @IBOutlet weak var tableView: UITableView?
    var validators: [Validator] = []
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "All Validators"
        self.tableView?.rowHeight = ValidatorCell.desiredHieght
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)

        reloadDataFromStellarBeat()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    
    // MARK: Network Load Data
    func reloadDataFromStellarBeat() {
        let url: URL = URL(string: stellarbeatURLPath)!
        
        print("Updating \(stellarbeatURLPath)")
        URLSession.shared.dataTask(with: url) { [stellarbeatURLPath] (data: Data?, urlResponse: URLResponse?, error: Error?) in
            if error != nil {
                print("Updating \(stellarbeatURLPath) Request Fail: \(error!.localizedDescription)")
            }
            else {
                do {
                    if let jsonNodes: [[String: AnyObject]] = try JSONSerialization.jsonObject(with: data!, options: []) as? [[String: AnyObject]] {
                        print("Updating \(stellarbeatURLPath) Got JSON")
                        //print("ASynchronous\(jsonResult)")
                        var tempNodes: [Validator] = []
                        for jsonNode in jsonNodes {
                            let node: Validator? = Validator.nodeFromDictionary(dict: jsonNode)
                            if node != nil { tempNodes.append(node!) }
                        }
                        print("Parsed Validator Nodes: \(tempNodes.count)")
                        QuorumManager.validatorsNodes = tempNodes
                        self.validators = tempNodes
                        DispatchQueue.main.async{
                            self.tableView?.reloadData()
                        }
                    }
                    else {
                        print("Updating \(stellarbeatURLPath) Parsing Fail: Expecting an array")
                    }
                } catch let error as NSError {
                    print("Updating \(stellarbeatURLPath) Parsing Fail: \(error.localizedDescription)")
                }
            }
        }.resume()
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
