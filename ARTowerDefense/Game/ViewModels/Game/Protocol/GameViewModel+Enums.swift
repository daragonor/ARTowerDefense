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
    case returnToMenu
    case updateStripe(context: [CellViewModelProtocol])
    case updateCoins(_ coins: Int)
    case updateHP(_ hp: Int)
    case updateWaves(value: String)
    case loadAnchorConfiguration
    case showLoadingAssets
    case hideLoadingAssets
    case showMissionCompleted
}

enum StripOption {
    case upgrade, sell, tower(_ type: TowerType), rotateRight, rotateLeft, undo, start

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
    case none, undo, ready, placing, tower(type: TowerType)
    var strip: [StripOption] {
        switch self {
        case .undo: return [.undo]
        case .ready: return [.undo, .start]
        case .placing: return TowerType.allCases.map { StripOption.tower($0) }
//            [.tower(.turret), .tower(.launcher), .tower(.barracks)]
        case .tower(let type):
            var options: [StripOption] = [.upgrade, .sell]
            if type == .barracks { options += [.rotateLeft, .rotateRight] }
            return options
        case .none: return []
        }
    }
}
