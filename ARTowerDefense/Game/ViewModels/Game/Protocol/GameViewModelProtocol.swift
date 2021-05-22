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
    func loadMission(_ mission: Int, _ connected: Bool)
    func setGameConfig(_ config: GameConfig)
    func putMap(on transform: simd_float4x4)
    func putTower(on entities: [Entity])
    func cleanValues()
    func enableFocusView()
}
