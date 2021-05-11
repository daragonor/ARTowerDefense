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
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    lazy var menuViewModel: MenuViewModelProtocol = { return MenuViewModel() }()
    lazy var gameViewModel: GameViewModelProtocol = { return GameViewModel() }()
    
    var stripContext: [CellViewModelProtocol] = .init()
    var menuContext: [MenuCellViewModelProtocol] = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMenuObservables()
        setupGameObservables()
        setupMenuTableView()
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
    
    func setupGameObservables() {
        gameViewModel.viewStatePublisher.receive(on: RunLoop.main).sink { [weak self] viewState in
            switch viewState {
            case .empty: break
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
                self?.loadAnchorConfiguration()
            case .updateCoins(let coins):
                self?.coinsLabel.text = "\(coins)"
            case .updateHP(let lifepoints):
                self?.hpLabel.text = "\(lifepoints)"
            case .updateWaves(let waves):
                self?.waveLabel.text = "0/\(waves)"
            }
        }.store(in: &cancellables)
    }
    
    func setupMultipeerHelper() {
        multipeerHelper = MultipeerHelper(
            serviceName: "helper-test",
            sessionType: .both,
            delegate: self
        )
        
        // MARK: - Setting RealityKit Synchronization
        
        guard let syncService = multipeerHelper.syncService else {
            fatalError("could not create multipeerHelp.syncService")
        }
        
        arView.scene.synchronizationService = syncService
        
    }
    
    func loadAnchorConfiguration() {
        arConfig = ARWorldTrackingConfiguration()
        arConfig.planeDetection = [.horizontal, .vertical]
        arConfig.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            arConfig.frameSemantics.insert(.personSegmentationWithDepth)
        }
        arView.renderOptions.insert(.disableMotionBlur)
        arView.session.delegate = self
        arConfig.isCollaborationEnabled = true
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        arView.session.run(arConfig)
        setupMultipeerHelper()
    }
    
    @objc
    func onTap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: arView)
        let entities = arView.entities(at: tapLocation)
        guard let entity = entities.first else { return }
//        if let tappedPlacing = placings.first(where: { id, _ in entities.contains(where: {$0.id == id}) }) {
//            if tappedPlacing.key == selectedPlacing?.model.id {
//                sendSelectedPlacing(position: (-1, -1))
//                selectedPlacing = nil
//                towers.forEach { $1.accessory.isEnabled = false }
//                reloadActionStrip(with: Action.none.strip)
//            } else {
//                sendSelectedPlacing(position: tappedPlacing.value.position)
//                selectedPlacing = tappedPlacing.value
//                towers.forEach { $1.accessory.isEnabled = false }
//                if let tappedTowerId = tappedPlacing.value.towerId {
//                    guard let towerBundle = towers.first(where: { id, _ in id == tappedTowerId })?.value else { return }
//                    towerBundle.accessory.isEnabled = true
//                    reloadActionStrip(with: Action.tower(hasStarted: hasStarted, type: towerBundle.type).strip)
//                } else {
//                    reloadActionStrip(with: Action.placing(hasStarted: hasStarted).strip)
//                }
//            }
//        } else {
        gameViewModel.glyphs[entity.id]?.isEnabled = false
        gameViewModel.usedGlyphs.append(entity.id)
        let arAnchor = ARAnchor(name: "Anchor Terrain", transform: entity.transformMatrix(relativeTo: nil))
        let terrainAnchor = AnchorEntity(anchor: arAnchor)
        gameViewModel.terrainAnchors.append(terrainAnchor)
//        let maps = gameConfig.missions[mission].maps
//        if usedMaps < maps.count {
//            usedMaps += 1
//            maps.count == usedMaps ?
//                reloadActionStrip(with: Action.ready.strip) : reloadActionStrip(with: Action.undo.strip)
//        }
        
        terrainAnchor.synchronization?.ownershipTransferMode = .autoAccept
        terrainAnchor.anchoring = AnchoringComponent(arAnchor)
        arView.scene.addAnchor(terrainAnchor)
        arView.session.add(anchor: arAnchor)
        insertMap(anchor: terrainAnchor, map: gameViewModel.config.missions[0].maps[gameViewModel.usedMaps])

