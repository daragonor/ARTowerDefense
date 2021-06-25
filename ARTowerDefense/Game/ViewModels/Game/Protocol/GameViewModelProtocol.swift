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
    var currentMission: Int? { get }
    var placings: [UInt64 : PlacingBundle] { get }
    var sessionType: SessionType { get set }
    func loadMission(_ mission: Int, _ connected: Bool, _ source: SessionType)
    func setGameConfig(_ config: GameConfig)
    func putMap(on transform: simd_float4x4)
    func checkPlacing(on entities: [UInt64], source: SessionType)
    func cleanValues()
    func enableFocusView()
    func updateSyncStrip(with source: SessionType, for state: StripState)
    func placeTower(with towerType: TowerType, from source: SessionType)
    func upgradeTower(with towerType: TowerType, towerLvl: TowerLevel, from source: SessionType)
    func sellTower(with towerType: TowerType, towerLvl: TowerLevel, from source: SessionType)
    func rotateTower(clockwise: Bool, from source: SessionType) 
    func finishMission(title:String, message: String)
}
