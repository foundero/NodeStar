//
//  HomeVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit
import Charts

class HomeVC: UITableViewController, ChartViewDelegate {
    
    let stellarbeatURLPath: String = "https://stellarbeat.io/nodes/raw"
    var validators: [Validator] = []
    
    @IBOutlet var fetchedLabel: UILabel!
    @IBOutlet var updatedLabel: UILabel!
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var validatorsLabel: UILabel!
    @IBOutlet var nodesAverageLabel: UILabel!
    @IBOutlet var nodesMaxLabel: UILabel!
    @IBOutlet var nodesChart: BarChartView!
    @IBOutlet var depthAverageLabel: UILabel!
    @IBOutlet var depthMaxLabel: UILabel!
    @IBOutlet var depthChart: LineChartView!
    @IBOutlet var reuseSelfRefLabel: UILabel!
    @IBOutlet var reuseDuplicateRefLabel: UILabel!
    
    let intFormatter = NumberFormatter()
    
    
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
        
        // Setup chart formatting
        intFormatter.minimumFractionDigits = 0
        intFormatter.maximumFractionDigits = 0
        
        nodesChart.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: intFormatter)
        nodesChart.leftAxis.axisMinimum = 0
        nodesChart.leftAxis.granularity = 1
        nodesChart.xAxis.drawGridLinesEnabled = false
        let nodesFormatter = intFormatter.copy() as! NumberFormatter
        nodesFormatter.positivePrefix = "n="
        nodesChart.xAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nodesFormatter)
        nodesChart.xAxis.granularity = 1
        nodesChart.xAxis.labelPosition = .bottom
        nodesChart.rightAxis.enabled = false
        nodesChart.chartDescription = nil
        nodesChart.legend.enabled = false
        nodesChart.isUserInteractionEnabled = false
        
        depthChart.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: intFormatter)
        depthChart.leftAxis.axisMinimum = 0
        depthChart.leftAxis.granularity = 1
        depthChart.xAxis.drawGridLinesEnabled = false
        let depthFormatter = intFormatter.copy() as! NumberFormatter
        depthFormatter.positivePrefix = "d="
        depthChart.xAxis.valueFormatter = DefaultAxisValueFormatter(formatter: depthFormatter)
        depthChart.xAxis.granularity = 1
        depthChart.xAxis.labelPosition = .bottom
        depthChart.rightAxis.enabled = false
        depthChart.chartDescription = nil
        depthChart.legend.enabled = false
        depthChart.isUserInteractionEnabled = false
        
        // Start loading the data
        self.updateTableView()
        self.refreshControl?.beginRefreshing()
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
            var updatedMax: Date = Date(timeIntervalSince1970: 0)
            var nodesMax: Int = 0
            var nodesSum: Int = 0
            var nodesHistogram: [Int:Int] = [:]
            var depthMax: Int = 0
            var depthSum: Int = 0
            var depthHistogram: [Int:Int] = [:]
            var countResuseSelfRef: Int = 0
            var countResuseDuplicateRef: Int = 0
            for v in validators {
                // Node Counts
                let nodeCount = v.quorumSet.leafValidators
                nodesSum += nodeCount
                if nodesMax < nodeCount {
                    nodesMax = nodeCount
                }
                if nodesHistogram[nodeCount] != nil {
                    nodesHistogram[nodeCount] = nodesHistogram[nodeCount]! + 1
                }
                else {
                    nodesHistogram[nodeCount] = 1
                }
                
                // Depth
                let depth = v.quorumSet.maxDepth
                depthSum += depth
                if depthMax < depth {
                    depthMax = depth
                }
                if depthHistogram[depth] != nil {
                    depthHistogram[depth] = depthHistogram[depth]! + 1
                }
                else {
                    depthHistogram[depth] = 1
                }
                
                // Reuse
                if nodeCount != v.quorumSet.eventualValidators.count {
                    countResuseDuplicateRef += 1
                }
                if v.quorumSet.eventualValidators.contains(v.publicKey) {
                    countResuseSelfRef += 1
                }
                
                // Dates
                if v.updatedAt > updatedMax {
                    updatedMax = v.updatedAt
                }
            }
            
            // Update our UI
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss a"
            self.fetchedLabel.text = dateFormatter.string(from: Date())
            self.updatedLabel.text = dateFormatter.string(from: updatedMax )
            self.fromLabel.text = "stellarbeat.io"
            self.validatorsLabel.text = "\(validators.count)"
            self.nodesAverageLabel.text = String(format: "%.02f", Double(nodesSum) / Double(validators.count))
            self.nodesMaxLabel.text = "\(nodesMax)"
            self.depthAverageLabel.text = String(format: "%.02f", Double(depthSum) / Double(validators.count))
            self.depthMaxLabel.text = "\(depthMax)"
            self.reuseSelfRefLabel.text = "\(countResuseSelfRef) of \(validators.count)"
            self.reuseDuplicateRefLabel.text = "\(countResuseDuplicateRef) of \(validators.count)"
            
            // Update Charts
            self.view.layoutIfNeeded()
            let nodeEntries = nodesHistogram.map { (arg) -> BarChartDataEntry in
                let (key, value) = arg
                return BarChartDataEntry(x: Double(key), y: Double(value))
            }
            let nodesDataSet = BarChartDataSet(values: nodeEntries, label: nil)
            //nodesDataSet.drawValuesEnabled = false;
            nodesDataSet.valueFormatter = DefaultValueFormatter(formatter: intFormatter)
            self.nodesChart.data = BarChartData(dataSet: nodesDataSet)
            
            let depthEntries = depthHistogram.map { (arg) -> BarChartDataEntry in
                let (key, value) = arg
                return BarChartDataEntry(x: Double(key), y: Double(value))
            }
            let depthDataSet = BarChartDataSet(values: depthEntries, label: "asdfas")
            depthDataSet.valueFormatter = DefaultValueFormatter(formatter: intFormatter)
            self.depthChart.data = BarChartData(dataSet: depthDataSet)
            
            // Chart Animation :)
            nodesChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
            depthChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: User Interaction
    @objc func pushValidatorsVC() {
        updateTableView()
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
                self.showNetworkError()
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
                        self.showParsingError()
                    }
                } catch let error as NSError {
                    print("Updating \(stellarbeatURLPath) Parsing Fail: \(error.localizedDescription)")
                    self.showParsingError()
                }
            }
        }.resume()
    }
    private func showNetworkError() {
        DispatchQueue.main.async{
            let message = "Failed to get data. Check your internet connection. Pull to refresh or try updating from App Store."
            let alert = UIAlertController(title: "Error", message: message, preferredStyle:.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel,  handler: nil))
            self.present(alert, animated: true, completion: {
                self.refreshControl?.endRefreshing()
            })
        }
    }
    private func showParsingError() {
        DispatchQueue.main.async{
            self.refreshControl?.endRefreshing()
            let message = "Failed to get parse network data. Pull to refresh or try updating from App Store."
            let alert = UIAlertController(title: "Error", message: message, preferredStyle:.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: {
                self.refreshControl?.endRefreshing()
            })
        }
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
    override public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 2 {
            nodesChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
        }
        if indexPath.section == 2 && indexPath.row == 2 {
            depthChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
        }
    }
    
    // MARK: ChartViewDelegate
    //@objc optional func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight)
    
}
