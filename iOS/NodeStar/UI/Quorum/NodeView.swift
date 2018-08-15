//
//  NodeView.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/30/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit
import FittableFontLabel

protocol NodeViewDelegate {
    func nodeViewTapped(nodeView: NodeView)
    func nodeViewDoubleTapped(nodeView: NodeView)
}

class NodeView: UIView {
    var delegate: NodeViewDelegate?
    var quorumNode: QuorumNode!
    var quorumMetrics: QuorumMetrics!
    var parentNodeView: NodeView?
    var selected: Bool = false { didSet { setNeedsDisplay() } }
    
    private var nameLabel: UILabel!
    private var thresholdLabel: UILabel!
    private var borderColor: UIColor = UIColor.black
    private var fillColor: UIColor = UIColor.white
    
    func adjustedFontSize() -> CGFloat {
        return self.nameLabel.fontSizeThatFits(text: nameLabel.text ?? "",
                                               maxFontSize: 14,
                                               minFontScale: 0.3,
                                               rectSize: nil)
    }
    func setFontSize(size: CGFloat) {
        nameLabel.font = UIFont.systemFont(ofSize: size)
    }
    
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
        backgroundColor = UIColor.clear
        contentMode = UIViewContentMode.redraw
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:)))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(recognizer:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(doubleTapGesture)
        
        thresholdLabel = UILabel(frame: CGRect.null)
        thresholdLabel.translatesAutoresizingMaskIntoConstraints = false
        thresholdLabel.font = UIFont.systemFont(ofSize: 10)
        addSubview(thresholdLabel)
        addConstraint(NSLayoutConstraint(item: thresholdLabel,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .bottom,
                                              multiplier: 1.0,
                                              constant: -6.0))
        addConstraint(NSLayoutConstraint(item: thresholdLabel,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .centerX,
                                              multiplier: 1.0,
                                              constant: 0.0))
        
        nameLabel = UILabel(frame: CGRect.null)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.3
        nameLabel.textAlignment = NSTextAlignment.center
        addSubview(nameLabel)
        addConstraint(NSLayoutConstraint(item: nameLabel,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .notAnAttribute,
                                         multiplier: 1.0,
                                         constant: 22.0))
        addConstraint(NSLayoutConstraint(item: nameLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .top,
                                              multiplier: 1.0,
                                              constant: 8.0))
        addConstraint(NSLayoutConstraint(item: nameLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .leading,
                                              multiplier: 1.0,
                                              constant: 1.0))
        addConstraint(NSLayoutConstraint(item: nameLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: self,
                                              attribute: .trailing,
                                              multiplier: 1.0,
                                              constant: -1.0))
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 40.0, height: 40.0)
    }
    
    
    // MARK: Public Methods
    func update() {
        if quorumNode is QuorumValidator {
            // Leaf
            fillColor = UIColor.white
            thresholdLabel.text = ""
            thresholdLabel.text = ""
            nameLabel.text = QuorumManager.handleForNodeId(id: quorumNode.identifier)
            if QuorumManager.validatorForId(id: quorumNode.identifier)?.verified == true {
                fillColor = nodeStarLightGreen
            }
        }
        else {
            // Quorum Set
            fillColor = UIColor.lightGray
            thresholdLabel.text = "\(quorumNode.threshold)/\(quorumNode.quorumNodes.count)"
            nameLabel.text = ""
        }
        setNeedsDisplay()
    }
    func updateAsRoot(validator: Validator) {
        nameLabel.text = QuorumManager.handleForNodeId(id: validator.publicKey)
        setNeedsDisplay()
    }
    
    
    // MARK: Gestures
    @objc func tap(recognizer : UITapGestureRecognizer) {
        delegate?.nodeViewTapped(nodeView: self)
    }
    @objc func doubleTap(recognizer : UITapGestureRecognizer) {
        delegate?.nodeViewDoubleTapped(nodeView: self)
    }
    
    
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        if selected {
            nameLabel.font = UIFont.boldSystemFont(ofSize: 14)
            thresholdLabel.font = UIFont.boldSystemFont(ofSize: 10)
        }
        else {
            nameLabel.font = UIFont.systemFont(ofSize: 14)
            thresholdLabel.font = UIFont.systemFont(ofSize: 10)
        }
        drawRingFittingInsideView()
    }
    // https://stackoverflow.com/questions/29616992/how-do-i-draw-a-circle-in-ios-swift
    internal func drawRingFittingInsideView()->() {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        var desiredLineWidth:CGFloat = 0.5
        if selected {
            desiredLineWidth = 2.0
        }
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x:bounds.size.width/2.0,y:bounds.size.height/2.0),
            radius: CGFloat( halfSize - (desiredLineWidth/2.0) ),
            startAngle: CGFloat(0),
            endAngle:CGFloat(Double.pi * 2),
            clockwise: true)
        
        borderColor.setStroke()
        fillColor.setFill()
        circlePath.lineWidth = desiredLineWidth
        circlePath.fill()
        if quorumNode is QuorumValidator || selected {
            circlePath.stroke()
        }
        
        if selected {
            // Draw the metrics as concentric circles on each node
            for (index, (metric, color)) in [(quorumMetrics.affect, nodeStarBlue),
                                             (quorumMetrics.require, UIColor.red),
                                             (quorumMetrics.influence, nodeStarGreen)].enumerated()
            {
                let radius =  CGFloat( halfSize - (desiredLineWidth*CGFloat(index + 1) - desiredLineWidth/2.0) )
                let circlePathInner = UIBezierPath(
                    arcCenter: CGPoint(x:bounds.size.width/2.0,y:bounds.size.height/2.0),
                    radius:radius,
                    startAngle: CGFloat(-Double.pi/2.0),
                    endAngle:CGFloat(Double.pi * 2 * metric - Double.pi/2.0),
                    clockwise: true)
                color.setStroke()
                circlePathInner.lineWidth = desiredLineWidth
                circlePathInner.stroke()
            }
        }
    }
}
