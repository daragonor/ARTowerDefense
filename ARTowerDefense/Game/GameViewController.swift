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
        setupMultipeerHelper()
        setupMenuObservables()
        setupGameObservables()
        setupMenuTableView()
        setupStrip()
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
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
            guard let self = self else { return }
            switch viewState {
            case .empty: break
            case .fetchConnectedPeers:
                if self.multipeerHelper.connectedPeers.isEmpty {
                    
                } else {
                    let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.requestMission.key, parameters: nil)
                    guard let data = try? JSONEncoder().encode(model)
                    else { break }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.showLoadingAlert(message: "Connecting")
                    }
                    self.multipeerHelper.sendToAllPeers(data)
                }
            case .showContext(let context):
                self.gameInfoStackView.isHidden = true
                self.menuTableView.isHidden = false
                self.menuContext = context
                let newHeight = CGFloat(context.map({$0.contentHeight}).reduce(0.0, +))
                let maxHeight =  UIScreen.main.bounds.height
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.menuTableView.isScrollEnabled = newHeight >= maxHeight
                    self.menuHeightConstraint.constant = min(newHeight, maxHeight)
                    self.menuTableView.reloadData()
                }
            case .startMission(let mission, let connected):
                self.gameViewModel.loadMission(mission, connected)
                self.gameInfoStackView.isHidden = false
                self.menuTableView.isHidden = true
            case .setGameConfiguration(let config):
                self.gameViewModel.setGameConfig(config)
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
            case .returnToMenu(let networkStatus):
                self.menuViewModel.toMissions(connected: networkStatus)
            case .updateStripe(let context):
                self.stripContext = context
                DispatchQueue.main.async { [weak self] in
                    self?.stripTableView.reloadData()
                }
            case .enableFocusView:
                self.canRayCast = true
                if self.focusEntity == nil {
                    self.focusEntity = FocusEntity(on: self.arView, focus: .classic)
                }
            case .disableFocusView:
                self.canRayCast = false
                self.focusEntity?.destroy()
                self.focusEntity = nil
            case .showLoadingAssets:
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.showLoadingAlert(message: "Loading assets...")
                }
            case .hideLoadingAssets:
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: false, completion: nil)
                }
            case .loadAnchorConfiguration(let connected):
                self.loadAnchorConfiguration(connected)
                self.gameViewModel.enableFocusView()
            case .updateCoins(let coins):
                self.coinsLabel.text = "\(coins)"
            case .updateHP(let lifepoints):
                self.hpLabel.text = "\(lifepoints)"
            case .updateWaves(let value):
                self.waveLabel.text = value
            case .startMission: break
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
    func showLoadingAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        loadingIndicator.startAnimating();
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    func loadAnchorConfiguration(_ connected: Bool) {
        arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arConfig.environmentTexturing = .automatic
        arView.renderOptions.insert(.disableMotionBlur)

//        arView.debugOptions.insert(.showPhysics)
//        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
//            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
//        }
        arConfig.isCollaborationEnabled = connected
        if connected { setupMultipeerHelper() }
        arView.session.run(arConfig)
        
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
