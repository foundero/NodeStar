//
//  AppDelegate.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 7/26/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

let nodeStarBlue: UIColor = UIColor(red: 24.0/255.0, green: 129.0/255.0, blue: 234.0/255.0, alpha: 1)
let nodeStarLightGreen: UIColor = UIColor(red: 220.0/255, green: 250.0/255, blue: 220.0/255, alpha: 1.0)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window?.backgroundColor = UIColor.white
        return true
    }
}
