//
//  MathVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/9/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class MathVC: UIViewController {
    static let mathNames = ["Impact Metrics", "Simple Quorum", "Recursive Quorum"]
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mathNumber = MathVC.mathNames.index(of: title ?? "") ?? 0
        setImage(image: UIImage(named: "math\(mathNumber+1)")!)
    }
    
    override func viewDidLayoutSubviews() {
        let mathNumber = MathVC.mathNames.index(of: title ?? "") ?? 0
        setImage(image: UIImage(named: "math\(mathNumber+1)")!)
    }
    
    private func setImage(image: UIImage) {
        imageView.image = image
        let viewSize = CGSize(width: view.bounds.size.width - 40,
                              height: view.bounds.size.height - 40)
        let imageAspectRatio = image.size.width / image.size.height
        let viewAspectRatio = viewSize.width / viewSize.height
        if imageAspectRatio > viewAspectRatio {
            widthConstraint.constant = min(image.size.width, viewSize.width)
            heightConstraint.constant = widthConstraint.constant / imageAspectRatio
        }
        else {
            heightConstraint.constant = min(image.size.height, viewSize.height)
            widthConstraint.constant = heightConstraint.constant * imageAspectRatio
        }
        view.layoutIfNeeded()
    }
}

class MathListVC: UITableViewController {
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Math"
        tableView.cellLayoutMarginsFollowReadableWidth = false
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
    }
    
    // MARK: Table View
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MathVC.mathNames.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(indexPath.row+1). " + MathVC.mathNames[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = MathVC.newVC()
        vc.title = MathVC.mathNames[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
