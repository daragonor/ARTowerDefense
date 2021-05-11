//
//  GameViewModel+Enums.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation

enum GameViewState {
    case empty
    case updateCoins(_ coins: Int)
    case updateHP(_ hp: Int)
    case updateWaves(_ waves: Int)
    case loadAnchorConfiguration
    case showLoadingAssets
    case hideLoadingAssets
}
