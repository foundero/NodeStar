//
//  ClusterView.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/15/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit
import FittableFontLabel

protocol ClusterViewDelegate {
    func clusterViewTapped(clusterView: ClusterView)
    func clusterViewDoubleTapped(clusterView: ClusterView)
}

class ClusterView: UIView {
    var delegate: ClusterViewDelegate?
    var cluster: Cluster!
    var row: Int = 0
    var parentClusterView: ClusterView?
    var selected: Bool = false { didSet { setNeedsDisplay() } }
    
    private var countLabel: UILabel!
    private var incomingLabel: UILabel!
    private var borderColor: UIColor = UIColor.black
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
        backgroundColor = UIColor.clear
        contentMode = UIViewContentMode.redraw
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(recognizer:)))
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(recognizer:)))
        doubleTapGesture.numberOfTapsRequired = 2
        tapGesture.require(toFail: doubleTapGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(doubleTapGesture)
        
        incomingLabel = UILabel(frame: CGRect.null)
        incomingLabel.translatesAutoresizingMaskIntoConstraints = false
        incomingLabel.font = UIFont.systemFont(ofSize: 10)
        addSubview(incomingLabel)
        addConstraint(NSLayoutConstraint(item: incomingLabel,
                                         attribute: .bottom,
                                         relatedBy: .equal,
                                         toItem: self,
                                         attribute: .bottom,
                                         multiplier: 1.0,
                                         constant: -6.0))
        addConstraint(NSLayoutConstraint(item: incomingLabel,
                                         attribute: .centerX,
                                         relatedBy: .equal,
                                         toItem: self,
                                         attribute: .centerX,
                                         multiplier: 1.0,
                                         constant: 0.0))
        
        countLabel = UILabel(frame: CGRect.null)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = UIFont.systemFont(ofSize: 17)
        countLabel.adjustsFontSizeToFitWidth = true
        countLabel.minimumScaleFactor = 0.3
        countLabel.textAlignment = NSTextAlignment.center
        addSubview(countLabel)
        addConstraint(NSLayoutConstraint(item: countLabel,
                                         attribute: .height,
                                         relatedBy: .equal,
                                         toItem: nil,
                                         attribute: .notAnAttribute,
                                         multiplier: 1.0,
                                         constant: 26.0))
        addConstraint(NSLayoutConstraint(item: countLabel,
                                         attribute: .centerY,
                                         relatedBy: .equal,
                                         toItem: self,
                                         attribute: .centerY,
                                         multiplier: 1.0,
                                         constant: 0.0))
        addConstraint(NSLayoutConstraint(item: countLabel,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: self,
                                         attribute: .leading,
                                         multiplier: 1.0,
                                         constant: 1.0))
        addConstraint(NSLayoutConstraint(item: countLabel,
                                         attribute: .trailing,
                                         relatedBy: .equal,
                                         toItem: self,
                                         attribute: .trailing,
                                         multiplier: 1.0,
                                         constant: -1.0))
    }
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: 60.0, height: 60.0)
    }
    
    
    // MARK: Public Methods
    func update() {
        countLabel.text = "\(cluster.nodes.count)"
        incomingLabel.text = "\(cluster.incoming.count)"
        setNeedsDisplay()
    }
    
    
    // MARK: Gestures
    @objc func tap(recognizer : UITapGestureRecognizer) {
        delegate?.clusterViewTapped(clusterView: self)
    }
    @objc func doubleTap(recognizer : UITapGestureRecognizer) {
        delegate?.clusterViewDoubleTapped(clusterView: self)
    }
    
    
    // MARK: Drawing
    override func draw(_ rect: CGRect) {
        if selected {
            countLabel.font = UIFont.boldSystemFont(ofSize: 17)
        }
        else {
            countLabel.font = UIFont.systemFont(ofSize: 17)
        }
        drawRingFittingInsideView()
    }
    // https://stackoverflow.com/questions/29616992/how-do-i-draw-a-circle-in-ios-swift
    internal func drawRingFittingInsideView()->() {
        let halfSize:CGFloat = min( bounds.size.width/2, bounds.size.height/2)
        var desiredLineWidth:CGFloat = 0.5
        if selected {
            desiredLineWidth = 3.0
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
        circlePath.stroke()
    }
}
