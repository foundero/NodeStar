//
//  LinesOverlayView.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/1/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class LinesOverlayView: UIView {
    
    private var paths: [UIBezierPath] = [] { didSet { setNeedsDisplay() } }
    
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
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    // MARK: Public Methods
    func overlayOnView(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
    
    func clearLines() {
        paths = []
    }
    
    func addLine(from: NodeView, to: NodeView) {
        // Make sure autolayout is done first
        superview?.layoutIfNeeded()
        
        // Create path from pnv to nv
        let path = UIBezierPath()
        let fromBottom = CGPoint(x: from.bounds.size.width/2.0, y: from.bounds.size.height)
        let toTopY = max(0, (to.bounds.size.height - to.bounds.size.width)) / 2.0
        let toTop = CGPoint(x: to.bounds.size.width/2.0, y: toTopY)
        let controlPoint = CGPoint(x: fromBottom.x, y: fromBottom.y + 30)
        path.move(to: convert(fromBottom, from: from))
        path.addQuadCurve(to: convert(toTop, from: to), controlPoint: convert(controlPoint, from: from))
        path.lineWidth = 0.5
        
        // Add it to list - which will eventually redraw (setNeedsDisplay)
        paths.append(path)
    }
    
    func addLine(from: ClusterView, to: ClusterView) {
        // Make sure autolayout is done first
        superview?.layoutIfNeeded()
        
        // Create path from pnv to nv
        let path = UIBezierPath()
        path.lineWidth = 0.5
        let arrowHeight: CGFloat = 12.0
        
        let fromTopY = max(0, (from.bounds.size.height - from.bounds.size.width)) / 2.0
        let fromTop = CGPoint(x: from.bounds.size.width/2.0, y: fromTopY)
        let toBottom = CGPoint(x: to.bounds.size.width/2.0, y: to.bounds.size.height + arrowHeight)
        if from === to {
             let diameter = min(from.bounds.size.width, from.bounds.size.height)
             let cp1 = CGPoint(x: from.bounds.size.width/2.0 + 1*diameter, y: -0.6*diameter)
             let cp2 = CGPoint(x: from.bounds.size.width/2.0 + 0.8*diameter, y: diameter*1.8)
             path.move(to: convert(fromTop, from: from))
             path.addCurve(to: convert(toBottom, from: to),
             controlPoint1: convert(cp1, from: from),
             controlPoint2: convert(cp2, from: from))
        }
        else {
            let cp1 = CGPoint(x: fromTop.x, y: fromTopY - 30)
            path.move(to: convert(fromTop, from: from))
            path.addQuadCurve(to: convert(toBottom, from: to), controlPoint: convert(cp1, from: from))
        }
        // Add it to list - which will eventually redraw (setNeedsDisplay)
        paths.append(path)
        
        // Add the arrow
        let arrowBottom = convert(toBottom, from: to)
        let arrowTop = CGPoint(x: arrowBottom.x, y: arrowBottom.y-arrowHeight)
        let arrowPath = UIBezierPath.bezierPathWithArrowFromPoint(startPoint: arrowBottom,
                                                                  endPoint: arrowTop,
                                                                  tailWidth: 0,
                                                                  headWidth: 10,
                                                                  headLength: arrowHeight)
        paths.append(arrowPath)
    }
    
    // MARK: Drawign
    override func draw(_ rect: CGRect) {
        UIColor.darkGray.setStroke()
        for path in paths {
            path.stroke()
        }
    }
}
