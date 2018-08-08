//
//  QuorumMetricsVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/7/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit
import Charts

class QuorumMetricsVC: UITableViewController, ChartViewDelegate {
    var validator: Validator!
    var quorumNode: QuorumNode!
    
    // Charts
    @IBOutlet weak var metricChart: BarChartView!
    // Cells
    @IBOutlet weak var cellRootName: UITableViewCell!
    @IBOutlet weak var cellRootPK: UITableViewCell!
    @IBOutlet weak var cellNodeType: UITableViewCell!
    @IBOutlet weak var cellNodeName: UITableViewCell!
    @IBOutlet weak var cellNodeIdentifier: UITableViewCell!
    @IBOutlet weak var cellMetricsChart: UITableViewCell!
    @IBOutlet weak var cellMetricsAffect: UITableViewCell!
    @IBOutlet weak var cellMetricsRequire: UITableViewCell!
    @IBOutlet weak var cellMetricsInfluence: UITableViewCell!
    // Labels
    @IBOutlet weak var labelSummary: UILabel!
    @IBOutlet weak var labelMetricsAffect: UILabel!
    @IBOutlet weak var labelMetricsRequire: UILabel!
    @IBOutlet weak var labelMetricsInfluence: UILabel!
    @IBOutlet weak var labelCombinationsLeafs: UILabel!
    @IBOutlet weak var labelCombinations: UILabel!
    @IBOutlet weak var labelCombinationsRecursive: UILabel!
    @IBOutlet weak var labelTrueGivenTrue: UILabel!
    @IBOutlet weak var labelTrueGivenFalse: UILabel!
    @IBOutlet weak var labelFalseGivenTrue: UILabel!
    @IBOutlet weak var labelFalseGivenFalse: UILabel!
    @IBOutlet weak var labelEffectedMath: UILabel!
    @IBOutlet weak var labelEffectedResult: UILabel!
    @IBOutlet weak var labelAffectMath: UILabel!
    @IBOutlet weak var labelAffectResult: UILabel!
    @IBOutlet weak var labelRequireMath: UILabel!
    @IBOutlet weak var labelRequireResult: UILabel!
    @IBOutlet weak var labelInfluenceMath: UILabel!
    @IBOutlet weak var labelInfluenceResult: UILabel!
    