//        }
    }
    func insertMap(anchor: AnchorEntity, map: MapModel) {
        let rows = map.matrix.count
        let columns = map.matrix.first!.count
        for row in 0..<rows {
            for column in 0..<columns {
                let rowDistance = Float(rows / 2) - gameViewModel.config.initialValues.gridDiameter
                let columnDistance = Float(columns / 2) - gameViewModel.config.initialValues.gridDiameter
                let x = (Float(row) - rowDistance ) * 0.1
                let z = (Float(column) - columnDistance) * 0.1
                let mapCode = map.matrix[row][column]
                let mapType = MapLegend.allCases[mapCode]
//                let floor = neutralFloorTemplate.embeddedModel(at: [x, 0.005, z])
//                anchor.addChild(floor.model)
                switch mapType {
                case .neutral: break
//                    let chance = Int.random(in: 1...10)
//                    let rotation = Direction.baseMoves[Int.random(in: 0...3)].rotation()
//                    switch chance {
//                    case 7...8:
//                        let floor = neutralTankTemplate.embeddedModel(at: [x, 0.003, z])
//                        floor.model.transform.rotation = rotation
//                        anchor.addChild(floor.model)
//                    case 10:
//                        let floor = neutralBarrelTemplate.embeddedModel(at: [x, 0.003, z])
//                        floor.model.transform.rotation = rotation
//                        anchor.addChild(floor.model)
//                    default: break
//                    }
                case .zipLineIn, .zipLineOut:
                    break
                case .goal:
                    let portal = gameViewModel.templates[ModelType.goal.key]!.embeddedModel(at: [x, 0.03, z])
                    anchor.addChild(portal.model)
                    portal.model.orientation = Direction.right.orientation
                    portal.entity.playAnimation(portal.entity.availableAnimations[0].repeat())
                    fallthrough
                case .lowerPath:
                    var floor: ModelBundle {
                        for direction in Direction.allCases {
                            let (nextRow, nextColumn) = (row + direction.offset.row, column + direction.offset.column)
                            if nextRow >= 0 && nextRow < rows,
                               nextColumn >= 0 && nextColumn < columns {
                                if  MapLegend.allCases[map.matrix[nextRow][nextColumn]] == .higherPath {
                                    let floor = gameViewModel.templates[ModelType.pathUpwards.key]!.embeddedModel(at: [x, 0.001, z])
                                    floor.entity.transform.rotation = simd_quatf(angle: direction.angle, axis: [0, 1, 0])
                                    return floor
                                }
                            }
                        }
                        return gameViewModel.templates[ModelType.path.key]!.embeddedModel(at: [x, 0.001, z])
                    }
                    anchor.addChild(floor.model)
                case .higherPath:
                    var floor: ModelBundle {
                        for direction in Direction.baseMoves {
                            let (nextRow, nextColumn) = (row + direction.offset.row, column + direction.offset.column)
                            if nextRow >= 0 && nextRow < rows,
                               nextColumn >= 0 && nextColumn < columns {
                                if  MapLegend.allCases[map.matrix[nextRow][nextColumn]] == .lowerPath {
                                    let floor = gameViewModel.templates[ModelType.pathDownwards.key]!.embeddedModel(at: [x, 0.1, z])
                                    floor.entity.transform.rotation = simd_quatf(angle: direction.angle + .pi, axis: [0, 1, 0])
                                    return floor
                                }
                            }
                        }
                        return gameViewModel.templates[ModelType.path.key]!.embeddedModel(at: [x, 0.1, z])
                    }
                    anchor.addChild(floor.model)
                case .lowerPlacing:
                    let placing = gameViewModel.templates[ModelType.towerPlacing.key]!.embeddedModel(at: [x, 0.005, z])
                    let bounds = placing.entity.visualBounds(relativeTo: placing.model)
                    placing.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)])
                    anchor.addChild(placing.model)
                    gameViewModel.placings[placing.model.id] = PlacingBundle(model: placing.model, position: (row,column), towerId: nil)
                case .higherPlacing:
                    let placing = gameViewModel.templates[ModelType.towerPlacing.key]!.embeddedModel(at: [x, 0.102, z])
                    let bounds = placing.entity.visualBounds(relativeTo: placing.model)
                    placing.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)])
                    anchor.addChild(placing.model)
                    gameViewModel.placings[placing.model.id] = PlacingBundle(model: placing.model, position: (row,column), towerId: nil)
                case .spawn:
                    let station = gameViewModel.templates[ModelType.spawnPort.key]!.embeddedModel(at: [x, 0.001, z])
                    gameViewModel.spawnPlaces.append(SpawnBundle(model: station.model, position: (row, column), map: gameViewModel.usedMaps))
                    anchor.addChild(station.model)
                }
            }
        }
    }
}

extension GameViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
            let model = ModelEntity()
            let glyph = gameViewModel.templates[ModelType.here.key]!.clone(recursive: true)
            model.addChild(glyph)
            let anchorEntity = AnchorEntity(anchor: planeAnchor)
            anchorEntity.addChild(model)
            arView.scene.addAnchor(anchorEntity)
            gameViewModel.glyphs[model.id] = model
            glyph.playAnimation(glyph.availableAnimations[0].repeat())
            let entityBounds = glyph.visualBounds(relativeTo: model)
            model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.extents).offsetBy(translation: entityBounds.center)])
            arView.installGestures([.rotation, .translation] ,for: model)
        }
    }
}

