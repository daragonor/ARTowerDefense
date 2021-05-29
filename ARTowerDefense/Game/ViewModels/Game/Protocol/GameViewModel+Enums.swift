//
//  GameViewModel+Enums.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import UIKit

enum GameViewState {
    case empty
    case enableFocusView
    case disableFocusView
    case returnToMenu(connected: Bool, sessionType: SessionType)
    case updateStrip(context: [CellViewModelProtocol])
    case updateCoins(_ coins: String)
    case updateHP(_ hp: String)
    case updateWaves(_ value: String)
    case loadAnchorConfiguration(_ connected: Bool)
    case showLoadingAssets
    case hideLoadingAssets
    case showMissionCompleted
    case startMission
    case sendPeerData(collabKey: CollaborativeSessionKeys, data: Data?)
}

enum StripOption {
    case upgrade(type: TowerType, lvl: TowerLevel), sell(type: TowerType, lvl: TowerLevel), tower(_ type: TowerType), rotateRight, rotateLeft, undo, start

    var iconImage: UIImage {
        switch self {
        case .upgrade: return #imageLiteral(resourceName: "upgrade")
        case .sell: return #imageLiteral(resourceName: "coins")
        case .tower(let type):
            switch type {
            case .turret: return #imageLiteral(resourceName: "tower-turret")
            case .launcher: return #imageLiteral(resourceName: "tower-launcher")
            case .barracks: return #imageLiteral(resourceName: "tower-barracks")
            }
        case .rotateRight: return #imageLiteral(resourceName: "clockwise-rotation")
        case .rotateLeft: return #imageLiteral(resourceName: "anticlockwise-rotation")
        case .undo: return #imageLiteral(resourceName: "cancel")
        case .start: return #imageLiteral(resourceName: "start")
        }
    }
}
enum StripState {
    case none, undo, ready, placing, tower(type: TowerType, lvl: TowerLevel)
    var strip: [StripOption] {
        switch self {
        case .undo: return [.undo]
        case .ready: return [.undo, .start]
        case .placing: return TowerType.allCases.map { StripOption.tower($0) }
        case .tower(let type, let lvl):
            var options: [StripOption] = [.upgrade(type: type, lvl: lvl), .sell(type: type, lvl: lvl)]
            if type == .barracks { options += [.rotateLeft, .rotateRight] }
            return options
        case .none: return []
        }
    }
}
