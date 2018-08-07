//
//  NodeLinesOverlayView.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/1/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class NodeLinesOverlayView: UIView {
    
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
        let fromBottom = CGPoint(x: from.bounds.size.width/2.0, y: to.bounds.size.height)
        let toTopY = max(0, (to.bounds.size.height - to.bounds.size.width)) / 2.0
        let toTop = CGPoint(x: to.bounds.size.width/2.0, y: toTopY)
        let controlPoint = CGPoint(x: fromBottom.x, y: fromBottom.y + 30)
        path.move(to: convert(fromBottom, from: from))
        path.addQuadCurve(to: convert(toTop, from: to), controlPoint: convert(controlPoint, from: from))
        path.lineWidth = 0.5
        
        // Add it to list - which will eventually redraw (setNeedsDisplay)
        paths.append(path)
    }
    
    // MARK: Drawign
    override func draw(_ rect: CGRect) {
        UIColor.darkGray.setStroke()
        for path in paths {
            path.stroke()
        }
    }
}
