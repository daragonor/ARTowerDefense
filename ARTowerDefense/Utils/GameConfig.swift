//
//  GameConfig.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/8/21.
//

import Foundation

struct GameConfig: Codable {
    var missions: [MissionModel]
    var enciclopedia: Enciclopedia
    var initialValues: ConfigInitialValues
}

struct Enciclopedia: Codable {
    var towers: [TowerEnciclopedia]
    var creeps: [CreepEnciclopedia]
}

struct TowerEnciclopedia: Codable {
    var image: String
    var type: String
    var damage: String
    var speed: String
    var range: String
    var description: String
}

struct CreepEnciclopedia: Codable {
    var image: String
    var type: String
    var speed: String
    var resistance: String
    var description: String
}

struct MissionModel: Codable {
    var difficulty: Int
    var waves: Int
    var maps: [MapModel]
}

struct ConfigInitialValues: Codable {
    var gridDiameter: Float
    var waveInterval: Float
    var coins: Int
    var playerHp: Int
    var graceTime: Int
    var creepsPerWave: Int
}
