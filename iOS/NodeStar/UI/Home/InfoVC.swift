//
//  InfoVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/8/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class InfoVC: UITableViewController {
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "math",
                                                            style:.plain,
                                                            target: self,
                                                            action: #selector(tappedMathButton))
    }
    
    @objc func tappedMathButton() {
        let vc = MathListVC()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
