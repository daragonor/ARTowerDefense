//
//  ModelUtils.swift
//  First Attempt
//
//  Created by Daniel Aragon on 7/8/20.
//  Copyright © 2020 Daniel Aragon. All rights reserved.
//

import Foundation
enum ModelType: String, CaseIterable {
    case path, pathDownwards, pathUpwards, towerPlacing, here, goal, spawnPort, bullet
    var key: String {
        return self.rawValue
    }
    var scalingFactor: Float {
        switch self {
        case .path, .towerPlacing: return 0.000125
        case .pathUpwards, .pathDownwards: return 0.0125
        case .here: return 0.0003
        case .bullet: return 0.002
        case .goal: return 0.0001
        case .spawnPort: return 0.0002
        }
    }
}
enum CreepType: String, CaseIterable {
    case heavy, regular, small, flying
    
    var key: String {
        return self.rawValue
    }
    
    var scalingFactor: Float {
        switch self {
        case .flying: return 0.000007
        case .heavy: return 0.00002
        case .regular: return 0.00001
        case .small: return 0.00001
        }
    }
    
    var angleOffset: Float {
        switch self {
        case .regular: return .pi
        case .flying, .heavy, .small: return 0.0
        }
    }

    var attack: Float {
        switch self {
        case .heavy: return 30.0
        case .regular, .flying: return 20.0
        case .small: return 10.0
        }
    }
    
    var heightOffset: Float {
        switch self {
        case .heavy, .regular, .small: return 0.03
        case .flying: return 0.13
        }
    }
    
    var speed: Float {
        ///in seconds per tile
        switch self {
        case .heavy: return 4.0
        case .regular: return 2.0
        case .small: return 0.75
        case .flying: return 1.25
        }
    }
    
    var maxHP: Float {
        switch self {
        case .heavy: return 250.0
        case .regular: return 100.0
        case .small: return 70.0
        case .flying: return 100.0
        }
    }
    
    var cadence: Float {
        switch self {
        case .heavy: return 1.5 // 3-4
        case .regular: return 0.75 // 1.5
        case .small: return 0.4 // 0.8
        case .flying: return 0.2
        }
    }
    var reward: Int {
        switch self {
        case .heavy: return 40
        case .regular: return 10
        case .small: return 10
        case .flying: return 25
        }
    }
}

enum TowerLevel: String, CaseIterable {
    case lvl1, lvl2, lvl3
    var key: String {
        return self.rawValue
    }
    var nextLevel: TowerLevel {
        switch self {
        case .lvl1: return .lvl2
        case .lvl2: return .lvl3
        case .lvl3: return .lvl3
        }
    }
}

enum TowerType: String, CaseIterable {
    case turret, rocket, barracks
    func key(_ lvl: TowerLevel) -> String {
        return "\(self.rawValue)\(lvl.rawValue.firstUppercased)"
    }
    static var scalingFactor: Float {
        return 0.00047
    }
    
    func cost(lvl: TowerLevel) -> Int {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 150
            case .rocket: return 200
            case .barracks: return 100
            }
        case .lvl2:
            switch self {
            case .turret: return 250
            case .rocket: return 400
            case .barracks: return 200
            }
        case .lvl3:
            switch self {
            case .turret: return 350
            case .rocket: return 600
            case .barracks: return 300
            }
        }
    }
    var range: Float {
        switch self {
        case .turret: return 2.5
        case .rocket: return 4.5
        case .barracks: return 1.0
        }
    }
    func maxHP(lvl: TowerLevel) -> Float {
        switch self {
        case .barracks:
            switch lvl {
            case .lvl1: return 50.0
            case .lvl2: return 75.0
            case .lvl3: return 100.0
            }
        default: return 0.0
        }
    }
    
    func capacity(lvl: TowerLevel) -> Int {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 1
            case .rocket: return 2
            case .barracks: return 1
            }
        case .lvl2:
            switch self {
            case .turret: return 1
            case .rocket: return 4
            case .barracks: return 2
            }
        case .lvl3:
            switch self {
            case .turret: return 1
            case .rocket: return 6
            case .barracks: return 3
            }
        }
    }
    
    func cadence(lvl: TowerLevel) -> Float {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 1.0
            case .rocket: return 2.5
            case .barracks: return 0.7
            }
        case .lvl2:
            switch self {
            case .turret: return 0.75
            case .rocket: return 2.25
            case .barracks: return 0.5
            }
        case .lvl3:
            switch self {
            case .turret: return 0.5
            case .rocket: return 2
            case .barracks: return 0.3
            }
        }
    }
    
    func attack(lvl: TowerLevel) -> Float {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 5
            case .rocket: return 20
            case .barracks: return 20
            }
        case .lvl2:
            switch self {
            case .turret: return 15
            case .rocket: return 30
            case .barracks: return 30
            }
        case .lvl3:
            switch self {
            case .turret: return 25
            case .rocket: return 40
            case .barracks: return 40
            }
        }
    }
}
