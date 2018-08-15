//
//  Extensions.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/1/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

extension UINavigationController {
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return .all
    }
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension UIViewController {
    static func newVC() -> Self {
        func newVC<T: UIViewController>(_ viewType: T.Type) -> T {
            let t = String(describing: T.self)
            let storyboard = UIStoryboard(name: "\(t)", bundle: nil)
            return storyboard.instantiateViewController(withIdentifier: "\(t)") as! T
        }
        return newVC(self)
    }
}

// https://gist.github.com/mwermuth/07825df27ea28f5fc89a
extension UIBezierPath {
    class func getAxisAlignedArrowPoints(points: inout Array<CGPoint>, forLength: CGFloat, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat ) {
        let tailLength = forLength - headLength
        points.append(CGPoint(x: 0, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: tailWidth/2))
        points.append(CGPoint(x: tailLength, y: headWidth/2))
        points.append(CGPoint(x: forLength, y: 0))
        points.append(CGPoint(x: tailLength, y: -headWidth/2))
        points.append(CGPoint(x: tailLength, y: -tailWidth/2))
        points.append(CGPoint(x: 0, y: -tailWidth/2))
    }

    class func transformForStartPoint(startPoint: CGPoint, endPoint: CGPoint, length: CGFloat) -> CGAffineTransform{
        let cosine: CGFloat = (endPoint.x - startPoint.x)/length
        let sine: CGFloat = (endPoint.y - startPoint.y)/length
        return __CGAffineTransformMake(cosine, sine, -sine, cosine, startPoint.x, startPoint.y)
    }
    
    class func bezierPathWithArrowFromPoint(startPoint:CGPoint, endPoint: CGPoint, tailWidth: CGFloat, headWidth: CGFloat, headLength: CGFloat) -> UIBezierPath {
        let xdiff: Float = Float(endPoint.x) - Float(startPoint.x)
        let ydiff: Float = Float(endPoint.y) - Float(startPoint.y)
        let length = hypotf(xdiff, ydiff)
        
        var points = [CGPoint]()
        self.getAxisAlignedArrowPoints(points: &points, forLength: CGFloat(length), tailWidth: tailWidth, headWidth: headWidth, headLength: headLength)
        
        let transform: CGAffineTransform = self.transformForStartPoint(startPoint: startPoint, endPoint: endPoint, length:  CGFloat(length))
        
        let cgPath: CGMutablePath = CGMutablePath()
        cgPath.addLines(between: points, transform: transform)
        cgPath.closeSubpath()
        return UIBezierPath(cgPath: cgPath)
    }
}
