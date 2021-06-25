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
    func toMission(index: Int, connected: Bool, sessionType: SessionType) {
        viewState = .startMission(mission: index, connected: connected, sessionType: sessionType)
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
    
    func toMultiplayerMenu() {
        viewState = .showContext(getMultiplayer())
    }
    
    func fetchConnectedPeers(_ sessionType: SessionType) {
        viewState = .fetchConnectedPeers(sessionType: sessionType)
    }
    
    func toMissions(connected: Bool, sessionType: SessionType) {
        viewState = .showContext(getMissions(connected, sessionType))
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
                onTap: { self.toMissions(connected: false, sessionType: .host) }),
            MenuTableViewCell.ViewModel(
                title: "Multiplayer",
                onTap: toMultiplayerMenu),
            MenuTableViewCell.ViewModel(
                title: "Settings",
                onTap: toSettings),
            MenuTableViewCell.ViewModel(
                title: "Enciclopedia",
                onTap: toEnciclopedia)
        ]
    }
    
    func getMissions(_ connected: Bool, _ sessionType: SessionType) -> [MenuCellViewModelProtocol] {
        let missions = config.missions.enumerated().map { (index, mission) in
            return MenuTableViewCell.ViewModel(
                    title: "Mission \(index + 1)",
                onTap: { [weak self] in self?.toMission(index: index, connected: connected, sessionType: sessionType) })
        }
        return missions + [
            MenuTableViewCell.ViewModel(
                title: "Back",
                onTap:  connected ? toMultiplayerMenu : toMainMenu)
        ]
    }
    
    func getMultiplayer() -> [MenuCellViewModelProtocol] {
        return [
            MenuTableViewCell.ViewModel(
                title: "Host",
                onTap: { self.toMissions(connected: true, sessionType: .host) }),
            MenuTableViewCell.ViewModel(
                title: "Co-op",
                onTap: { self.fetchConnectedPeers(.coop) }),
            MenuTableViewCell.ViewModel(
                title: "Spectator",
                onTap: { self.fetchConnectedPeers(.spectator) }),
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
