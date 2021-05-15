//
//  ViewController.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import UIKit
import ARKit
import RealityKit
import Combine
import MultipeerHelper
import FocusEntity

class GameViewController: UIViewController {
    @IBOutlet var arView: ARView!
    var arConfig: ARWorldTrackingConfiguration!
    var multipeerHelper: MultipeerHelper!
    
    @IBOutlet weak var gameInfoStackView: UIStackView!
    @IBOutlet weak var coinsLabel: UILabel!
    @IBOutlet weak var hpLabel: UILabel!
    @IBOutlet weak var waveLabel: UILabel!
    
    @IBOutlet weak var stripTableView: UITableView!
    
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var menuHeightConstraint: NSLayoutConstraint!
    
    var focusEntity: FocusEntity?
    var canRayCast: Bool = true
    private var cancellables: Set<AnyCancellable> = .init()
    
    lazy var menuViewModel: MenuViewModelProtocol = { return MenuViewModel() }()
    lazy var gameViewModel: GameViewModelProtocol = { return GameViewModel(arView: arView) }()
    
    var stripContext: [CellViewModelProtocol] = .init()
    var menuContext: [MenuCellViewModelProtocol] = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenuObservables()
        setupGameObservables()
        setupMenuTableView()
        setupStrip()
    }
    
    func setupUI() {
        gameInfoStackView.isHidden = true
    }
    
    func setupMenuTableView() {
        menuTableView.register(CreepEnciclopediaViewCell.self)
        menuTableView.register(TowerEnciclopediaViewCell.self)
        menuTableView.register(MenuTableViewCell.self)
        menuTableView.register(HeaderTableViewCell.self)
        menuTableView.register(SettingsViewCell.self)
    }
    
    func setupMenuObservables() {
        menuViewModel.viewStatePublisher.receive(on: RunLoop.main).sink { [weak self] viewState in
            switch viewState {
            case .empty: break
            case .showContext(let context):
                self?.gameInfoStackView.isHidden = true
                self?.menuTableView.isHidden = false
                self?.menuContext = context
                let newHeight = CGFloat(context.map({$0.contentHeight}).reduce(0.0, +))
                let maxHeight =  UIScreen.main.bounds.height
                DispatchQueue.main.async { [weak self] in
                    self?.menuTableView.isScrollEnabled = newHeight >= maxHeight
                    self?.menuHeightConstraint.constant = min(newHeight, maxHeight)
                    self?.menuTableView.reloadData()
                }
            case .startMission(let mission):
                self?.gameViewModel.loadMission(mission)
                self?.gameInfoStackView.isHidden = false
                self?.menuTableView.isHidden = true
            case .setGameConfiguration(let config):
                self?.gameViewModel.setGameConfig(config)
            }
        }.store(in: &cancellables)
        
        menuViewModel.presentMenu()
    }
    
    func setupStrip() {
        stripTableView.transform = CGAffineTransform(rotationAngle: -(CGFloat)(Double.pi))
        stripTableView.showsVerticalScrollIndicator = false
    }
    
    func setupGameObservables() {
        gameViewModel.viewStatePublisher.receive(on: RunLoop.main).sink { [weak self] viewState in
            guard let self = self else { return }
            switch viewState {
            case .empty: break
            case .returnToMenu:
                self.menuViewModel.toMissions()
            case .updateStripe(let context):
                self.stripContext = context
                DispatchQueue.main.async { [weak self] in
                    self?.stripTableView.reloadData()
                }
            case .enableFocusView:
                self.canRayCast = true
                if self.focusEntity == nil {
//                    self.focusEntity = FocusEntity(on: self.arView, focus: .classic)
                }
            case .disableFocusView:
                self.canRayCast = false
                self.focusEntity?.destroy()
                self.focusEntity = nil
            case .showLoadingAssets:
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: nil, message: "Loading assets...", preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.style = UIActivityIndicatorView.Style.medium
                    loadingIndicator.startAnimating();
                    alert.view.addSubview(loadingIndicator)
                    self?.present(alert, animated: true, completion: nil)
                }
            case .hideLoadingAssets:
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: false, completion: nil)
                }
            case .loadAnchorConfiguration:
                self.loadAnchorConfiguration()
            case .updateCoins(let coins):
                self.coinsLabel.text = "\(coins)"
            case .updateHP(let lifepoints):
                self.hpLabel.text = "\(lifepoints)"
            case .updateWaves(let value):
                self.waveLabel.text = value
            case .showMissionCompleted:
                let alert = UIAlertController(title: nil, message: "Mission Completed", preferredStyle: .alert)
                self.present(alert, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.dismiss(animated: true) {
                            self.gameViewModel.cleanValues()
                        }
                    }
                }
            }
        }.store(in: &cancellables)
    }
    
    func loadAnchorConfiguration() {
        arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arConfig.environmentTexturing = .automatic
//        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
//            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
//        }
        arView.renderOptions.insert(.disableMotionBlur)
        arConfig.isCollaborationEnabled = true
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        arView.session.run(arConfig)
        setupMultipeerHelper()
        gameViewModel.enableFocusView()
    }
    
    @objc
    func onTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        let entities = arView.entities(at: tapLocation)
        if !entities.isEmpty {
            gameViewModel.putTower(on: entities)
        } else if canRayCast, let result = arView.raycast(
            from: tapLocation,
            allowing: .existingPlaneGeometry, alignment: .any
          ).first {
            gameViewModel.putMap(on: result.worldTransform)
        }
    }
    
}
