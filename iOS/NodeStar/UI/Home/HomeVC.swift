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
    
    // Charts
    @IBOutlet var nodesChart: BarChartView!
    @IBOutlet var depthChart: BarChartView!
    // Chart Cells
    @IBOutlet var nodesChartCell: UITableViewCell!
    @IBOutlet var depthChartCell: UITableViewCell!
    // Selectable Cells
    @IBOutlet var fromCell: UITableViewCell!
    @IBOutlet var validatorsCell: UITableViewCell!
    @IBOutlet var nodesSelectedCell: UITableViewCell!
    @IBOutlet var depthSelectedCell: UITableViewCell!
    @IBOutlet var selfRefCell: UITableViewCell!
    @IBOutlet var duplicateRefCell: UITableViewCell!
    // Other Cells
    @IBOutlet var fetchedCell: UITableViewCell!
    @IBOutlet var updatedCell: UITableViewCell!
    @IBOutlet var nodesAverageCell: UITableViewCell!
    @IBOutlet var nodesMaxCell: UITableViewCell!
    @IBOutlet var depthAverageCell: UITableViewCell!
    @IBOutlet var depthMaxCell: UITableViewCell!
    
    
    lazy var intFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
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
        title = "NodeStar"
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
        footerView.addTarget(self, action: #selector(pushAllValidatorsVC), for: .touchUpInside)
        view.addSubview(footerView)
        view.addConstraint(NSLayoutConstraint(item: footerView,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: footerView,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: 72.0))
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 72.0, 0.0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, 72.0, 0.0)
        
        // Setup refresh control
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action:#selector(refresh), for: UIControlEvents.valueChanged)
        refreshControl?.tintColor = nodeStarBlue
        tableView.addSubview(refreshControl!)
        
        // Setup chart formatting
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
        nodesChart.delegate = self
        nodesChart.pinchZoomEnabled = false
        nodesChart.scaleXEnabled = false
        nodesChart.scaleYEnabled = false
        
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
        depthChart.delegate = self
        depthChart.pinchZoomEnabled = false
        depthChart.scaleXEnabled = false
        depthChart.scaleYEnabled = false
        
        // Update the data (clear it out)
        updateTableView()
        
        // Start loading the data
        refreshControl?.beginRefreshing()
        refresh()
    }

    @objc func refresh() {
        reloadDataFromStellarBeat()
    }
    
    @objc func updateTableView() {
        if ( validators.count == 0 ) {
            // Clear it
            fetchedCell.detailTextLabel?.text = ""
            updatedCell.detailTextLabel?.text = ""
            fromCell.detailTextLabel?.text = ""
            validatorsCell.detailTextLabel?.text = ""
            nodesAverageCell.detailTextLabel?.text = ""
            nodesMaxCell.detailTextLabel?.text = ""
            depthAverageCell.detailTextLabel?.text = ""
            depthMaxCell.detailTextLabel?.text = ""
            selfRefCell.detailTextLabel?.text = ""
            duplicateRefCell.detailTextLabel?.text = ""
            nodesSelectedCell.detailTextLabel?.text = ""
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
                let nodeCount = v.quorumSet.allValidatorsCount
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
                if nodeCount != v.quorumSet.uniqueValidators.count {
                    countResuseDuplicateRef += 1
                }
                if v.quorumSet.uniqueValidators.contains(v.publicKey) {
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
            
            fetchedCell.detailTextLabel?.text = dateFormatter.string(from: Date())
            updatedCell.detailTextLabel?.text = dateFormatter.string(from: updatedMax )
            fromCell.detailTextLabel?.text = "stellarbeat.io"
            validatorsCell.detailTextLabel?.text = "\(validators.count)"
            let nodesAverage = Double(nodesSum) / Double(validators.count)
            nodesAverageCell.detailTextLabel?.text = String(format: "%.02f", nodesAverage)
            nodesMaxCell.detailTextLabel?.text = "\(nodesMax)"
            let depthAverage = Double(depthSum) / Double(validators.count)
            depthAverageCell.detailTextLabel?.text = String(format: "%.02f", depthAverage)
            depthMaxCell.detailTextLabel?.text = "\(depthMax)"
            selfRefCell.detailTextLabel?.text = "\(countResuseSelfRef) of \(validators.count)"
            duplicateRefCell.detailTextLabel?.text = "\(countResuseDuplicateRef) of \(validators.count)"
            
            // Update Charts
            let nodeTouplesSorted = nodesHistogram.sorted(by: { $0 < $1 })
            let nodeEntries = nodeTouplesSorted.map { (key, value) -> BarChartDataEntry in
                return BarChartDataEntry(x: Double(key), y: Double(value))
            }
            let nodesDataSet = BarChartDataSet(values: nodeEntries, label: nil)
            nodesDataSet.colors = [nodeStarBlue.withAlphaComponent(0.8)]
            nodesDataSet.valueFormatter = DefaultValueFormatter(formatter: intFormatter)
            nodesChart.data = BarChartData(dataSet: nodesDataSet)
            
            let depthTouplesSorted = depthHistogram.sorted(by: { $0 < $1 })
            let depthEntries = depthTouplesSorted.map { (key, value) -> BarChartDataEntry in
                return BarChartDataEntry(x: Double(key), y: Double(value))
            }
            let depthDataSet = BarChartDataSet(values: depthEntries, label: nil)
            depthDataSet.valueFormatter = DefaultValueFormatter(formatter: intFormatter)
            depthDataSet.colors = [nodeStarBlue.withAlphaComponent(0.8)]
            depthChart.data = BarChartData(dataSet: depthDataSet)
            
            updateSelected()
            
            // Chart Animation :)
            nodesChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
            depthChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
            
            tableView.reloadData()
        }
    }
    private func updateSelected() {
        if ( nodesChart.highlighted.count == 1 ) {
            nodesSelectedCell.textLabel?.text = "n=\(Int(nodesChart.highlighted[0].x))"
            nodesSelectedCell.detailTextLabel?.text = "\(Int(nodesChart.highlighted[0].y))"
        }
        else {
            if let entry = nodesChart.barData?.dataSets[0].entryForIndex(0) {
                nodesSelectedCell.textLabel?.text = "n=\(Int(entry.x))"
                nodesSelectedCell.detailTextLabel?.text = "\(Int(entry.y))"
            }
            else {
                nodesSelectedCell.textLabel?.text = ""
                nodesSelectedCell.detailTextLabel?.text = ""
            }
        }
        
        if ( depthChart.highlighted.count == 1 ) {
            depthSelectedCell.textLabel?.text = "d=\(Int(depthChart.highlighted[0].x))"
            depthSelectedCell.detailTextLabel?.text = "\(Int(depthChart.highlighted[0].y))"
        }
        else {
            if let entry = depthChart.barData?.dataSets[0].entryForIndex(0) {
                depthSelectedCell.textLabel?.text = "d=\(Int(entry.x))"
                depthSelectedCell.detailTextLabel?.text = "\(Int(entry.y))"
            }
            else {
                depthSelectedCell.textLabel?.text = ""
                depthSelectedCell.detailTextLabel?.text = ""
            }
        }
    }
    
    // MARK: User Interaction
    @objc func pushAllValidatorsVC() {
        let vc = ValidatorsVC.newVC()
        vc.title = "All Validators"
        vc.validators = QuorumManager.validators
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: Network Load Data
    // TODO: decouple this from the VC
    func reloadDataFromStellarBeat() {
        let url: URL = URL(string: stellarbeatURLPath)!
        print("Updating \(stellarbeatURLPath)")
        URLSession.shared.dataTask(with: url) { (a, n, c) in
        
        }
        URLSession.shared.dataTask(with: url) { [stellarbeatURLPath] (data, urlResponse, error) in
            if error != nil {
                print("Updating \(stellarbeatURLPath) Request Fail: \(error!.localizedDescription)")
                self.showNetworkError()
            }
            else {
                do {
                    if let jsonNodes: [[String: AnyObject]] =
                        try JSONSerialization.jsonObject(with: data!,options: []) as? [[String: AnyObject]] {
                        
                        print("Updating \(stellarbeatURLPath) Got JSON")
                        //print("ASynchronous\(jsonResult)")
                        var tempNodes: [Validator] = []
                        for jsonNode in jsonNodes {
                            let node: Validator? = Validator.nodeFromDictionary(dict: jsonNode)
                            if node != nil { tempNodes.append(node!) }
                        }
                        print("Parsed Validator Nodes: \(tempNodes.count)")
                        QuorumManager.validators = tempNodes
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
            let message = "Failed to get data. " +
                          "Check your internet connection. Pull to refresh or try updating from App Store."
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
            let message = "Failed to get parse network data. " +
                          "Pull to refresh or try updating from App Store."
            let alert = UIAlertController(title: "Error", message: message, preferredStyle:.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: {
                self.refreshControl?.endRefreshing()
            })
        }
    }
    
    // MARK: UITableViewDelegate
    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell == fromCell {
            // StellarBeat.io
            tableView.deselectRow(at: indexPath, animated: true)
            UIApplication.shared.open(URL(string: "https://stellarbeat.io/")!, options: [:], completionHandler: nil)
        }
        if cell == validatorsCell {
            // Validators
            pushAllValidatorsVC()
        }
        if cell == nodesSelectedCell {
            // Nodes Selected
            var nodes = 0
            if ( nodesChart.highlighted.count == 1 ) {
                nodes = Int(nodesChart.highlighted[0].x)
            }
            let vc = ValidatorsVC.newVC()
            vc.title = "n=\(nodes) Validators"
            vc.validators = validators.filter({ (v) -> Bool in
                return v.quorumSet.allValidatorsCount == nodes
            })
            navigationController?.pushViewController(vc, animated: true)
        }
        if cell == depthSelectedCell {
            // Depth Selected
            var depth = 0
            if ( depthChart.highlighted.count == 1 ) {
                depth = Int(depthChart.highlighted[0].x)
            }
            let vc = ValidatorsVC.newVC()
            vc.title = "d=\(depth) Validators"
            vc.validators = validators.filter({ (v) -> Bool in
                return v.quorumSet.maxDepth == depth
            })
            navigationController?.pushViewController(vc, animated: true)
        }
        if cell == selfRefCell {
            // Self Ref Validators
            let vc = ValidatorsVC.newVC()
            vc.title = "Self Ref Validators"
            vc.validators = validators.filter({ (v) -> Bool in
                return v.quorumSet.uniqueValidators.contains(v.publicKey)
            })
            navigationController?.pushViewController(vc, animated: true)
        }
        if cell == duplicateRefCell {
            // Duplicate Ref Validators
            let vc = ValidatorsVC.newVC()
            vc.title = "Duplicate Ref Validators"
            vc.validators = validators.filter({ (v) -> Bool in
                return v.quorumSet.allValidatorsCount != v.quorumSet.uniqueValidators.count
            })
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    override public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        let selectableCells = [fromCell,
                               validatorsCell,
                               nodesSelectedCell,
                               depthSelectedCell,
                               selfRefCell,
                               duplicateRefCell]
        if selectableCells.contains(cell) {
            return indexPath
        }
        return nil
    }
    
    // MARK: ChartViewDelegate
    @objc func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Flash the chart selected cell
        let cellToFlash = chartView == nodesChart ? nodesSelectedCell : depthSelectedCell
        cellToFlash?.setSelected(true, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 ) {
            cellToFlash?.setSelected(false, animated: true)
        }
        
        // Update the values in the chart selected cells
        updateSelected()
    }
}