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
    private var arrowPaths: [UIBezierPath] = [] { didSet { setNeedsDisplay() } }
    
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
    func overlayOnView(_ view: UIView, belowSubview: UIView? = nil) {
        translatesAutoresizingMaskIntoConstraints = false
        if belowSubview != nil {
            view.insertSubview(self, belowSubview: belowSubview!)
        }
        else {
            view.addSubview(self)
        }
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
        
        // Constants
        let arrowLength: CGFloat = 8.0
        let arrowWidth: CGFloat = 5.0
        
        
        // Create path from pnv to nv
        var fromAngle: CGFloat = 0
        var toAngle: CGFloat = 0
        var cp1RadiusAdd: CGFloat = arrowLength * 5
        var cp2RadiusAdd: CGFloat = arrowLength * 5
        if from === to {
            // to self
            fromAngle = CGFloat(0.0)
            toAngle = CGFloat(Double.pi*1.0/4.0)
            cp1RadiusAdd = arrowLength * 2
            cp2RadiusAdd = arrowLength * 3
        }
        else if from.row == 1 && to.row == 1 {
            // to the right
            fromAngle = CGFloat(-Double.pi*1.0/4.0)
            toAngle = CGFloat(Double.pi*3.0/4.0)
        }
        else {
            // to a node above
            fromAngle = CGFloat(-Double.pi/2.0)
            toAngle = CGFloat(Double.pi/2.0)
        }
        let fromPoint = pointOnCircle(view: from, radians: fromAngle)
        let toPoint = pointOnCircle(view: to, radians: toAngle)
        let toPointWithArrow = pointOnCircle(view: to, radiusAdd: arrowLength, radians: toAngle)
        let cp1 = pointOnCircle(view: from, radiusFactor: 1, radiusAdd: cp1RadiusAdd, radians: fromAngle)
        let cp2 = pointOnCircle(view: to, radiusFactor: 1, radiusAdd: cp2RadiusAdd, radians: toAngle)
        
        let path = UIBezierPath()
        path.lineWidth = 0.5
        if from.row==2 && to.row==0 {
            // might interset with node or other lines
            path.setLineDash([2,2], count: 2, phase: 0.0)
        }
        path.move(to: convert(fromPoint, from: from))
        path.addCurve(to: convert(toPointWithArrow, from: to),
                      controlPoint1: convert(cp1, from: from),
                      controlPoint2: convert(cp2, from: to))
        
        let arrowPath = UIBezierPath.bezierPathWithArrowFromPoint(startPoint: convert(toPointWithArrow, from: to),
                                                                  endPoint: convert(toPoint, from: to),
                                                                  tailWidth: 0,
                                                                  headWidth: arrowWidth,
                                                                  headLength: arrowLength)

        // Add paths - which will eventually redraw (setNeedsDisplay)
        paths.append(path)
        arrowPaths.append(arrowPath)
    }
    
    // MARK: Drawign
    override func draw(_ rect: CGRect) {
        UIColor.darkGray.setStroke()
        UIColor.darkGray.setFill()
        for path in paths {
            path.stroke()
        }
        for path in arrowPaths {
            path.stroke()
            path.fill()
        }
    }
    
    // MARK: Math
    private func pointOnCircle(view: UIView,
                               radiusFactor: CGFloat = 1.0,
                               radiusAdd: CGFloat = 0.0,
                               radians: CGFloat) -> CGPoint {
        let r: CGFloat = radiusFactor * (radiusAdd + min(view.bounds.size.width/2.0, view.bounds.size.height/2.0))
        let x: CGFloat = view.bounds.size.width/2.0 + r * cos(radians)
        let y: CGFloat = view.bounds.size.height/2.0 + r * sin(radians)
        return CGPoint(x: x, y: y)
    }
}
