//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine
import RealityKit

class GameViewModel {
    @Published var viewState: GameViewState
    var config: GameConfig!
    var loadedModels: Int = .init()
    var waveCount: Int = .init()
    var usedGlyphs: [UInt64] = .init()

    var templates: [String : Entity] = .init()
    
    var spawnPlaces: [SpawnBundle] = .init()
    var glyphs: [UInt64 : ModelEntity] = .init()
    var creeps: [UInt64 : CreepBundle] = .init()
    var placings: [UInt64 : PlacingBundle] = .init()
    var towers: [UInt64 : TowerBundle] = .init()
    var troops: [UInt64 : TroopBundle] = .init()
    var ammo: [UInt64 : AmmoBundle] = .init()
    var terrainAnchors: [AnchorEntity] = .init()
    var currentMission: Int
    var usedMaps: Int = .init()

    private var cancellables: Set<AnyCancellable> = .init()
//    private var arView: ARView!
    init() {
        viewState = .empty
//        self.arView = arView
        self.currentMission = -1
    }
}

extension GameViewModel: GameViewModelProtocol {
    var viewStatePublisher: Published<GameViewState>.Publisher { $viewState }
    
    func setGameConfig(_ config: GameConfig) {
        self.config = config
    }
    
    func loadMission(_ mission: Int) {
        self.currentMission = mission
        self.viewState = .updateCoins(config.initialValues.coins)
        self.viewState = .updateHP(config.initialValues.playerHp)
        self.viewState = .updateWaves(config.missions[currentMission].waves)
        if loadedModels == .zero {
            viewState = .showLoadingAssets
            var modelNames = ModelType.allCases.map { $0.key }
            modelNames += CreepType.allCases.map { $0.key }
            modelNames += TowerType.allCases.map {
                type in TowerLevel.allCases.map {
                    lvl in type.key(lvl) } }
                .joined()
            
            for name in modelNames {
                ModelEntity.loadAsync(named: name).sink(
                    receiveCompletion: { _ in print ("completion: \(name)") },
                    receiveValue: { [weak self] entity in
                        guard let self = self else { return }
                        self.loadedModels += 1
                        if self.loadedModels == modelNames.count {
                            for lifepoint in Lifepoints.allCases {
                                self.templates[lifepoint.key] = ModelEntity(mesh: .generateBox(size: SIMD3(x: 0.003, y: 0.0005, z: 0.0005), cornerRadius: 0.0002), materials: [SimpleMaterial(color: lifepoint.color, isMetallic: false)])
                            }
                            self.viewState = .hideLoadingAssets
                            self.viewState = .loadAnchorConfiguration
                        }
                        let factor =
                            ModelType(rawValue: name.snakeCasetoCamelCase())?.scalingFactor ??
                            CreepType(rawValue: name.snakeCasetoCamelCase())?.scalingFactor ??
                            TowerType.scalingFactor
                        entity.setScale(SIMD3(repeating: factor), relativeTo: nil)
                        self.templates[name] = entity

                    }).store(in: &cancellables)
                
            }
        }
    }
}
