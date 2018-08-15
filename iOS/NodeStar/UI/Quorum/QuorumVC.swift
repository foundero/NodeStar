//
//  QuorumVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/30/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit
import Charts

class QuorumVC: UIViewController, NodeViewDelegate {
    
    @IBOutlet var verticalStackView: UIStackView!
    var rowStackViews: [UIStackView] = []
    var linesOverlayView: LinesOverlayView!
    var nodeViews: [NodeView] = []
    var selectedNodeView: NodeView! { didSet { redrawSelectNodeView() } }
    
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var verifiedCheckmark: UIView!
    @IBOutlet weak var publicKeyLabel: UILabel!
    @IBOutlet weak var quorumSetHashLabel: UILabel!
    @IBOutlet weak var rootThresholdLabel: UILabel!
    @IBOutlet weak var nodesLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var usagesLabel: UILabel!
    @IBOutlet weak var metricChart: BarChartView!
    
    var validator: Validator!
    
    lazy var percentFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.positiveSuffix = "%"
        return formatter
    }()
    
    // MARK: -- View Controller Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Quorum Set - " + QuorumManager.handleForNodeId(id: validator.publicKey)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "detail",
                                                            style:.plain,
                                                            target: self,
                                                            action: #selector(tappedInfoButton))
        
        // Setup the chart
        metricChart.leftAxis.enabled = false
        metricChart.rightAxis.enabled = false
        metricChart.rightAxis.axisMinimum = 0.0
        metricChart.rightAxis.axisMaximum = 116.0
        metricChart.xAxis.drawGridLinesEnabled = false
        metricChart.xAxis.labelPosition = .bottom
        metricChart.xAxis.valueFormatter = MetricFormatter()
        metricChart.xAxis.labelCount = 3
        metricChart.xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        metricChart.chartDescription = nil
        metricChart.legend.enabled = false
        
        // Draw all the nodes within horizontal stack views
        showNodes(quorumNode: validator.quorumSet, depth: 0, parentNodeView: nil)
        
        // Root Node View
        let rootNodeView = nodeViews[0]
        rootNodeView.updateAsRoot(validator: validator)
        
        // Select 1st validator nodeview or else root
        var foundValidator = false
        for nv in nodeViews {
            if nv.quorumNode is QuorumValidator {
                selectedNodeView = nv
                foundValidator = true
                break
            }
        }
        if !foundValidator {
            selectedNodeView = rootNodeView
        }
        
        // Setup the view to draw lines on
        linesOverlayView = LinesOverlayView()
        linesOverlayView.overlayOnView(view)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @objc func tappedInfoButton() {
        let vc = ValidatorDetailVC.newVC()
        vc.validator = validator
        navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func tappedNodeInfoButton() {
        // If we can find the full info then go to it
        var validatorToPush = QuorumManager.validatorForId(id: selectedNodeView.quorumNode.identifier)
        if validatorToPush == nil && selectedNodeView.quorumNode.identifier == validator.quorumSet.identifier {
            validatorToPush = validator
        }
        if validatorToPush != nil {
            let vc = ValidatorDetailVC.newVC()
            vc.validator = validatorToPush
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    @IBAction func tappedNodeMetricsButton() {
        let vc = QuorumMetricsVC.newVC()
        vc.validator = validator
        vc.quorumNode = nodeForMetrics(node: selectedNodeView.quorumNode)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: -- Visualize Nodes
    func createRow(row: Int) {
        let padding: CGFloat = 10.0
        
        // Create a stackView For the row
        let stackView = UIStackView(frame: CGRect.null)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        stackView.axis = .horizontal
        verticalStackView.addArrangedSubview(stackView)
        stackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // Give it a background that changes color based on row
        let background = UIView(frame: CGRect.null)
        background.translatesAutoresizingMaskIntoConstraints = false
        let maxDepth = validator.quorumSet.maxDepth
        let backgroundAlpha: CGFloat = (CGFloat(maxDepth + 1) - CGFloat(row)) / CGFloat(maxDepth + 1)
        background.backgroundColor = UIColor.brown.withAlphaComponent(backgroundAlpha)
        stackView.addSubview(background)
        stackView.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .top,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .leading,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .trailing,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .bottom,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .bottom,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        
        // Give the row a label
        let rowLabel = UILabel(frame: CGRect.null)
        rowLabel.translatesAutoresizingMaskIntoConstraints = false
        let rowLabels: [String] = [" Root ", " Quorum Set ", " Inner Quorum Set "]
        if row < rowLabels.count-1 {
            rowLabel.text = rowLabels[row]
        }
        else {
            rowLabel.text = rowLabels[rowLabels.count-1]
        }
        rowLabel.font = UIFont.systemFont(ofSize: 10.0)
        rowLabel.backgroundColor = UIColor.white
        stackView.addSubview(rowLabel)
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .top,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .trailing,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        
        // Add the row to the view
        rowStackViews.append(stackView)
    }
    
    func showNodes(quorumNode: QuorumNode, depth: Int, parentNodeView: NodeView?) {
        // Create StackView if needed
        if rowStackViews.count < depth+1 {
            createRow(row: depth)
        }
        
        // Show this node in the row stack view
        let nv: NodeView = NodeView()
        nv.quorumNode = quorumNode
        nv.quorumMetrics = validator.quorumSet.impactOfNode(subjectNode: quorumNode)
        nv.parentNodeView = parentNodeView
        nv.update()
        nv.delegate = self
        rowStackViews[depth].addArrangedSubview(nv)
        nodeViews.append(nv)
        
        // Before showing children add spacer if next row already exists
        if rowStackViews.count > depth+1 {
            rowStackViews[depth+1].setCustomSpacing(8, after: rowStackViews[depth+1].arrangedSubviews.last!)
        }
        
        // Show children: first half validators, all inner quorum set, second half validators
        for (index, qn) in quorumNode.quorumNodesChildValidators().enumerated() {
            if index <= quorumNode.quorumNodesChildValidators().count / 2 {
                showNodes(quorumNode: qn, depth: depth+1, parentNodeView: nv)
            }
        }
        for qn in quorumNode.quorumNodesChildQuorumSets() {
            showNodes(quorumNode: qn, depth: depth+1, parentNodeView: nv)
        }
        for (index, qn) in quorumNode.quorumNodesChildValidators().enumerated() {
            if index > quorumNode.quorumNodesChildValidators().count / 2 {
                showNodes(quorumNode: qn, depth: depth+1, parentNodeView: nv)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Draw the lines between nodes
        linesOverlayView.clearLines()
        for nv in nodeViews {
            if let pnv: NodeView = nv.parentNodeView {
                // Draw from pnv to nv
                linesOverlayView.addLine(from: pnv, to: nv)
            }
        }
        
        // Update the font sizes to be consistent per row
        for rowStackView in rowStackViews {
            // Get the min size
            var minRowFontSize: CGFloat = 14.0
            for case let nv as NodeView in rowStackView.arrangedSubviews {
                let nvAdjustedFontSize = nv.adjustedFontSize()
                if nvAdjustedFontSize < minRowFontSize {
                    minRowFontSize = nvAdjustedFontSize
                }
            }
            // Set all in row to min size
            for case let nv as NodeView in rowStackView.arrangedSubviews {
                nv.setFontSize(size: minRowFontSize)
            }
        }
    }
    
    private func redrawSelectNodeView() {
        showNodeInfo(quorumNode: selectedNodeView.quorumNode)
        
        for nv in nodeViews {
            let sameNode = nv.quorumNode.identifier == selectedNodeView.quorumNode.identifier
            let rootSelected = selectedNodeView.quorumNode.identifier == validator.publicKey &&
                nv.quorumNode.identifier == validator.quorumSet.identifier
            let leafSelectedThatIsRoot = nv.quorumNode.identifier == validator.publicKey &&
                selectedNodeView.quorumNode.identifier == validator.quorumSet.identifier
            nv.selected = sameNode || rootSelected || leafSelectedThatIsRoot
        }
    }
    
    
    // MARK: -- NodeViewDelegate
    func nodeViewTapped(nodeView: NodeView) {
        selectedNodeView = nodeView
    }
    func nodeViewDoubleTapped(nodeView: NodeView) {
        selectedNodeView = nodeView
        // If we can find the full info then go to it
        if let validatorToPush: Validator = QuorumManager.validatorForId(id: nodeView.quorumNode.identifier) {
            let vc = QuorumVC.newVC()
            vc.validator = validatorToPush
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: -- Display Detail
    private func showNodeInfo(quorumNode: QuorumNode) {
        clearInfo()
        
        if quorumNode.identifier == validator.quorumSet.identifier {
            // Root node let - show Validator (because the QuorumNode is a QuorumSetNode in this case)
            showValidatorInfo(validatorToShow: validator)
        }
        else if let validator: Validator = QuorumManager.validatorForId(id: quorumNode.identifier) {
            // Leaf validator where we have it's fulll Validator info
            showValidatorInfo(validatorToShow: validator)
        }
        else {
            // Either a QuorumSetNode or QuorumValidatorNode - either way we don't have much info on it
            showQuorumNodeInfo(node: quorumNode)
        }
        
        // Update Metrics Chart
        let metrics = validator.quorumSet.impactOfNode(subjectNode: nodeForMetrics(node: quorumNode))
        let dataSet = BarChartDataSet(values: [
            BarChartDataEntry(x: Double(0), y: Double(metrics.affect * 100)),
            BarChartDataEntry(x: Double(1), y: Double(metrics.require * 100)),
            BarChartDataEntry(x: Double(2), y: Double(metrics.influence * 100))], label: nil)
        dataSet.colors = [nodeStarBlue, UIColor.red, nodeStarGreen]
        dataSet.valueFormatter = DefaultValueFormatter(formatter: percentFormatter)
        dataSet.valueFont = UIFont.systemFont(ofSize: 8.0)
        dataSet.axisDependency = YAxis.AxisDependency.right
        metricChart.data = BarChartData(dataSet: dataSet)
        metricChart.animate(yAxisDuration: 0.8, easingOption: ChartEasingOption.easeOutQuad)
    }
    private func nodeForMetrics(node: QuorumNode) -> QuorumNode {
        var nodeForMetrics = node
        if node.identifier == validator.quorumSet.identifier {
            // Selected root - check for leaf to display metrics for instead
            if let progeny = validator.quorumSet.progeny(progenyIdentifier: validator.publicKey) {
                nodeForMetrics = progeny
            }
        }
        return nodeForMetrics
    }
    private func clearInfo() {
        quorumSetHashLabel.text = ""
        publicKeyLabel.text = " \n "
        cityLabel.text = ""
        nameLabel.text = ""
        nodesLabel.text = ""
        depthLabel.text = ""
        usagesLabel.text = ""
        rootThresholdLabel.text = ""
        verifiedCheckmark.isHidden = true
    }
    private func showValidatorInfo(validatorToShow: Validator) {
        let validatorHandle = QuorumManager.handleForNodeId(id: validatorToShow.publicKey)
        nameLabel.text = "\(validatorHandle). \(validatorToShow.name ?? "")"
        cityLabel.text = validatorToShow.city ?? "[City]"
        publicKeyLabel.text = "pk: " + validatorToShow.publicKey
        verifiedCheckmark.isHidden = !validatorToShow.verified
        
        nodesLabel.text = "n=\(validatorToShow.quorumSet.uniqueValidators.count)," +
            "\(validatorToShow.uniqueEventualValidators.count)"
        depthLabel.text = "d=\(validatorToShow.quorumSet.maxDepth)"
        usagesLabel.text = "u=\(validatorToShow.uniqueDependents.count)," +
            "\(validatorToShow.uniqueEventualDependents.count)"
        showQuorumNodeInfo(node: validatorToShow.quorumSet)
    }
    private func showQuorumNodeInfo(node: QuorumNode) {
        // Limited QuorumNode (QuorumSet or ValidatorNode) info
        if node is QuorumValidator {
            publicKeyLabel.text = "pk: " + node.identifier
            if nameLabel.text == "" {
                nameLabel.text = "?. Unkonwn Validator"
            }
        }
        else {
            quorumSetHashLabel.text = "qsh: " + node.identifier
            if nameLabel.text == "" {
                nameLabel.text = "Quorum Set"
            }
        }
        
        let thresholdString = "\(node.threshold)/\(node.quorumNodes.count)"
        if ( node.maxDepth ) > 1 {
            rootThresholdLabel.text = "*" + thresholdString
        }
        else {
            rootThresholdLabel.text = thresholdString
        }
    }
}

class MetricFormatter: IAxisValueFormatter {
    var shortForm: Bool = true
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        var strings: [String] = []
        if shortForm {
            strings = ["A", "R", "I"]
        }
        else {
            strings = ["Affect", "Require", "Influence"]
        }
        return strings[min(Int(value),2)]
    }
}
