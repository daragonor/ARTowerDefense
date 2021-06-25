//
//  GameViewModel+Enums.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
enum MenuViewState {
    case empty
    case showContext(_ context: [CellViewModelProtocol & MenuCellViewModelProtocol])
    case startMission(mission: Int, connected: Bool, sessionType: SessionType)
    case setGameConfiguration(config: GameConfig)
    case fetchConnectedPeers(sessionType: SessionType)
}
