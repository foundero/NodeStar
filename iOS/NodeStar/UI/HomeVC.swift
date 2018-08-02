//
//  HomeVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class HomeVC: UITableViewController {
    
    let stellarbeatURLPath: String = "https://stellarbeat.io/nodes/raw"
    var validators: [Validator] = []
    
    @IBOutlet var fetchedLabel: UILabel!
    @IBOutlet var updatedLabel: UILabel!
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var validatorsLabel: UILabel!
    @IBOutlet var nodesAverageLabel: UILabel!
    @IBOutlet var nodesMaxLabel: UILabel!
    @IBOutlet var depthAverageLabel: UILabel!
    @IBOutlet var depthMaxLabel: UILabel!
    @IBOutlet var reuseSelfRefLabel: UILabel!
    @IBOutlet var reuseDuplicateRefLabel: UILabel!
    
    
    // Ugly hack to get at VC.view instead of tableview
    // https://stackoverflow.com/a/16249515
    @IBOutlet var tableViewReference: UITableView!
    var viewReference: UIView!
    override var tableView: UITableView! {
        get { return tableViewReference }
        set { super.tableView = newValue }
    }
    override var view: UIView! {
        get { return viewReference }
        set { super.view = newValue }
    }
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "NodeStar"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)

        // Ugly hack to get at VC.view instead of tableview
        // https://stackoverflow.com/a/16249515
        viewReference = UIView(frame: tableViewReference.frame)
        viewReference.backgroundColor = tableViewReference.backgroundColor
        viewReference.addSubview(tableViewReference)
        
        // Add the footer view
        let footerView = UIButton(frame: CGRect.null)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.backgroundColor = nodeStarBlue
        footerView.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        footerView.setTitleColor(UIColor.white, for: UIControlState.normal)
        footerView.setTitle("View Validators", for: UIControlState.normal)
        footerView.addTarget(self, action: #selector(pushValidatorsVC), for: .touchUpInside)
        view.addSubview(footerView)
        view.addConstraint(NSLayoutConstraint(item: footerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 72.0))
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 72.0, 0.0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 72.0, 0.0)
        
        // Setup refresh control
        self.refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action:#selector(refresh), for: UIControlEvents.valueChanged)
        refreshControl?.tintColor = nodeStarBlue
        self.tableView.addSubview(self.refreshControl!)
        
        // Start loading the data
        self.updateTableView()
        self.refresh()
    }
    
    @objc func refresh() {
        reloadDataFromStellarBeat()
    }
    
    @objc func updateTableView() {
        if ( self.validators.count == 0 ) {
            // Clear it
            self.fetchedLabel.text = ""
            self.updatedLabel.text = ""
            self.fromLabel.text = ""
            self.validatorsLabel.text = ""
            self.nodesAverageLabel.text = ""
            self.nodesMaxLabel.text = ""
            self.depthAverageLabel.text = ""
            self.depthMaxLabel.text = ""
            self.reuseSelfRefLabel.text = ""
            self.reuseDuplicateRefLabel.text = ""
        }
        else {
            // Setup with our data
            
            // Calculate some metrics
            var maxUpdated: Date = Date(timeIntervalSince1970: 0)
            var maxNodes: Int = 0
            var sumNodes: Int = 0
            var maxDepth: Int = 0
            var sumDepth: Int = 0
            var countResuseSelfRef: Int = 0
            var countResuseDuplicateRef: Int = 0
            for v in validators {
                let nodeCount = v.quorumSet.leafValidators
                sumNodes += nodeCount
                if maxNodes < nodeCount {
                    maxNodes = nodeCount
                }
                let depth = v.quorumSet.maxDepth
                sumDepth += depth
                if maxDepth < depth {
                    maxDepth = depth
                }
                if nodeCount != v.quorumSet.eventualValidators.count {
                    countResuseDuplicateRef += 1
                }
                if v.quorumSet.eventualValidators.contains(v.publicKey) {
                    countResuseSelfRef += 1
                }
                if v.updatedAt > maxUpdated {
                    maxUpdated = v.updatedAt
                }
            }
            
            // Update our UI
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
            self.fetchedLabel.text = dateFormatter.string(from: Date())
            self.updatedLabel.text = dateFormatter.string(from: maxUpdated )
            self.fromLabel.text = "stellarbeat.io"
            self.validatorsLabel.text = "\(validators.count)"
            self.nodesAverageLabel.text = String(format: "%.02f", Double(sumNodes) / Double(validators.count))
            self.nodesMaxLabel.text = "\(maxNodes)"
            self.depthAverageLabel.text = String(format: "%.02f", Double(sumDepth) / Double(validators.count))
            self.depthMaxLabel.text = "\(maxDepth)"
            self.reuseSelfRefLabel.text = "\(countResuseSelfRef) of \(validators.count)"
            self.reuseDuplicateRefLabel.text = "\(countResuseDuplicateRef) of \(validators.count)"
        }
        self.tableView.reloadData()
    }
    
    // MARK: User Interaction
    @objc func pushValidatorsVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ValidatorsVC") as! ValidatorsVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Network Load Data
    func reloadDataFromStellarBeat() {
        //TODO: decouple this from the VC
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
                            self.updateTableView()
                            self.refreshControl?.endRefreshing()
                        }
                    }
                    else {
                        print("Updating \(stellarbeatURLPath) Parsing Fail: Expecting an array")
                        DispatchQueue.main.async{
                            self.refreshControl?.endRefreshing()
                        }
                    }
                } catch let error as NSError {
                    print("Updating \(stellarbeatURLPath) Parsing Fail: \(error.localizedDescription)")
                    DispatchQueue.main.async{
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }.resume()
    }
    
    // MARK: UITableViewDelegate
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 {
            // StellarBeat.io
            tableView.deselectRow(at: indexPath, animated: true)
            UIApplication.shared.open(URL(string: "https://stellarbeat.io/")!, options: [:], completionHandler: nil)
        }
        if indexPath.section == 0 && indexPath.row == 3 {
            // Validators
            self.pushValidatorsVC()
        }
    }
    override public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 && ( indexPath.row == 2 || indexPath.row == 3 ) {
            return indexPath
        }
        return nil
    }
}
