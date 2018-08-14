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
    @IBOutlet var usageChart: BarChartView!
    // Chart Cells
    @IBOutlet var nodesChartCell: UITableViewCell!
    @IBOutlet var depthChartCell: UITableViewCell!
    @IBOutlet var usageChartCell: UITableViewCell!
    // Selectable Cells
    @IBOutlet var fromCell: UITableViewCell!
    @IBOutlet var validatorsCell: UITableViewCell!
    @IBOutlet var nodesSelectedCell: UITableViewCell!
    @IBOutlet var depthSelectedCell: UITableViewCell!
    @IBOutlet var usageSelectedCell: UITableViewCell!
    @IBOutlet var selfRefCell: UITableViewCell!
    @IBOutlet var duplicateRefCell: UITableViewCell!
    // Other Cells
    @IBOutlet var fetchedCell: UITableViewCell!
    @IBOutlet var updatedCell: UITableViewCell!
    @IBOutlet var nodesAverageCell: UITableViewCell!
    @IBOutlet var nodesMaxCell: UITableViewCell!
    @IBOutlet var depthAverageCell: UITableViewCell!
    @IBOutlet var depthMaxCell: UITableViewCell!
    @IBOutlet var usageAverageCell: UITableViewCell!
    @IBOutlet var usageMaxCell: UITableViewCell!
    
    // BarChartView to ChartCell, SelectedCell, prefix
    lazy var chartMetadata: [BarChartView : ChartMetadata] = {
        return [nodesChart : ChartMetadata(selectCell: nodesSelectedCell, chartCell: nodesChartCell, prefix: "n="),
                depthChart : ChartMetadata(selectCell: depthSelectedCell, chartCell: depthChartCell, prefix: "d="),
                usageChart : ChartMetadata(selectCell: usageSelectedCell, chartCell: usageChartCell, prefix: "u=")]
    }()
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
        self.navigationItem.titleView = setTitle("NodeStar", subtitle: "A Stellar Quorum Explorer")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "definitions",
                                                            style:.plain,
                                                            target: self,
                                                            action: #selector(tappedDefinitionsButton))

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
        for (chart, metadata) in chartMetadata {
            setupChart(chart: chart, prefix: metadata.prefix)
        }
        
        // Update the data (clear it out)
        updateTableView()
        
        // Start loading the data
        refreshControl?.beginRefreshing()
        refresh()
    }
    
    private func setupChart(chart: BarChartView, prefix: String) {
        chart.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: intFormatter)
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.granularity = 1
        chart.xAxis.drawGridLinesEnabled = false
        let nodesFormatter = intFormatter.copy() as! NumberFormatter
        nodesFormatter.positivePrefix = prefix
        chart.xAxis.valueFormatter = DefaultAxisValueFormatter(formatter: nodesFormatter)
        chart.xAxis.granularity = 1
        chart.xAxis.labelPosition = .bottom
        chart.rightAxis.enabled = false
        chart.chartDescription = nil
        chart.legend.enabled = false
        chart.delegate = self
        chart.pinchZoomEnabled = false
        chart.scaleXEnabled = false
        chart.scaleYEnabled = false
    }
    
    private func setTitle(_ title:String, subtitle:String) -> UIView {
        let titleLabel = UILabel(frame: CGRect(x: 0, y: -2, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.text = title
        titleLabel.sizeToFit()

        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.text = subtitle
        subtitleLabel.sizeToFit()
        
        let maxTitleWidth = max(titleLabel.frame.size.width, subtitleLabel.frame.size.width)
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: maxTitleWidth, height: 30))
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        let widthDiff = subtitleLabel.frame.size.width - titleLabel.frame.size.width
        if widthDiff < 0 {
            let newX = widthDiff / 2
            subtitleLabel.frame.origin.x = abs(newX)
        } else {
            let newX = widthDiff / 2
            titleLabel.frame.origin.x = newX
        }
        return titleView
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
            for (_, metadata) in chartMetadata {
                upateSelectedCell(cell: metadata.selectCell, keyValue: (nil, nil), prefix: metadata.prefix)
            }
        }
        else {
            // Setup with our data
            
            // Calculate some metrics
            var updatedMax: Date = Date(timeIntervalSince1970: 0)
            chartMetadata[nodesChart]!.validatorsForKey = [:]
            chartMetadata[depthChart]!.validatorsForKey = [:]
            chartMetadata[usageChart]!.validatorsForKey = [:]
            var countResuseSelfRef: Int = 0
            var countResuseDuplicateRef: Int = 0
            for v in validators {
                // Node Counts
                let nodeCount = v.quorumSet.allValidatorsCount
                chartAddValidator(chart: nodesChart, validator: v, key: nodeCount)
                
                // Depth
                let depth = v.quorumSet.maxDepth
                chartAddValidator(chart: depthChart, validator: v, key: depth)
                
                // Usage
                let usage = v.usagesInValidatorQuorumSets()
                chartAddValidator(chart: usageChart, validator: v, key: usage)
                
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
            updateMaxAndAverage(chart: nodesChart, averageCell: nodesAverageCell, maxCell: nodesMaxCell)
            updateMaxAndAverage(chart: depthChart, averageCell: depthAverageCell, maxCell: depthMaxCell)
            updateMaxAndAverage(chart: usageChart, averageCell: usageAverageCell, maxCell: usageMaxCell)
            selfRefCell.detailTextLabel?.text = "\(countResuseSelfRef) of \(validators.count)"
            duplicateRefCell.detailTextLabel?.text = "\(countResuseDuplicateRef) of \(validators.count)"
            
            // Update Charts
            for (chart, metadata) in chartMetadata {
                chart.data = BarChartData(dataSet: dataSetForHistogram(nodesForKey: metadata.validatorsForKey))
                chart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
            }
            updateSelected()
            
            tableView.reloadData()
        }
    }
    private func updateMaxAndAverage(chart: BarChartView, averageCell: UITableViewCell, maxCell: UITableViewCell) {
        let (max, count) = chartMaxAndCount(chart: chart)
        averageCell.detailTextLabel?.text = String(format: "%.02f", Double(count)/Double(validators.count))
        maxCell.detailTextLabel?.text = "\(max)"
    }
    private func chartMaxAndCount(chart: BarChartView) -> (Int, Int) {
        return chartMetadata[chart]!.validatorsForKey.reduce((0,0)) { (r, v) -> (Int,Int) in
            if v.key > r.0 {
                return (v.key, r.1 + v.key * v.value.count)
            }
            else {
                return (r.0, r.1 + v.key * v.value.count)
            }
        }
    }
    private func chartAddValidator(chart: BarChartView, validator: Validator, key: Int) {
        if chartMetadata[chart]!.validatorsForKey[key] != nil {
            chartMetadata[chart]!.validatorsForKey[key]!.append(validator)
        }
        else {
            chartMetadata[chart]!.validatorsForKey[key] = [validator]
        }
    }
    private func dataSetForHistogram(nodesForKey: [Int:[Validator]]) -> BarChartDataSet {
        let sorted = nodesForKey.sorted(by: { $0.key < $1.key })
        let entries = sorted.map { (key, validators) -> BarChartDataEntry in
            return BarChartDataEntry(x: Double(key), y: Double(validators.count))
        }
        let dataSet = BarChartDataSet(values: entries, label: nil)
        dataSet.colors = [nodeStarBlue.withAlphaComponent(0.8)]
        dataSet.valueFormatter = DefaultValueFormatter(formatter: intFormatter)
        return dataSet
    }
    private func updateSelected() {
        for (chart, metadata) in chartMetadata {
            upateSelectedCell(cell: metadata.selectCell,
                              keyValue: selectedKeyValue(chart: chart),
                              prefix: metadata.prefix)
        }
    }
    private func selectedKeyValue(chart: BarChartView) -> (key: Int?, value: Int?) {
        if ( chart.highlighted.count == 1 ) {
            return (Int(chart.highlighted[0].x), Int(chart.highlighted[0].y))
        }
        else {
            if let entry = usageChart.barData?.dataSets[0].entryForIndex(0) {
                return (Int(entry.x), Int(entry.y))
            }
        }
        return (nil, nil)
    }
    private func upateSelectedCell(cell: UITableViewCell, keyValue: (Int?, Int?), prefix: String) {
        let (key, value) = keyValue
        if key != nil {
            cell.textLabel?.text = "\(prefix)\(key!):"
        }
        else {
            cell.textLabel?.text = ""
        }
        if value != nil {
            cell.detailTextLabel?.text = "\(value!)"
        }
        else {
            cell.detailTextLabel?.text = ""
        }
    }
    
    // MARK: User Interaction
    @objc func pushAllValidatorsVC() {
        let vc = ValidatorsVC.newVC()
        vc.title = "All Validators"
        vc.validators = QuorumManager.validators
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func tappedDefinitionsButton() {
        let vc = InfoVC.newVC()
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
        
        // Check if tapped on chart selected cell
        for (chart, metadata) in chartMetadata {
            if cell == metadata.selectCell {
                let vc = ValidatorsVC.newVC()
                let keyValue = selectedKeyValue(chart: chart)
                if keyValue.key != nil {
                    vc.title = "Validators \(metadata.prefix!)\(keyValue.key!)"
                    vc.validators = metadata.validatorsForKey[keyValue.key!]!
                    navigationController?.pushViewController(vc, animated: true)
                }
                else {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                return
            }
        }
        
        if cell == fromCell {
            // StellarBeat.io
            tableView.deselectRow(at: indexPath, animated: true)
            UIApplication.shared.open(URL(string: "https://stellarbeat.io/")!, options: [:], completionHandler: nil)
        }
        if cell == validatorsCell {
            // Validators
            pushAllValidatorsVC()
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
                               usageSelectedCell,
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
        let cellToFlash: UITableViewCell! = chartMetadata[chartView as! BarChartView]!.selectCell
        cellToFlash?.setSelected(true, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 ) {
            cellToFlash?.setSelected(false, animated: true)
        }
        
        // Update the values in the chart selected cells
        updateSelected()
    }
}

struct ChartMetadata {
    var selectCell: UITableViewCell!
    var chartCell: UITableViewCell!
    var prefix: String!
    var validatorsForKey: [Int: [Validator]]!
    init(selectCell: UITableViewCell, chartCell: UITableViewCell, prefix: String) {
        self.selectCell = selectCell
        self.chartCell = chartCell
        self.prefix = prefix
        validatorsForKey = [:]
    }
}
