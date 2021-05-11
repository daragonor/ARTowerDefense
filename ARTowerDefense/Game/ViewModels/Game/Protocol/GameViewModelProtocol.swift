//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine
import RealityKit

protocol GameViewModelProtocol {
    var viewStatePublisher: Published<GameViewState>.Publisher { get }
    var templates: [String: Entity] { get set }
    var spawnPlaces: [SpawnBundle] { get set }
    var glyphs: [UInt64 : ModelEntity] { get set }
    var usedGlyphs: [UInt64] { get set }
    var creeps: [UInt64 : CreepBundle] { get set }
    var placings: [UInt64 : PlacingBundle] { get set }
    var towers: [UInt64 : TowerBundle] { get set }
    var troops: [UInt64 : TroopBundle] { get set }
    var ammo: [UInt64 : AmmoBundle] { get set }
    var terrainAnchors: [AnchorEntity] { get set}
    var usedMaps: Int { get set }
    var config: GameConfig! { get set }
    
    func loadMission(_ mission: Int)
    func setGameConfig(_ config: GameConfig)
}
