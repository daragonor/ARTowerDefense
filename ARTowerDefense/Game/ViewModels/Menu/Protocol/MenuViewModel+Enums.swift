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
}

enum MenuRow: String, CaseIterable {
    case menu, missions, lobby, settings, enciclopedia
}

enum EnciclopediaType: String, CaseIterable {
    case towers, creeps
}
