//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine

class GameViewModel {
    @Published var viewState: MenuViewState
    var config: GameConfig
    var loadedModels = 0

    init() {
        viewState = .empty
        config = {
            let filePath = Bundle.main.path(forResource: "config", ofType: "json")!
            let data = try! NSData(contentsOfFile: filePath) as Data
            return try! JSONDecoder().decode(GameConfig.self, from: data)
        }()
    }
}

extension GameViewModel: GameViewModelProtocol { }
