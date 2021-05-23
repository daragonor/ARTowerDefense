//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine
import RealityKit
import ARKit

class GameViewModel {
    @Published var viewState: GameViewState
    
    var config: GameConfig!
    var templates: [String : Entity] = .init()

    var waveCount: Int = .init()
    var usedMaps: Int = .init()
    var playerHp: Int = .init()
    var coins: Int = .init()
    var currentMission: Int?

    var terrainAnchors: [AnchorEntity] = .init()
    var selectedPlacing: PlacingBundle?

//    var glyphs: [UInt64 : ModelEntity] = .init()
    var spawnPlaces: [SpawnBundle] = .init()
    var creeps: [UInt64 : CreepBundle] = .init()
    var placings: [UInt64 : PlacingBundle] = .init()
    var towers: [UInt64 : TowerBundle] = .init()
    var troops: [UInt64 : TroopBundle] = .init()
    var ammo: [UInt64 : AmmoBundle] = .init()
    var networkStatus: Bool = false
    private var cancellables: Set<AnyCancellable> = .init()
    private var arView: ARView!
    var gameTimer: Timer?
    init(arView: ARView) {
        self.viewState = .empty
        self.arView = arView
    }
}

extension GameViewModel: GameViewModelProtocol {
    var viewStatePublisher: Published<GameViewState>.Publisher { $viewState }

    func putMap(on transform: simd_float4x4) {
        let arAnchor = ARAnchor(name: "Anchor Terrain", transform: transform)
        let terrainAnchor = AnchorEntity(anchor: arAnchor)
        terrainAnchors.append(terrainAnchor)
        terrainAnchor.synchronization?.ownershipTransferMode = .autoAccept
        terrainAnchor.anchoring = AnchoringComponent(arAnchor)
        arView.scene.addAnchor(terrainAnchor)
        arView.session.add(anchor: arAnchor)
        let maps = config.missions[currentMission!].maps
        insertMap(anchor: terrainAnchor, map: maps[usedMaps])
        usedMaps += 1
        if maps.count == usedMaps {
            viewState = .updateStripe(context: getStripe(for: .ready))
            viewState = .disableFocusView
        } else {
            viewState = .updateStripe(context: getStripe(for: .undo))
        }
    }
    
    func putTower(on entities: [Entity]) {
        if let tappedPlacing = placings.first(where: { id, _ in entities.contains(where: {$0.id == id}) }) {
            if tappedPlacing.key == selectedPlacing?.model.id {
                selectedPlacing = nil
                towers.forEach { $1.accessory.isEnabled = false }
                viewState = .updateStripe(context: getStripe(for: .none))
            } else {
                selectedPlacing = tappedPlacing.value
                towers.forEach { $1.accessory.isEnabled = false }
                if let tappedTowerId = tappedPlacing.value.towerId {
                    guard let towerBundle = towers.first(where: { id, _ in id == tappedTowerId })?.value else { return }
                    towerBundle.accessory.isEnabled = true
                    viewState = .updateStripe(context: getStripe(for: .tower(type: towerBundle.type)))

                } else {
                    viewState = .updateStripe(context: getStripe(for: .placing))
                }
            }
        }
    }
            
    
    func cleanValues() {
        terrainAnchors.forEach { terrain in terrain.removeFromParent() }
        currentMission = nil
        //limpiar todos los arreglos
        spawnPlaces = []
        creeps = [:]
        placings = [:]
        towers = [:]
        troops = [:]
        ammo = [:]
        viewState = .returnToMenu(connected: networkStatus)
    }
    
    func setGameConfig(_ config: GameConfig) {
        self.config = config
    }
    
    func loadMission(_ mission: Int, _ connected: Bool) {
        updateInitialValues(for: mission)
        networkStatus = connected
        loadTemplatesIfNeeded(connected)
        enableFocusView()
    }
    
    func enableFocusView() {
        viewState = .enableFocusView
    }
}

