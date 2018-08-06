//
//  QuorumVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/30/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class QuorumVC: UIViewController, NodeViewDelegate {
    
    @IBOutlet var verticalStackView: UIStackView?
    var rowStackViews: [UIStackView] = []
    var nodeLinesOverlayView: NodeLinesOverlayView!
    var nodeViews: [NodeView] = []
    var selectedNodeView: NodeView! { didSet { redrawSelectNodeView() } }
    
    @IBOutlet weak var cityLabel: UILabel?
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var verifiedCheckmark: UIView?
    @IBOutlet weak var publicKeyLabel: UILabel?
    @IBOutlet weak var quorumSetHashLabel: UILabel?
    @IBOutlet weak var rootThresholdLabel: UILabel?
    @IBOutlet weak var nodesLabel: UILabel?
    @IBOutlet weak var leafsLabel: UILabel?
    @IBOutlet weak var depthLabel: UILabel?
    
    var validator: Validator!
    
    // MARK: -- View Controller Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Quorum Set - " + QuorumManager.handleForNodeId(id: self.validator.publicKey)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "info", style:.plain, target: self, action: #selector(tappedInfoButton))
        
        // Draw all the nodes within horizontal stack views
        self.showNodes(quorumNode: self.validator.quorumSet, depth: 0, parentNodeView: nil)
        
        // Select root
        let rootNodeView = self.nodeViews[0]
        rootNodeView.updateAsRoot(validator: self.validator)
        selectedNodeView = rootNodeView

        // Setup the view to draw lines on
        self.nodeLinesOverlayView = NodeLinesOverlayView()
        self.nodeLinesOverlayView.overlayOnView(self.view)
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @objc func tappedInfoButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ValidatorDetailVC") as! ValidatorDetailVC
        vc.validator = self.validator
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func tappedNodeInfoButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ValidatorDetailVC") as! ValidatorDetailVC
        vc.validator = self.validator
        self.navigationController?.pushViewController(vc, animated: true)
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
        self.verticalStackView?.addArrangedSubview(stackView)
        stackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // Give it a background that changes color based on row
        let background = UIView(frame: CGRect.null)
        background.translatesAutoresizingMaskIntoConstraints = false
        let backgroundAlpha: CGFloat = (CGFloat(self.validator.quorumSet.maxDepth + 1) - CGFloat(row)) / CGFloat(self.validator.quorumSet.maxDepth + 1)
        background.backgroundColor = UIColor.brown.withAlphaComponent(backgroundAlpha)
        stackView.addSubview(background)
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .top, relatedBy: .equal, toItem: stackView, attribute: .top, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .leading, relatedBy: .equal, toItem: stackView, attribute: .leading, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .trailing, relatedBy: .equal, toItem: stackView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .bottom, relatedBy: .equal, toItem: stackView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
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
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel, attribute: .top, relatedBy: .equal, toItem: stackView, attribute: .top, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel, attribute: .trailing, relatedBy: .equal, toItem: stackView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        
        // Add the row to the view
        self.rowStackViews.append(stackView)
    }
    
    func showNodes(quorumNode: QuorumNode, depth: Int, parentNodeView: NodeView?) {
        // Create StackView if needed
        if self.rowStackViews.count < depth+1 {
            self.createRow(row: depth)
        }
        
        // Show this node in the row stack view
        let nv: NodeView = NodeView()
        nv.quorumNode = quorumNode
        nv.parentNodeView = parentNodeView
        nv.update()
        nv.delegate = self
        self.rowStackViews[depth].addArrangedSubview(nv)
        self.nodeViews.append(nv)
        
        // Before showing children add spacer if next row already exists
        if self.rowStackViews.count > depth+1 {
            self.rowStackViews[depth+1].setCustomSpacing(8, after: self.rowStackViews[depth+1].arrangedSubviews.last!)
        }
        
        // Show children
        for qn in quorumNode.quorumNodes {
            self.showNodes(quorumNode: qn, depth: depth+1, parentNodeView: nv)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Draw the lines between nodes
        self.nodeLinesOverlayView.clearLines()
        for nv in self.nodeViews {
            if let pnv: NodeView = nv.parentNodeView {
                // Draw from pnv to nv
                self.nodeLinesOverlayView.addLine(from: pnv, to: nv)
            }
        }
    }
    
    private func redrawSelectNodeView() {
        self.showNodeInfo(quorumNode: selectedNodeView.quorumNode)
        
        for nv in self.nodeViews {
            // Selected if same quorumNode or if root selected any matching its quorumset or if selected matches roots quorum set
            nv.selected = (
                nv.quorumNode.identifier == selectedNodeView.quorumNode.identifier ||
                selectedNodeView.quorumNode.identifier == self.validator.publicKey && nv.quorumNode.identifier == self.validator.quorumSet.identifier ||
                nv.quorumNode.identifier == self.validator.publicKey && selectedNodeView.quorumNode.identifier == self.validator.quorumSet.identifier
            )
        }
    }
    
    
    // MARK: -- NodeViewDelegate
    func nodeViewTapped(nodeView: NodeView) {
        self.selectedNodeView = nodeView
        let m = validator.quorumSet.quorumMetricsForNode(node: nodeView.quorumNode)
        m.printMetrics()
    }
    func nodeViewDoubleTapped(nodeView: NodeView) {
        self.selectedNodeView = nodeView
        // If we can find the full info then go to it
        if let validator: Validator = QuorumManager.validatorForId(id: nodeView.quorumNode.identifier) {
            self.pushValidatorNode(validator: validator)
        }
    }
    
    // MARK: -- Navigate
    private func pushValidatorNode(validator: Validator) {
        let storyboard = UIStoryboard(name: "QuorumVC", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QuorumVC") as! QuorumVC
        vc.validator = validator
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: -- Display Detail
    private func showNodeInfo(quorumNode: QuorumNode) {
        self.clearInfo()
        
        if quorumNode.identifier == self.validator.quorumSet.identifier {
            // Root node let - show Validator (because the QuorumNode is a QuorumSetNode in this case)
            self.showValidatorInfo(validator: self.validator)
        }
        else if let validator: Validator = QuorumManager.validatorForId(id: quorumNode.identifier) {
            // Leaf validator where we have it's fulll Validator info
            self.showValidatorInfo(validator: validator)
        }
        else {
            // Either a QuorumSetNode or QuorumValidatorNode - either way we don't have much info on it
            self.showQuorumNodeInfo(node: quorumNode)
        }
    }
    private func clearInfo() {
        self.quorumSetHashLabel?.text = " "
        self.publicKeyLabel?.text = " "
        self.cityLabel?.text = " "
        self.nameLabel?.text = " "
        self.nodesLabel?.text = " "
        self.leafsLabel?.text = " "
        self.depthLabel?.text = " "
        self.rootThresholdLabel?.text = " "
        self.verifiedCheckmark?.isHidden = true
    }
    private func showValidatorInfo(validator: Validator) {
        self.nameLabel?.text = "\(QuorumManager.handleForNodeId(id: validator.publicKey)). \(validator.name ?? "")"
        self.cityLabel?.text = validator.city ?? "[City]"
        self.publicKeyLabel?.text = "pk: " + validator.publicKey
        self.verifiedCheckmark?.isHidden = !validator.verified
        
        self.nodesLabel?.text = "n=\(validator.quorumSet.eventualValidators.count)"
        self.leafsLabel?.text = "l=\(validator.quorumSet.leafValidators)"
        self.depthLabel?.text = "d=\(validator.quorumSet.maxDepth)"
        self.showQuorumNodeInfo(node: validator.quorumSet)
    }
    private func showQuorumNodeInfo(node: QuorumNode) {
        // Limited QuorumNode (QuorumSet or ValidatorNode) info
        if node is QuorumValidator {
            self.publicKeyLabel?.text = "pk: " + node.identifier
        }
        else {
            self.quorumSetHashLabel?.text = "qsh: " + node.identifier
        }
        
        let thresholdString = "\(node.threshold)/\(node.quorumNodes.count)"
        if ( node.maxDepth ) > 1 {
            self.rootThresholdLabel?.text = "*" + thresholdString
        }
        else {
            self.rootThresholdLabel?.text = thresholdString
        }
    }
}
