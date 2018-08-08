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