private extension GameViewModel {
    func getStripe(for state: StripState) -> [CellViewModelProtocol] {
        return state.strip.map { option in
            var onTap: () -> Void = {}
            var title: String? = .init()
            switch option {
            case .upgrade:
                guard let towerId = selectedPlacing?.towerId, let tower = towers[towerId] else { break }
                title = tower.lvl == tower.lvl.nextLevel ? "MAX" : "\(tower.type.cost(lvl: tower.lvl.nextLevel))"
                onTap = upgradeTower
            case .sell:
                guard let towerId = selectedPlacing?.towerId, let tower = towers[towerId] else { break }
                title = "\(Int(Float(tower.type.cost(lvl: tower.lvl)) * 0.5))"
            case .tower(let type):
                title = "\(type.cost(lvl: .lvl1))"
                onTap = { self.placeTower(with: type) }
            case .rotateRight:
                title = nil
            case .rotateLeft:
                title = nil
            case .undo:
                title = "Undo"
                onTap = undoPlacing
            case .start:
                title = "Start"
                onTap = startMission
            }
            return StripViewCell.ViewModel(image: option.iconImage, title: title, onTap: onTap)
        }
    }
    
    func placeTower(with towerType: TowerType) {
        guard towerType.cost(lvl: .lvl1) <= coins else { return }
        insertTower(towerType: towerType, towerLvl: .lvl1)
        viewState = .updateStripe(context: getStripe(for: .tower(type: towerType)))
    }
    
    func startMission() {
        setupGameInfo()
        viewState = .updateStripe(context: getStripe(for: .none))
    }
    
