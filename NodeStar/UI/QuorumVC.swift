//
//  QuorumVC.swift
//  NodeStar
//
//  Created by jeff on 7/30/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class QuorumVC: UIViewController, NodeViewDelegate {
    
    @IBOutlet var verticalStackView: UIStackView?
    var rowStackViews: [UIStackView] = []
    var pathView: PathView!
    var nodeViews: [NodeView] = []
    
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
    
    // MARK -- View Controller Stuff
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "QuorumSet - " + QuorumManager.handleForNodeId(id: self.validator.publicKey)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        
        self.showNodes(quorumNode: self.validator.quorumSet, depth: 0, parentNodeView: nil)

        // Setup the view to draw lines on
        self.pathView = PathView()
        self.pathView.isUserInteractionEnabled = false
        pathView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pathView)
        NSLayoutConstraint.activate([
            pathView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pathView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pathView.topAnchor.constraint(equalTo: view.topAnchor),
            pathView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        pathView.backgroundColor = .clear
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK -- Visualize Nodes
    
    func createRow(row: Int) {
        let padding: CGFloat = 10.0
        
        let stackView = UIStackView(frame: CGRect.null)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        stackView.axis = .horizontal
        self.verticalStackView?.addArrangedSubview(stackView)
        stackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        let background = UIView(frame: CGRect.null)
        background.translatesAutoresizingMaskIntoConstraints = false
        background.backgroundColor = UIColor.brown.withAlphaComponent( (CGFloat(self.validator.quorumSet.maxDepth + 1) - CGFloat(row)) / CGFloat(self.validator.quorumSet.maxDepth + 1) )
        stackView.addSubview(background)
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .top, relatedBy: .equal, toItem: stackView, attribute: .top, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .leading, relatedBy: .equal, toItem: stackView, attribute: .leading, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .trailing, relatedBy: .equal, toItem: stackView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: background, attribute: .bottom, relatedBy: .equal, toItem: stackView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        
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
        
        self.rowStackViews.append(stackView)
    }
    
    func showNodes(quorumNode: QuorumNode, depth: Int, parentNodeView: NodeView?) {
        // Create StackView if needed
        if self.rowStackViews.count < depth+1 {
            self.createRow(row: depth)
        }
        
        // Show this one
        let nv: NodeView = NodeView(frame: CGRect.null)
        nv.quorumNode = quorumNode
        nv.parentNodeView = parentNodeView
        nv.update()
        if depth == 0 {
            nv.updateAsRoot(validator: self.validator)
            self.nodeViewTapped(nodeView: nv)
        }
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
        // Draw the lines
        self.view.layoutIfNeeded()
        var paths: [UIBezierPath] = []
        for nv in self.nodeViews {
            if let pnv: NodeView = nv.parentNodeView {
                // Draw from pnv to nv
                let path = UIBezierPath()
                let pnvBottom = CGPoint(x: pnv.bounds.size.width/2.0, y: pnv.bounds.size.height)
                let nvTop = CGPoint(x: nv.bounds.size.width/2.0, y: (max(0, (nv.bounds.size.height - nv.bounds.size.width))) / 2.0)
                let controlPoint = CGPoint(x: pnvBottom.x, y: pnvBottom.y + 30)
                path.move(to: self.view.convert(pnvBottom, from: pnv))
                path.addQuadCurve(to: self.view.convert(nvTop, from: nv), controlPoint: self.view.convert(controlPoint, from: pnv))
                path.lineWidth = 0.5
                paths.append(path)
            }
        }
        self.pathView.paths = paths
    }
    
    // MARK -- NodeViewDelegate
    func nodeViewTapped(nodeView: NodeView) {
        self.showNodeInfo(quorumNode: nodeView.quorumNode)
    }
    func nodeViewDoubleTapped(nodeView: NodeView) {
        self.showNodeInfo(quorumNode: nodeView.quorumNode)
        // If we can find the full info then go to it
        if let validator: Validator = QuorumManager.validatorForId(id: nodeView.quorumNode.identifier) {
            self.pushValidatorNode(validator: validator)
        }
    }
    
    // MARK -- Navigate
    private func pushValidatorNode(validator: Validator) {
        let storyboard = UIStoryboard(name: "QuorumVC", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "QuorumVC") as! QuorumVC
        vc.validator = validator
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK -- Display Detail
    private func showNodeInfo(quorumNode: QuorumNode) {
        self.clearInfo()
        
        // Root node show both validator and quorum...
        if quorumNode.identifier == self.validator.quorumSet.identifier {
            self.showValidatorInfo(validator: self.validator)
        }
        else if let validator: Validator = QuorumManager.validatorForId(id: quorumNode.identifier) {
            self.showValidatorInfo(validator: validator)
        }
        else {
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

class PathView: UIView {
    var paths: [UIBezierPath] = [] { didSet { setNeedsDisplay() } }
    override func draw(_ rect: CGRect) {
        UIColor.darkGray.setStroke()
        for path in paths {
            path.stroke()
        }
    }
}
