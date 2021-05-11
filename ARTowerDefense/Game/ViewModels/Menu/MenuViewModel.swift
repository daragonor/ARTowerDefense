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
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try! decoder.decode(GameConfig.self, from: data)
        }()
        viewState = .setGameConfiguration(config: config)
    }
}

extension MenuViewModel: MenuViewModelProtocol {
    func toMission(index: Int) {
        viewState = .startMission(mission: index)
    }
    
    func presentMenu() {
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
        viewState = .showContext(getMultiplayer())
    }
    
    func toMultiplayerCoop() {
        
    }
    
    func toMultiplayerSpectator() {
    
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
                onTap: { [weak self] in self?.toMission(index: index) })
        }
        return missions + [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: toMainMenu)
        ]
    }
    
    func getMultiplayer() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Co-op",
                onTap: toMultiplayerCoop),
            MenuTableViewCell.ViewModel(
                title: "Spectator",
                onTap: toMultiplayerSpectator),
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: toMainMenu)
        ]
    }
    
    func getSettings() -> [MenuCellViewModelProtocol] {
        return [
            SettingsViewCell.ViewModel(
                title: "Sound",
                preference: .sound),
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: toMainMenu)
        ]
    }
    
    func getEnciclopedia() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Towers",
                onTap: toTowersEnciclopedia),
            MenuTableViewCell.ViewModel(
                title: "Creeps",
                onTap: toCreepsEnciclopedia),
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap: toMainMenu)
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
                onTap: toEnciclopedia)
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
                onTap: toEnciclopedia)
        ]
    }
}
