//
//  ViewController.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import UIKit
import RealityKit
import Combine
import MultipeerHelper

class GameViewController: UIViewController {
    @IBOutlet var arView: ARView!
    
    @IBOutlet weak var gameInfoStackView: UIStackView!
    @IBOutlet weak var coinsLabel: UILabel!
    @IBOutlet weak var hpLabel: UILabel!
    @IBOutlet weak var waveLabel: UILabel!
    
    @IBOutlet weak var stripTableView: UITableView!
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var menuHeightConstraint: NSLayoutConstraint!
    
    private var cancellables: Set<AnyCancellable> = .init()

    lazy var menuViewModel: MenuViewModelProtocol = { return MenuViewModel() }()
    lazy var stripViewModel: GameViewModelProtocol = { return GameViewModel() }()

    var stripContext: [CellViewModelProtocol] = .init()
    var menuContext: [MenuCellViewModelProtocol] = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservables()
    }
    
    func setupUI() {
        gameInfoStackView.isHidden = true
    }
    
    func setupObservables() {
        menuViewModel.viewStatePublisher.receive(on: RunLoop.main).sink { viewState in
            switch viewState {
            case .empty: break
            case .showContext(let context):
                DispatchQueue.main.async { [weak self] in
                    self?.menuContext = context
                    let newHeight = CGFloat(context.map({$0.contentHeight}).reduce(0.0, +))
                    let maxHeight =  UIScreen.main.bounds.height
                    self?.menuTableView.isScrollEnabled = newHeight >= maxHeight
                    self?.menuHeightConstraint.constant = min(newHeight, maxHeight)
                    self?.menuTableView.reloadData()
                }
            }
        }.store(in: &cancellables)
        menuViewModel.toStartMenu()
    }
}