    func setupGameInfo() {
        var graceTimer = config.initialValues.graceTime
        var waveInterval = config.initialValues.waveInterval
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let mission = self.currentMission else { return }
            self.coins += 5
            self.viewState = .updateCoins(self.coins)
            if graceTimer >= 0 {
                self.viewState = .updateWaves(value: "0:\(graceTimer < 10 ? "0" : "")\(graceTimer)")
                if graceTimer == 0 {
                    self.sendWaves(mission: mission, wave: self.waveCount)
                    self.waveCount += 1
                    self.viewState = .updateWaves(value: "\(self.waveCount + 1)/\(self.config.missions[mission].waves.count)")
                }
                graceTimer -= 1
            } else {
                if waveInterval == 0 { graceTimer = self.config.initialValues.graceTime }
                waveInterval -= 1
            }
        }
        gameTimer?.fire()
    }
    
    func sendWaves(mission: Int, wave: Int) {
        for spawn in spawnPlaces {
            let missionConfig = config.missions[mission]
            let paths = missionConfig.maps[spawn.map].creepPathsCoordinates(at: spawn.position,diameter: config.initialValues.gridDiameter)
            var count = 0
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                guard count < missionConfig.waves[wave].count else { timer.invalidate() ; return }
                let creepType = CreepType.allCases[missionConfig.waves[wave][count]]
                let creep: ModelBundle = self.templates[creepType.key]!.embeddedModel(at: spawn.model.transform.translation)
                creep.model.position.y += 0.03
                let bounds = creep.entity.visualBounds(relativeTo: creep.model)
                creep.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: SIMD3(repeating: 0.0015))], mode: .trigger, filter: CollisionFilter(group: Filter.creeps.group, mask: Filter.towers.group))
                spawn.model.anchor?.addChild(creep.model)
                let creepHPbar = self.templates[Lifepoints.full.key]!.clone(recursive: true)
                creep.model.addChild(creepHPbar)
                creepHPbar.position.y = (bounds.extents.y / 2) + 0.003
                self.creeps[creep.model.id] = CreepBundle(bundle: creep, hpBarId: creepHPbar.id, type: creepType, animation: nil, subscription: nil)
                creep.entity.playAnimation(creep.entity.availableAnimations[0].repeat())
                count += 1
                self.deployUnit(creep.model, type: creepType,speed: creepType.speed, on: paths[self.waveCount % paths.count], setScale: 10)
            }
            timer.fire()
        }
    }
    
    func deployUnit(_ creep: ModelEntity, type: CreepType, speed: Float, to index: Int = 0, on path: [OrientedCoordinate], baseHeight: Float? = nil, setScale: Float? = nil) {
        var unitTransform = creep.transform
        let move = path[index]
        ///Set new move
        let height = baseHeight ?? unitTransform.translation.y
        unitTransform.translation = move.coordinate
        unitTransform.translation.y += height
        unitTransform.rotation = simd_quatf(angle: move.angle + type.angleOffset, axis: [0, 1, 0])
        if let scale = setScale { unitTransform.scale = SIMD3(repeating: scale) }
        ///Start moving
        let animation = creep.move(to: unitTransform, relativeTo: creep.anchor, duration: TimeInterval(speed), timingFunction: .linear)
        creeps[creep.id]?.animation = animation
        let subscription = arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter(animation.isPlaybackController)
            .sink(receiveValue: { event in
                if move.mapLegend == .goal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        creep.removeFromParent()
                    }
                    self.creeps.removeValue(forKey: creep.id)
                    self.playerHp -= 1
                    self.viewState = .updateHP(self.playerHp)
                    self.checkMissionCompleted()
                } else if move.mapLegend == .zipLineOut {
                    
                } else {
                    self.deployUnit(creep, type: type, speed: speed, to: index + 1, on: path, baseHeight: height)
                }
            })
        creeps[creep.id]?.subscription = subscription
    }
    
    func upgradeTower() {
        
    }
    
    func undoPlacing() {
        if let lastMap = terrainAnchors.last {
            lastMap.removeFromParent()
            usedMaps -= 1
            viewState = .updateStripe(context: getStripe(for: .undo))
            viewState = .enableFocusView
        }
    }
    
    func updateInitialValues(for mission: Int) {
        self.currentMission = mission
        self.playerHp = config.initialValues.playerHp
        self.coins = config.initialValues.coins
        self.waveCount = .zero
        self.usedMaps = .zero
        self.viewState = .updateCoins(config.initialValues.coins)
        self.viewState = .updateHP(config.initialValues.playerHp)
        self.viewState = .updateWaves(value: "0/\(config.missions[mission].waves.count)")
    }
    
    func loadTemplatesIfNeeded(_ connected: Bool) {
        guard templates.isEmpty else {
            viewState = .loadAnchorConfiguration(connected)
            return
        }
        var loadedModels: Int = .zero
        viewState = .showLoadingAssets
        var modelNames = ModelType.allCases.map { $0.key }
        modelNames += CreepType.allCases.map { $0.key }
        modelNames += LevelType.allCases.map { $0.key }
        modelNames += NeutralType.allCases.map { $0.key }
        modelNames += TowerType.allCases.map { type in TowerLevel.allCases.map { lvl in type.key(lvl) } }.joined()
        
        for name in modelNames {
            ModelEntity.loadAsync(named: name).sink(
                receiveCompletion: { _ in print ("completion: \(name)") },
                receiveValue: { [weak self] entity in
                    guard let self = self else { return }
                    loadedModels += 1
                    if loadedModels == modelNames.count {
                        for lifepoint in Lifepoints.allCases {
                            self.templates[lifepoint.key] = ModelEntity(mesh: .generateBox(size: SIMD3(x: 0.003, y: 0.0005, z: 0.0005), cornerRadius: 0.0002), materials: [SimpleMaterial(color: lifepoint.color, isMetallic: false)])
                        }
                        self.viewState = .hideLoadingAssets
                        self.viewState = .loadAnchorConfiguration(connected)

                    }
                    let factor =
                        ModelType(rawValue: name.snakeCasetoCamelCase())?.scalingFactor ??
                        CreepType(rawValue: name.snakeCasetoCamelCase())?.scalingFactor ??
                        LevelType(rawValue: name)?.scalingFactor ??
                        NeutralType(rawValue: name)?.scalingFactor ??
                        TowerType.scalingFactor
                    entity.setScale(SIMD3(repeating: factor), relativeTo: nil)
                    self.templates[name] = entity
                    
                }).store(in: &cancellables)
        }
    }
    
    func insertMap(anchor: AnchorEntity, map: MapModel) {
        let rows = map.matrix.count
        let columns = map.matrix.first!.count
        var neutralCount = 0
        var higherPathCount = 0
//        var lowerPathCount = 0
        for row in 0..<rows {
            for column in 0..<columns {
                let rowDistance = Float(rows / 2) - config.initialValues.gridDiameter
                let columnDistance = Float(columns / 2) - config.initialValues.gridDiameter
                let x = (Float(row) - rowDistance ) * 0.1
                let z = (Float(column) - columnDistance) * 0.1
                let mapCode = map.matrix[row][column]
                let mapType = MapLegend.allCases[mapCode]
                //                let floor = neutralFloorTemplate.embeddedModel(at: [x, 0.005, z])
                //                anchor.addChild(floor.model)
                switch mapType {
                case .neutral:
                    switch currentMission {
                        case 0:
                            let ground = templates[neutral_Lvl01[neutralCount].key]!.embeddedModel(at: [x, 0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl01[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl01.count {
                                neutralCount = 0
                            }
                        case 1:
                            let ground = templates[neutral_Lvl02[neutralCount].key]!.embeddedModel(at: [x,0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl02[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl02.count {
                                neutralCount = 0
                            }
                        case 2:
                            let ground = templates[neutral_Lvl03[neutralCount].key]!.embeddedModel(at: [x,0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl03[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl03.count {
                                neutralCount = 0
                            }
                        case 3:
                            let ground = templates[neutral_Lvl04[neutralCount].key]!.embeddedModel(at: [x,0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl04[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl04.count {
                                neutralCount = 0
                            }
                        case 4:
                            let ground = templates[neutral_Lvl05[neutralCount].key]!.embeddedModel(at: [x,0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl05[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl05.count {
                                neutralCount = 0
                            }
                        case 5:
                            let ground = templates[neutral_Lvl06[neutralCount].key]!.embeddedModel(at: [x,0.001, z])
                            ground.entity.transform.rotation = simd_quatf(angle: neutral_Lvl06[neutralCount].rY.angle, axis: [0, 1, 0])
                            neutralCount += 1
                            anchor.addChild(ground.model)
                            if neutralCount == neutral_Lvl06.count {
                                neutralCount = 0
                            }
                        default:
                            let ground = templates[LevelType.lvl05_ground004.key]!.embeddedModel(at: [x, 0.001, z])
                            anchor.addChild(ground.model)
                    }
                    break
                case .zipLineIn, .zipLineOut:
                    break
                case .goal:
                    let portal = templates[ModelType.goal.key]!.embeddedModel(at: [x, 0.03, z])
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
                                    switch currentMission {
                                    case 3,4:
                                        let floor = templates[LevelType.lvl04_higherpath004.key]!.embeddedModel(at: [x, 0.001, z])
                                        floor.entity.transform.rotation = simd_quatf(angle: direction.angle, axis: [0, 1, 0])
                                        return floor
                                    default:
                                        let floor = templates[LevelType.lvl06_higherpath004.key]!.embeddedModel(at: [x, 0.001, z])
                                        floor.entity.transform.rotation = simd_quatf(angle: direction.angle, axis: [0, 1, 0])
                                        return floor
                                    }
//                                    let floor = templates[ModelType.pathUpwards.key]!.embeddedModel(at: [x, 0.001, z])
//                                    floor.entity.transform.rotation = simd_quatf(angle: direction.angle, axis: [0, 1, 0])
//                                    return floor
                                }
                            }
                        }
                        return templates[ModelType.path.key]!.embeddedModel(at: [x, 0.001, z])
                    }
                    anchor.addChild(floor.model)
                case .higherPath:
                    var floor: ModelBundle {
                        for direction in Direction.baseMoves {
                            let (nextRow, nextColumn) = (row + direction.offset.row, column + direction.offset.column)
                            if nextRow >= 0 && nextRow < rows,
                               nextColumn >= 0 && nextColumn < columns {
                                if  MapLegend.allCases[map.matrix[nextRow][nextColumn]] == .lowerPath {
                                    switch currentMission {
                                    case 3,4:
                                        let floor = templates[LevelType.lvl04_higherpath003.key]!.embeddedModel(at: [x, 0.001, z])
                                        floor.entity.transform.rotation = simd_quatf(angle: direction.angle + .pi, axis: [0, 1, 0])
                                        return floor
                                    default:
                                        let floor = templates[LevelType.lvl06_higherpath003.key]!.embeddedModel(at: [x, 0.001, z])
                                        floor.entity.transform.rotation = simd_quatf(angle: direction.angle + .pi, axis: [0, 1, 0])
                                        return floor
                                    }
//                                    let floor = templates[ModelType.pathDownwards.key]!.embeddedModel(at: [x, 0.1, z])
                                    
                                }
                            }
                        }
//                        return templates[ModelType.path.key]!.embeddedModel(at: [x, 0.1, z])
                        print("higherPathCount")
                        print(higherPathCount)
                        switch currentMission {
                            case 3:
                                let higherPath = templates[higherPath_Lvl04[higherPathCount].key]!.embeddedModel(at: [x, 0.001, z])
                                higherPath.entity.transform.rotation = simd_quatf(angle: higherPath_Lvl04[higherPathCount].rY.angle, axis: [0, 1, 0])
                                higherPathCount += 1
                                return higherPath
                            case 4:
                                let higherPath = templates[higherPath_Lvl05[higherPathCount].key]!.embeddedModel(at: [x, 0.001, z])
                                higherPath.entity.transform.rotation = simd_quatf(angle: higherPath_Lvl05[higherPathCount].rY.angle, axis: [0, 1, 0])
                                higherPathCount += 1
                                return higherPath
                            case 5:
                                let higherPath = templates[higherPath_Lvl06[higherPathCount].key]!.embeddedModel(at: [x, 0.001, z])
                                higherPath.entity.transform.rotation = simd_quatf(angle: higherPath_Lvl06[higherPathCount].rY.angle, axis: [0, 1, 0])
                                higherPathCount += 1
                                return higherPath
                            default:
                                return templates[LevelType.lvl04_higherpath001.key]!.embeddedModel(at: [x,0.001, z])
                        }
                    }
                    anchor.addChild(floor.model)
                case .lowerPlacing:
                    let placing = templates[ModelType.towerPlacing.key]!.embeddedModel(at: [x, 0.001, z])
                    let bounds = placing.entity.visualBounds(relativeTo: placing.model)
                    placing.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)])
                    anchor.addChild(placing.model)
                    placings[placing.model.id] = PlacingBundle(model: placing.model, position: (row,column), towerId: nil)
                case .higherPlacing:
                    let higherPlacingKey = { () -> String in
                        switch currentMission {
                        case 3: return LevelType.lvl04_higherbase001.key
                        case 4: return LevelType.lvl05_higherbase001.key
                        case 5: return LevelType.lvl06_higherbase001.key
                        default: return LevelType.lvl04_higherbase001.key
                        }
                    }()
                    let placing = templates[higherPlacingKey]!.embeddedModel(at: [x, 0.1, z])
                    let bounds = placing.entity.visualBounds(relativeTo: placing.model)
                    placing.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents).offsetBy(translation: bounds.center)])
                    anchor.addChild(placing.model)
                    placings[placing.model.id] = PlacingBundle(model: placing.model, position: (row,column), towerId: nil)
                case .spawn:
                    let station = templates[ModelType.spawnPort.key]!.embeddedModel(at: [x, 0.001, z])
                    spawnPlaces.append(SpawnBundle(model: station.model, position: (row, column), map: usedMaps))
                    anchor.addChild(station.model)
                }
            }
        }
    }
    
    func checkMissionCompleted() {
        if creeps.isEmpty, waveCount == config.missions[currentMission!].waves.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.viewState = .showMissionCompleted
            }
        }
    }
}

// MARK:- Insert Tower
extension GameViewModel {
    func insertTower(towerType: TowerType, towerLvl: TowerLevel) {
        guard let placingPosition = selectedPlacing?.model.position, let anchor = selectedPlacing?.model.anchor as? AnchorEntity else { return }
        
        coins -= towerType.cost(lvl: towerLvl)
        let towerModel: ModelBundle = templates[towerType.key(towerLvl)]!.embeddedModel(at: placingPosition)
        placings.keys.forEach { id in
            if id == selectedPlacing?.model.id {
                placings[id]?.towerId = towerModel.model.id
                selectedPlacing?.towerId = towerModel.model.id
            }
        }
        
        towerModel.model.position.y += 0.003
        anchor.addChild(towerModel.model)
        ///Tower range accesorry
        let diameter = 2.0 * config.initialValues.gridDiameter * towerType.range * 0.1
        
        let rangeAccessory = ModelEntity(mesh: .generateBox(size: SIMD3(x: diameter, y: 0.02, z: diameter), cornerRadius: 0.025), materials: [SimpleMaterial(color: UIColor.red.withAlphaComponent(0.05), isMetallic: false)])
        towerModel.model.addChild(rangeAccessory)
        rangeAccessory.position.y += 0.02
        let tower = TowerBundle(bundle: towerModel, type: towerType, lvl: towerLvl, accessory: rangeAccessory)
        towers[tower.model.id] = tower

        
        if towerType == .barracks {
            rangeAccessory.position.z += diameter
            let unitOffset: SIMD3<Float> = [0, 0.02, diameter]
            deployTroop(tower: tower, unitOffset: unitOffset)
        } else {
            let collisionOffset: SIMD3<Float> = [0, 0.02, 0]
            let collisionSize: SIMD3<Float> = [diameter, 0.02, diameter]
            tower.model.components.set(CollisionComponent(shapes: [ShapeResource.generateBox(size: collisionSize).offsetBy(translation: collisionOffset)], mode: .trigger, filter: CollisionFilter.init(group: Filter.towers.group, mask: Filter.creeps.group)))
            
            let endSubs = arView.scene.subscribe(to: CollisionEvents.Ended.self, on: tower.model) {
                event in
                guard let tower = self.towers[event.entityA.id] else { return }
                guard let creep = self.creeps[event.entityB.id] else { return }
                tower.enemiesIds.removeAll(where: { $0 == creep.model.id })
            }
            
            let beganSubs = arView.scene.subscribe(to: CollisionEvents.Began.self, on: tower.model) {
                event in
                guard let tower = self.towers[event.entityA.id] else { return }
                guard let creep = self.creeps[event.entityB.id] else { return }
                tower.enemiesIds.append(creep.model.id)
                if tower.attackTimer.isNil {
                    tower.attackTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(towerType.cadence(lvl: towerLvl)), repeats: true) { timer in
                        let capacity = min(tower.enemiesIds.count, tower.type.capacity(lvl: tower.lvl))
                        tower.enemiesIds[0..<capacity].forEach { id in
                            if let creep = self.creeps[id] {
                                switch towerType {
                                case .turret:
                                    self.fireBullet(tower: tower, creep: creep, anchor: anchor, placingPosition: placingPosition)
                                case .launcher:
                                    self.fireBomb(tower: tower, creep: creep, anchor: anchor, placingPosition: placingPosition)
                                default: break
                                }
                            }
                        }
                    }
                    tower.attackTimer?.fire()
                } else if let timer = tower.attackTimer, !timer.isValid {
                    tower.attackTimer?.fire()
                }
            }
            tower.subscribes = [beganSubs, endSubs]
        }
    }
    
    func deployTroop(tower: TowerBundle, unitOffset: SIMD3<Float>) {
        let troop: ModelBundle = templates[CreepType.regular.key]!.embeddedModel(at: unitOffset)
        troop.model.scale = (SIMD3(repeating: 10))
        let bounds = troop.entity.visualBounds(relativeTo: troop.model)
        troop.model.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: bounds.extents)], mode: .trigger, filter: CollisionFilter(group: Filter.towers.group, mask: Filter.creeps.group))
        tower.model.addChild(troop.model)
        let troopHPbar = templates[Lifepoints.full.key]!.clone(recursive: true)
        troop.model.addChild(troopHPbar)
        troopHPbar.position.y = (bounds.extents.y / 2) + 0.003
        troop.entity.playAnimation(troop.entity.availableAnimations[0].repeat())
        troops[troop.model.id] = TroopBundle(bundle: troop, hpBarId: troopHPbar.id,maxHP: tower.type.maxHP(lvl: tower.lvl), towerId: tower.model.id)

        let endSubs = arView.scene.subscribe(to: CollisionEvents.Ended.self, on: troop.model) {
            event in
            guard let creep = event.entityB as? ModelEntity else { return }
            self.troops[troop.model.id]?.enemiesIds.removeAll(where: { $0 == creep.id })
        }
        let beganSubs = arView.scene.subscribe(to: CollisionEvents.Began.self, on: troop.model) {
            event in
            switch tower.type {
            case .turret, .launcher: break
            case .barracks:
                guard let creepModel = event.entityB as? ModelEntity, let creepBundle = self.creeps[creepModel.id] else { return }
                guard let troopModel = event.entityA as? ModelEntity else { return }
                self.troops[troopModel.id]?.enemiesIds.append(creepModel.id)
                creepBundle.animation?.pause()
                self.troops[troopModel.id]?.rotate(to: creepBundle)
                let towerTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(tower.type.cadence(lvl: tower.lvl)), repeats: true) { timer in
                    guard self.troops[troopModel.id]?.enemiesIds.contains(creepModel.id) ?? false else { timer.invalidate() ; return }
                    
                    self.damageCreep(creepModel: creepModel, towerId: troopModel.id, attack: tower.type.attack(lvl: tower.lvl))
                }
                towerTimer.fire()
                let creepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(creepBundle.type.cadence), repeats: true) { timer in
                    guard self.creeps.keys.contains(creepModel.id) else { timer.invalidate() ; return }
                    self.damageTroop(tower: tower, unitOffset: unitOffset, troopModel: troopModel, creepId: creepModel.id, attack: creepBundle.type.attack)
                }
                creepTimer.fire()
            }
        }
        tower.subscribes = [beganSubs, endSubs]
    }
    
    func fireBomb(tower: TowerBundle, creep: CreepBundle, anchor: AnchorEntity, placingPosition: SIMD3<Float>) {
        let bomb = AmmoBundle(bundle: self.templates[ModelType.flyingBomb.key]!.embeddedModel(at: placingPosition))
        bomb.model.transform.translation.y += 0.015
        anchor.addChild(bomb.model)
        self.ammo[bomb.model.id] = bomb
        let topHeight = ((creep.model.position.y - tower.model.position.y) / 2) + 0.15
        deployBomb(iterations: 20, bomb: bomb, tower: tower, creep: creep, topHeight: topHeight)
    }
    
    func deployBomb(speed baseSpeed: Float = 0.2, iterations: Int, bomb: AmmoBundle, tower: TowerBundle, creep: CreepBundle, topHeight: Float, counter: Int = 1) {
        guard iterations != counter else {
            self.damageCreep(creepModel: creep.model, towerId: tower.model.id, attack: tower.type.attack(lvl: tower.lvl))
            bomb.model.removeFromParent()
            bomb.subscriptions.last?.cancel()
            self.ammo.removeValue(forKey: bomb.model.id)
            return
        }
        var speed = baseSpeed
        var bulletTransform = bomb.model.transform
        bulletTransform.translation += (creep.model.position - bomb.model.position) / Float(iterations - counter)
        if counter < 9 {
            speed += 0.005
            bulletTransform.translation.y = bomb.model.position.y + (topHeight - bomb.model.position.y) / Float(counter)
        } else {
            speed -= 0.005
            bulletTransform.translation.y = bomb.model.position.y + (creep.model.position.y - bomb.model.position.y) / Float(counter)
        }
        bulletTransform.translation.y += Float(Int.random(in: -1...1))/200.0
        bulletTransform.rotation = simd_quatf(angle: Direction.allCases[counter%Direction.allCases.count].angle, axis: Axis.y.matrix)
        let animation = bomb.model.move(to: bulletTransform, relativeTo: bomb.model.anchor, duration: TimeInterval(speed), timingFunction: .linear)
        let subscription = arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter(animation.isPlaybackController)
            .sink(receiveValue: { [weak self] _ in
                self?.deployBomb(speed: speed, iterations: iterations, bomb: bomb, tower: tower, creep: creep, topHeight: topHeight, counter: counter + 1)
            })
        bomb.subscriptions.append(subscription)
    }
    
    func fireBullet(tower: TowerBundle, creep: CreepBundle, anchor: AnchorEntity, placingPosition: SIMD3<Float>) {
        var towerTransform = tower.entity.transform
        towerTransform.rotation = tower.model.angle(targetPosition: creep.model.position)
        let towerAnimation = tower.entity.move(to: towerTransform, relativeTo: tower.model, duration: TimeInterval(0.1), timingFunction: .linear)
        tower.subscribes.append(arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
            .filter { $0.playbackController == towerAnimation }
            .sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            let bullet = AmmoBundle(bundle: self.templates[ModelType.bullet.key]!.embeddedModel(at: placingPosition))
            self.ammo[bullet.model.id] = bullet
            bullet.model.transform.translation.y += 0.015
            anchor.addChild(bullet.model)
            var bulletTransform = bullet.model.transform
            bulletTransform.translation = creep.model.position
            bullet.rotate(to: creep)
            let animation = bullet.model.move(to: bulletTransform, relativeTo: bullet.model.anchor, duration: 0.1, timingFunction: .linear)
            let subscription = self.arView.scene.publisher(for: AnimationEvents.PlaybackCompleted.self)
                .filter { $0.playbackController == animation }
                .sink( receiveValue: { [weak self] event in
                    guard let self = self else { return }
                    self.damageCreep(creepModel: creep.model, towerId: tower.model.id, attack: tower.type.attack(lvl: tower.lvl))
                    bullet.model.removeFromParent()
                    bullet.subscriptions.last?.cancel()
                    self.ammo.removeValue(forKey: bullet.model.id)
                })
            bullet.subscriptions.append(subscription)
        }))
    }
    
    
    func damageTroop(tower: TowerBundle, unitOffset: SIMD3<Float>, troopModel: ModelEntity, creepId: UInt64, attack: Float) {
        guard let troopBundle = troops[troopModel.id], let (childIndex, child) = troopModel.children.enumerated().first(where: { $1.id == troops[troopModel.id]?.hpBarId }) else { return }
        troops[troopModel.id]?.hp -= attack
        if troopBundle.hp < 0 {
            creeps[creepId]?.animation?.resume()
            troopModel.removeFromParent()
            troops[troopModel.id]?.enemiesIds.removeAll()
            troops.removeValue(forKey: troopModel.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3 ) {
                self.deployTroop(tower: tower, unitOffset: unitOffset)
            }
        }
        let hpPercentage = troopBundle.hp / troopBundle.maxHP
        let hpBar = templates[Lifepoints.status(hp: hpPercentage).key]!.clone(recursive: true)
        hpBar.scale = [hpPercentage, 1.0, 1.0]
        troopModel.children[childIndex] = hpBar
        hpBar.position = child.position
        child.removeFromParent()
        troops[troopModel.id]?.hpBarId = hpBar.id
    }
    
    func damageCreep(creepModel: ModelEntity, towerId: UInt64, attack: Float) {
        guard let creepBundle = creeps[creepModel.id], let (childIndex, child) = creepModel.children.enumerated().first(where: { $1.id == creeps[creepModel.id]?.hpBarId }) else { return }
        creeps[creepModel.id]?.hp -= attack
        if creepBundle.hp < 0 {
            coins += creepBundle.type.reward
            towers[towerId]?.enemiesIds.removeAll(where: { id in id == creepModel.id })
            creepModel.removeFromParent()
            creeps.removeValue(forKey: creepModel.id)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.checkMissionCompleted()
            }
        }
        let hpPercentage = creepBundle.hp / creepBundle.maxHP
        let hpBar = templates[Lifepoints.status(hp: hpPercentage).key]!.clone(recursive: true)
        hpBar.scale = [hpPercentage, 1.0, 1.0]
        creepModel.children[childIndex] = hpBar
        hpBar.position = child.position
        child.removeFromParent()
        creeps[creepModel.id]?.hpBarId = hpBar.id
    }
}
