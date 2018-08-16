//
//  ClusterVC.swift
//  NodeStar
//
//  Created by Jeff DiTullio on 8/14/18.
//  Copyright © 2018 Foundero Inc. All rights reserved.
//

import UIKit

class ClusterVC: UIViewController, ClusterViewDelegate {

    var clusters: [Cluster] = []
    
    @IBOutlet var verticalStackView: UIStackView!
    var rowStackViews: [UIStackView] = []
    var linesOverlayView: LinesOverlayView!
    var clusterViews: [ClusterView] = []
    var selectedClusterView: ClusterView! { didSet { redrawSelectClusterView() } }
    
    @IBOutlet weak var labelValidators: UILabel!
    @IBOutlet weak var labelIncoming: UILabel!
    @IBOutlet weak var labelOutgoing: UILabel!
    @IBOutlet weak var labelSelfRef: UILabel!
    @IBOutlet weak var labelUnkown: UILabel!
    
    // MARK: View Loading
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style:.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "definitions",
                                                            style:.plain,
                                                            target: self,
                                                            action: #selector(tappedDefinitionsButton))
        
        // Create the rows and show the clusters
        createRow(row: 0)
        createRow(row: 1)
        createRow(row: 2)
        showNodes(showClusters: clusters, bestCount: Cluster.bestClusterIncomingCount(clusters: clusters))
        
        // Offset rows a bit so line from bottom to top don't go through middle row nodes
        let bottomOdd = rowStackViews[2].arrangedSubviews.count % 2
        let middleOdd = rowStackViews[1].arrangedSubviews.count % 2
        let topOdd = rowStackViews[0].arrangedSubviews.count % 2
        if bottomOdd == middleOdd && middleOdd == topOdd {
            rowStackViews[2].layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
            rowStackViews[1].layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        }
        
        
        // Setup the view to draw lines on
        linesOverlayView = LinesOverlayView()
        linesOverlayView.overlayOnView(view, belowSubview: verticalStackView)
        
        // Select best cluster
        let bestCluster = clusters.last
        let bestClusterView = clusterViews.first {
            return $0.cluster === bestCluster
        }!
        selectedClusterView = bestClusterView
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    private func redrawSelectClusterView() {
        for cv in clusterViews {
            cv.selected = cv == selectedClusterView
        }
        
        let cluster: Cluster = selectedClusterView.cluster
        labelValidators.text = "Validators: \(cluster.nodes.count)"
        labelIncoming.text = "Incoming (u'): \(cluster.incoming.count)"
        labelOutgoing.text = "Outgoing (n'): \(cluster.outgoing.count)"
        labelSelfRef.text = "Self Ref: \(cluster.outgoingClusters.contains{$0===cluster})"
        labelUnkown.text = "Unknown: \(cluster.outgoingUnknown.count)"
    }
    
    
    // MARK: -- Visualize Nodes
    func createRow(row: Int) {
        let padding: CGFloat = 10.0
        
        // Create a stackView For the row
        let stackView = UIStackView(frame: CGRect.null)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackViewDistribution.fillEqually
        stackView.alignment = UIStackViewAlignment.center
        stackView.axis = .horizontal
        verticalStackView.addArrangedSubview(stackView)
        stackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // Give it a background that changes color based on row
        // But put it behind view
        let background = UIView(frame: CGRect.null)
        background.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(background, at: 0)
        view.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .top,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .leading,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .trailing,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        view.addConstraint(NSLayoutConstraint(item: background,
                                                   attribute: .bottom,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .bottom,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        
        // Give the row a label
        let rowLabel = UILabel(frame: CGRect.null)
        rowLabel.translatesAutoresizingMaskIntoConstraints = false
        let rowStuff: [(String,UIColor)] = [(" best clusters ", UIColor(white: 0.96, alpha: 1.0)),
                                            (" clusters ", UIColor(white: 0.90, alpha: 1.0)),
                                            (" unused clusters ", UIColor.brown.withAlphaComponent(0.5))]
        rowLabel.text = rowStuff[row].0
        background.backgroundColor = rowStuff[row].1
        rowLabel.font = UIFont.systemFont(ofSize: 10.0)
        rowLabel.backgroundColor = UIColor.white
        stackView.addSubview(rowLabel)
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel,
                                                   attribute: .top,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .top,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        stackView.addConstraint(NSLayoutConstraint(item: rowLabel,
                                                   attribute: .trailing,
                                                   relatedBy: .equal,
                                                   toItem: stackView,
                                                   attribute: .trailing,
                                                   multiplier: 1.0,
                                                   constant: 0.0))
        
        // Add the row to the view
        rowStackViews.append(stackView)
    }
    
    func showNodes(showClusters: [Cluster], bestCount: Int) {
        
        // Show this node in the row stack view
        for c in showClusters {
            let cv: ClusterView = ClusterView()
            cv.cluster = c
            cv.update()
            cv.delegate = self
            if c.incoming.count == 0 {
                cv.row = 2
            }
            else if c.incoming.count == bestCount {
                cv.row = 0
            }
            else {
                cv.row = 1
            }
            rowStackViews[cv.row].addArrangedSubview(cv)
            clusterViews.append(cv)
        }
    }
    
    override func viewDidLayoutSubviews() {
        // Draw the lines between nodes
        linesOverlayView.clearLines()
        for parentcv in clusterViews {
            for childCluster in parentcv.cluster.outgoingClusters {
                let childcv: ClusterView = clusterViews.first {
                    return $0.cluster === childCluster
                }!
                linesOverlayView.addLine(from: parentcv, to: childcv)
            }
        }
    }
    
    
    // MARK: -- ClusterViewDelegate
    func clusterViewTapped(clusterView: ClusterView) {
        selectedClusterView = clusterView
    }
    func clusterViewDoubleTapped(clusterView: ClusterView) {
        selectedClusterView = clusterView
        clusterButtonTapped()
    }
    
    // MARK: -- UI Interaction
    @IBAction func clusterButtonTapped() {
        let vc = ClusterDetailVC()
        vc.cluster = selectedClusterView.cluster!
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func tappedDefinitionsButton() {
        let vc = InfoVC.newVC()
        navigationController?.pushViewController(vc, animated: true)
    }
}