    lazy var percentFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = "%"
        return formatter
    }()
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        
        // Setup chart formatting
        metricChart.chartDescription = nil
        metricChart.legend.enabled = false
        metricChart.rightAxis.enabled = false
        metricChart.leftAxis.enabled = true
        metricChart.leftAxis.axisMinimum = 0.0
        metricChart.leftAxis.axisMaximum = 115.0
        metricChart.leftAxis.granularity = 25
        metricChart.leftAxis.labelFont = UIFont.systemFont(ofSize: 13.0)
        metricChart.leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: percentFormatter)
        metricChart.xAxis.drawGridLinesEnabled = false
        metricChart.xAxis.labelPosition = .bottom
        let formatter = MetricFormatter()
        formatter.shortForm = false
        metricChart.xAxis.valueFormatter = formatter
        metricChart.xAxis.labelCount = 3
        metricChart.xAxis.labelFont = UIFont.systemFont(ofSize: 13.0)
        
        // Update the data (clear it out)
        updateTableView()
    }
    
    @objc func updateTableView() {

        // Root
        let validatorHandle = QuorumManager.handleForNodeId(id: validator.publicKey)
        let rootNameString = "\(validatorHandle). \(validator.name ?? "")"
        var nodeNameString = "Inner Quorum Set"
        cellRootName.detailTextLabel?.text = rootNameString
        cellRootPK.detailTextLabel?.text = validator.publicKey
        
        // Node
        if quorumNode is QuorumSet {
            if quorumNode.identifier == validator.quorumSet.identifier {
                // Root
                cellNodeType.detailTextLabel?.text = "Root Validator / Quorum Set Node"
                nodeNameString = "\(validatorHandle). \(validator.name ?? "")"
                cellNodeName.detailTextLabel?.text = nodeNameString
                cellNodeIdentifier.textLabel?.text = "Public Key:"
                cellNodeIdentifier.detailTextLabel?.text = validator.publicKey
            }
            else {
                // Quorum Set
                cellNodeType.detailTextLabel?.text = "Inner Quorum Set Node"
                cellNodeName.detailTextLabel?.text = "n/a"
                cellNodeIdentifier.textLabel?.text = "QSet Hash:"
                cellNodeIdentifier.detailTextLabel?.text = quorumNode.identifier
            }
        }
        else {
            // Leaf Validator
            cellNodeType.detailTextLabel?.text = "Leaf Validator Node"
            let leafValidatorHandle = QuorumManager.handleForNodeId(id: quorumNode.identifier)
            let leafValidator = QuorumManager.validatorForId(id: quorumNode.identifier)
            nodeNameString = "\(leafValidatorHandle). \(leafValidator?.name ?? "")"
            cellNodeName.detailTextLabel?.text = nodeNameString
            cellNodeIdentifier.textLabel?.text = "Public Key:"
            cellNodeIdentifier.detailTextLabel?.text = quorumNode.identifier
        }
        
        // Summary
        labelSummary.text =
            "Impact of Selected Node: [\(nodeNameString)]\n" +
            "on Validator: [\(rootNameString)]"
        
        // Metrics
        let metrics = validator.quorumSet.impactOfNode(subjectNode: quorumNode)
        labelMetricsAffect.text =
            "The selected node affects the quorum outcome in " +
            QuorumMetrics.percentString(value: metrics.affect) +
            " of combinations."
        labelMetricsRequire.text =
            "The selected node is required to be true in " +
            QuorumMetrics.percentString(value: metrics.require) +
            " of the combinations that lead to quorum truth."
        labelMetricsInfluence.text =
            "The selected node influences the quorum result to true in " +
            QuorumMetrics.percentString(value: metrics.influence) +
            " of combinations where it otherwise would have been false."
        
        // Combinations
        let leafs = validator.quorumSet.uniqueValidators.subtracting(quorumNode.uniqueValidators).count
        labelCombinationsLeafs.text = "\(leafs)"
        labelCombinations.text = "\(pow(2, leafs))"
        labelCombinationsRecursive.text = "\(metrics.combinations)"
        labelTrueGivenTrue.text = "\(metrics.truthsGivenNodeTrue)"
        labelTrueGivenFalse.text = "\(metrics.truthsGivenNodeFalse)"
        labelFalseGivenTrue.text = "\(metrics.falsesGivenNodeTrue)"
        labelFalseGivenFalse.text = "\(metrics.falsesGivenNodeFalse)"
        
        // Math
        labelEffectedMath.text =
            "\(metrics.truthsGivenNodeTrue) + \(metrics.falsesGivenNodeFalse)" +
            " - \(metrics.combinations)"
        labelEffectedResult.text = "\(metrics.effected)"
        labelAffectMath.text = "\(metrics.effected) / \(metrics.combinations)"
        labelAffectResult.text =
            QuorumMetrics.ratioString(value: metrics.affect) +
            " or " +
            QuorumMetrics.percentString(value: metrics.affect)
        labelRequireMath.text = "\(metrics.effected) / \(metrics.truthsGivenNodeTrue)"
        labelRequireResult.text =
            QuorumMetrics.ratioString(value: metrics.require) +
            " or " +
            QuorumMetrics.percentString(value: metrics.require)
        labelInfluenceMath.text = "\(metrics.effected) / \(metrics.falsesGivenNodeFalse)"
        labelInfluenceResult.text =
            QuorumMetrics.ratioString(value: metrics.influence) +
            " or " +
            QuorumMetrics.percentString(value: metrics.influence)
        
        // Update Metrics Chart
        let dataSet = BarChartDataSet(values: [
            BarChartDataEntry(x: Double(0), y: Double(metrics.affect * 100)),
            BarChartDataEntry(x: Double(1), y: Double(metrics.require * 100)),
            BarChartDataEntry(x: Double(2), y: Double(metrics.influence * 100))], label: nil)
        dataSet.colors = [UIColor.blue, UIColor.red, UIColor.green]
        dataSet.valueFormatter = DefaultValueFormatter(formatter: percentFormatter)
        dataSet.valueFont = UIFont.systemFont(ofSize: 13.0)
        dataSet.axisDependency = YAxis.AxisDependency.left
        metricChart.data = BarChartData(dataSet: dataSet)
        metricChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
