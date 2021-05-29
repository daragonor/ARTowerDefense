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
    var canRayCast: Bool = false
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
            case .fetchConnectedPeers(let sessionType):
                if self.multipeerHelper.connectedPeers.isEmpty {
                    
                } else {
                    let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.requestMission.key, parameters: nil)
                    guard let data = try? JSONEncoder().encode(model)
                    else { break }
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.showLoadingAlert(message: "Connecting")
                    }
                    self.gameViewModel.sessionType = sessionType
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
            case .startMission(let mission, let connected, let sessionType):
                self.gameViewModel.loadMission(mission, connected, sessionType)
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
            case .returnToMenu(let networkStatus, let sessionType):
                self.menuViewModel.toMissions(connected: networkStatus, sessionType: sessionType)
            case .updateStrip(let context):
                self.stripContext = context
                DispatchQueue.main.async { [weak self] in
                    self?.stripTableView.reloadData()
                }
            case .sendPeerData(let collab, let data):
                let model = CollaborativeSessionModel(key: collab.key, parameters: data)
                guard let data = try? JSONEncoder().encode(model) else { return }
                self.multipeerHelper.sendToAllPeers(data)
            case .enableFocusView:
                guard [.host].contains(self.gameViewModel.sessionType) else { return }
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
                self.coinsLabel.text = coins
                let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.updateCoins.key, parameters: try? JSONEncoder().encode(coins))
                guard let data = try? JSONEncoder().encode(model) else { break }
                self.multipeerHelper.sendToAllPeers(data)
            case .updateHP(let lifepoints):
                self.hpLabel.text = lifepoints
                let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.updateHP.key, parameters: try? JSONEncoder().encode(lifepoints))
                guard let data = try? JSONEncoder().encode(model) else { break }
                self.multipeerHelper.sendToAllPeers(data)
            case .updateWaves(let value):
                self.waveLabel.text = value
                let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.updateWaves.key, parameters: try? JSONEncoder().encode(value))
                guard let data = try? JSONEncoder().encode(model) else { break }
                self.multipeerHelper.sendToAllPeers(data)
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
        let entities = arView.entities(at: tapLocation).compactMap({$0.synchronization?.identifier})
        if !entities.isEmpty {
            if gameViewModel.sessionType == .coop {
                let model = CollaborativeSessionModel(key: CollaborativeSessionKeys.requestPlacingStatus.key, parameters: try? JSONEncoder().encode(entities.map({"\($0)"})))
                guard let data = try? JSONEncoder().encode(model) else { return }
                multipeerHelper.sendToAllPeers(data)
            }
            gameViewModel.checkPlacing(on: entities, source: .host)
        } else if canRayCast, let result = arView.raycast(
            from: tapLocation,
            allowing: .existingPlaneGeometry, alignment: .any
          ).first {
            gameViewModel.putMap(on: result.worldTransform)
        }
    }
    
}
