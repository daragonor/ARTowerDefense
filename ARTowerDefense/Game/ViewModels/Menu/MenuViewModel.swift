//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine

class MenuViewModel {
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

extension MenuViewModel: MenuViewModelProtocol {
    func toStartMenu() {
        viewState = .showContext(getStartMenu())
    }
    
    func toMainMenu() {
        viewState = .showContext(getMenu())
    }
    
    func toEnciclopedia() {
        viewState = .showContext(getEnciclopedia())
    }
    
    func toTowersEnciclopedia() {
        viewState = .showContext(getTowersEnciclopedia())
    }
    
    func toCreepsEnciclopedia() {
        viewState = .showContext(getCreepsEnciclopedia())
    }
    
    func toMultiplayer() {
        
    }
    
    func toMissions() {
        viewState = .showContext(getMissions())
    }
    
    func toSettings() {
        viewState = .showContext(getSettings())
    }
    
    var viewStatePublisher: Published<MenuViewState>.Publisher { $viewState }
}

extension MenuViewModel {
    func getStartMenu() -> [MenuCellViewModelProtocol] {
        return [
            HeaderTableViewCell.ViewModel(),
            MenuTableViewCell.ViewModel(
                title: "Start",
                onTap: toMainMenu)
        ]
    }
    
    func getMenu() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Missions",
                onTap: toMissions),
            MenuTableViewCell.ViewModel(
                title: "Multiplayer",
                onTap: toMultiplayer),
            MenuTableViewCell.ViewModel(
                title: "Settings",
                onTap: toSettings),
            MenuTableViewCell.ViewModel(
                title: "Enciclopedia",
                onTap: toEnciclopedia)
        ]
    }
    
    func getMissions() -> [MenuCellViewModelProtocol] {
        let missions = config.missions.enumerated().map { (index, mission) in
            return MenuTableViewCell.ViewModel(
                    title: "Mission \(index + 1)",
                    onTap: { self.toMainMenu() })
        }
        return missions + [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: { self.toMainMenu() })
        ]
    }
    func getSettings() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: { self.toMainMenu() })
        ]
    }
    func getEnciclopedia() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Towers",
                onTap: { self.toTowersEnciclopedia() }),
            MenuTableViewCell.ViewModel(
                title: "Creeps",
                onTap: { self.toCreepsEnciclopedia() }),
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: { self.toMainMenu() })
        ]
    }
    func getTowersEnciclopedia() -> [MenuCellViewModelProtocol] {
        let entries = config.enciclopedia.towers.map { entry in
            return TowerEnciclopediaViewCell.ViewModel(
                image: entry.image,
                type: entry.type,
                damage: entry.damage,
                speed: entry.speed,
                range: entry.range,
                description: entry.description)
        }
        return entries + [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: { self.toEnciclopedia() })
        ]
    }
    
    func getCreepsEnciclopedia() -> [MenuCellViewModelProtocol] {
        let entries = config.enciclopedia.creeps.map { entry in
            return CreepEnciclopediaViewCell.ViewModel(
                image: entry.image,
                type: entry.type,
                speed: entry.speed,
                resistance: entry.resistance,
                description: entry.description)
        }
        return entries + [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: { self.toEnciclopedia() })
        ]
    }
}
