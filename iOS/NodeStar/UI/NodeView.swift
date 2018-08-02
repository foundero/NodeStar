//
//  NodeView.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/30/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit


protocol NodeViewDelegate {
    func nodeViewTapped(nodeView: NodeView)
    func nodeViewDoubleTapped(nodeView: NodeView)
}

class NodeView: UIView {
    var delegate: NodeViewDelegate?
    var quorumNode: QuorumNode!
    var parentNodeView: NodeView?
    var selected: Bool = false { didSet { setNeedsDisplay() } }
    
    private var nameLabel: UILabel!
    private var thresholdLabel: UILabel!
    private var borderColor: UIColor = UIColor.blue
    private var fillColor: UIColor = UIColor.white
    
    init() {
        super.init(frame: CGRect.null)
        sharedInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    private func sharedInit() {
        self.backgroundColor = UIColor.clear
        self.contentMode = UIViewContentMode.redraw
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap(recognizer:)))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap(recognizer:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        self.addGestureRecognizer(tapGesture)
        self.addGestureRecognizer(doubleTapGesture)
        
        self.thresholdLabel = UILabel(frame: CGRect.null)
        self.thresholdLabel.translatesAutoresizingMaskIntoConstraints = false
        self.thresholdLabel.font = UIFont.systemFont(ofSize: 8)
        self.addSubview(self.thresholdLabel)
        self.addConstraint(NSLayoutConstraint(item: self.thresholdLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -6.0))
        self.addConstraint(NSLayoutConstraint(item: self.thresholdLabel, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        
        self.nameLabel = UILabel(frame: CGRect.null)
        self.nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.nameLabel.font = UIFont.systemFont(ofSize: 14)
        self.nameLabel.adjustsFontSizeToFitWidth = true
        self.nameLabel.minimumScaleFactor = 0.5
        self.nameLabel.textAlignment = NSTextAlignment.center
        self.addSubview(self.nameLabel)
        self.addConstraint(NSLayoutConstraint(item: self.nameLabel, attribute: .top, relatedBy: .equal, toItem:self , attribute: .top, multiplier: 1.0, constant: 8.0))
        self.addConstraint(NSLayoutConstraint(item: self.nameLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 4.0))
        self.addConstraint(NSLayoutConstraint(item: self.nameLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -4.0))
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 40.0, height: 40.0)
    }
    
    
    // MARK: Public Methods
    func update() {
        if self.quorumNode is QuorumValidator {
            // Leaf
            self.borderColor = UIColor.black
            self.fillColor = UIColor.white
            self.thresholdLabel.text = ""
            self.thresholdLabel.text = ""
            self.nameLabel.text = QuorumManager.handleForNodeId(id: self.quorumNode.identifier)
            if QuorumManager.validatorForId(id: self.quorumNode.identifier)?.verified == true {
                self.fillColor = nodeStarLightGreen
            }
        }
        else {
            // Quorum Set
            self.borderColor = UIColor.black.withAlphaComponent(0.5)
            self.fillColor = UIColor.white.withAlphaComponent(0.5)
            self.thresholdLabel.text = "\(quorumNode.threshold)/\(quorumNode.quorumNodes.count)"
            self.nameLabel.text = ""
        }
        self.setNeedsDisplay()
    }
    func updateAsRoot(validator: Validator) {
        self.nameLabel.text = QuorumManager.handleForNodeId(id: validator.publicKey)
        if validator.verified == true {
            self.fillColor = nodeStarLightGreen.withAlphaComponent(0.5)
        }
        self.setNeedsDisplay()
    }
    
    
    // MARK: Gestures
    @objc func tap(recognizer : UITapGestureRecognizer) {
        self.delegate?.nodeViewTapped(nodeView: self)
    }
    @objc func doubleTap(recognizer : UITapGestureRecognizer) {
        self.delegate?.nodeViewDoubleTapped(nodeView: self)
    }
    
    
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        drawRingFittingInsideView()
    }
    // https://stackoverflow.com/questions/29616992/how-do-i-draw-a-circle-in-ios-swift
    internal func drawRingFittingInsideView()->() {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        var desiredLineWidth:CGFloat = 2.0
        if self.selected {
            desiredLineWidth = 5.0
        }
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:bounds.size.width/2,y:bounds.size.height/2),
            radius: CGFloat( halfSize - (desiredLineWidth/2) ),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true)
        
        self.borderColor.setStroke()
        self.fillColor.setFill()
        circlePath.lineWidth = desiredLineWidth
        circlePath.stroke()
        circlePath.fill()
    }
}
