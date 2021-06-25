//
//  ModelUtils.swift
//  First Attempt
//
//  Created by Daniel Aragon on 7/8/20.
//  Copyright © 2020 Daniel Aragon. All rights reserved.
//

import Foundation
enum ModelType: String, CaseIterable {
    case path, pathDownwards, pathUpwards, towerPlacing, here, goal, spawnPort, bullet, flyingBomb, acidFloor
    var key: String {
        return self.rawValue.camelCaseToSnakeCase()
    }
    var scalingFactor: Float {
        switch self {
        case .acidFloor: return 0.000125
        case .path: return 0.05
        case .towerPlacing: return 0.0000248
        case .pathUpwards, .pathDownwards: return 0.0125
        case .here: return 0.0003
        case .bullet: return 0.002
        case .goal: return 0.0001
        case .spawnPort: return 0.0002
        case .flyingBomb: return 0.0002
        }
    }
}

enum CreepType: String, CaseIterable {
    case small, regular, heavy, flying
    
    var key: String {
        return self.rawValue.camelCaseToSnakeCase()
    }
    
    var scalingFactor: Float {
        switch self {
        case .flying: return 0.00001
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
    
    var nextLevel: TowerLevel {
        switch self {
        case .lvl1: return .lvl2
        case .lvl2: return .lvl3
        case .lvl3: return .lvl3
        }
    }
}

enum TowerType: String, CaseIterable {
    case turret, launcher, barracks
    var key: String { rawValue }
    func key(_ lvl: TowerLevel) -> String {
        return "\(self.rawValue)_\(lvl.rawValue)"
    }
    static var scalingFactor: Float {
        return 0.00047
    }
    
    func cost(lvl: TowerLevel) -> Int {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 150
            case .launcher: return 200
            case .barracks: return 100
            }
        case .lvl2:
            switch self {
            case .turret: return 250
            case .launcher: return 400
            case .barracks: return 200
            }
        case .lvl3:
            switch self {
            case .turret: return 350
            case .launcher: return 600
            case .barracks: return 300
            }
        }
    }
    var range: Float {
        switch self {
        case .turret: return 2.5
        case .launcher: return 4.5
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
            case .launcher: return 2
            case .barracks: return 1
            }
        case .lvl2:
            switch self {
            case .turret: return 1
            case .launcher: return 4
            case .barracks: return 2
            }
        case .lvl3:
            switch self {
            case .turret: return 1
            case .launcher: return 6
            case .barracks: return 3
            }
        }
    }
    
    func cadence(lvl: TowerLevel) -> Float {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 1.0
            case .launcher: return 2.5
            case .barracks: return 0.7
            }
        case .lvl2:
            switch self {
            case .turret: return 0.75
            case .launcher: return 2.25
            case .barracks: return 0.5
            }
        case .lvl3:
            switch self {
            case .turret: return 0.5
            case .launcher: return 2
            case .barracks: return 0.3
            }
        }
    }
    
    func attack(lvl: TowerLevel) -> Float {
        switch lvl {
        case .lvl1:
            switch self {
            case .turret: return 5
            case .launcher: return 10
            case .barracks: return 20
            }
        case .lvl2:
            switch self {
            case .turret: return 10
            case .launcher: return 20
            case .barracks: return 30
            }
        case .lvl3:
            switch self {
            case .turret: return 15
            case .launcher: return 30
            case .barracks: return 40
            }
        }
    }
}

enum LevelType: String, CaseIterable {
    case lvl01_ground001,lvl01_ground002,lvl01_ground003,lvl01_ground004,lvl01_ground005,
         lvl02_ground001,lvl02_ground002,lvl02_ground003,lvl02_ground004,lvl02_ground005,
         lvl03_ground001,lvl03_ground002,lvl03_ground003,lvl03_ground004,lvl03_ground005,
         lvl04_ground001,lvl04_ground002,lvl04_ground003,lvl04_ground004,lvl04_ground005,lvl04_higherbase001,lvl04_higherpath001,lvl04_higherpath002,lvl04_higherpath003,lvl04_higherpath004,
         lvl05_ground001,lvl05_ground002,lvl05_ground003,lvl05_ground004,lvl05_ground005,lvl05_higherbase001,lvl05_higherpath001,lvl05_higherpath002,lvl05_higherpath003,lvl05_higherpath004,lvl05_higherpath005,lvl06_ground001,lvl06_ground002,lvl06_ground003,lvl06_ground004,lvl06_ground005,lvl06_higherbase001,lvl06_higherpath001,lvl06_higherpath002,lvl06_higherpath003,lvl06_higherpath004
    var key: String {
        return self.rawValue
    }
    var scalingFactor: Float {
        switch self {
        case .lvl01_ground001,.lvl01_ground002,.lvl01_ground003,.lvl01_ground004,.lvl01_ground005,
             .lvl02_ground001,.lvl02_ground002,.lvl02_ground003,.lvl02_ground004,.lvl02_ground005,
             .lvl03_ground001,.lvl03_ground002,.lvl03_ground003,.lvl03_ground004,.lvl03_ground005,
             .lvl04_ground001,.lvl04_ground002,.lvl04_ground003,.lvl04_ground004,.lvl04_ground005,.lvl04_higherbase001,.lvl04_higherpath001,.lvl04_higherpath002,.lvl04_higherpath003,.lvl04_higherpath004,
             .lvl05_ground001,.lvl05_ground002,.lvl05_ground003,.lvl05_ground004,.lvl05_ground005,.lvl05_higherbase001,.lvl05_higherpath001,.lvl05_higherpath002,.lvl05_higherpath003,.lvl05_higherpath004,.lvl05_higherpath005,
             .lvl06_ground001,.lvl06_ground002,.lvl06_ground003,.lvl06_ground004,.lvl06_ground005,.lvl06_higherbase001,.lvl06_higherpath001,.lvl06_higherpath002,.lvl06_higherpath003,.lvl06_higherpath004:
            return 0.0000248
        }
    }
}

enum NeutralType: String, CaseIterable {
    case lvl00_neutral002
    var key: String {
        return self.rawValue
    }
    var scalingFactor: Float {
        switch self {
        case .lvl00_neutral002:
            return 0.0000248
        }
    }
}

class NeutralFloor {
    var key: String
    var rY: Direction

    init (key: String, rY: Direction){
        self.key = key
        self.rY = rY
    }
}

var neutral_Lvl01 = [
    NeutralFloor(key: "lvl01_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl01_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl01_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl01_ground005", rY: Direction.up)
]

var neutral_Lvl02 = [
    NeutralFloor(key: "lvl02_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl02_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground001", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl02_ground002", rY: Direction.right),
    NeutralFloor(key: "lvl02_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
]

var neutral_Lvl03 = [
    NeutralFloor(key: "lvl03_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl03_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl03_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl03_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl03_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl03_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl03_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
]

var higherPath_Lvl04 = [
    NeutralFloor(key: "lvl04_higherpath002", rY: Direction.up),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.up),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl04_higherpath002", rY: Direction.down),
    NeutralFloor(key: "lvl04_higherpath001", rY: Direction.up),
]

var neutral_Lvl04 = [
    NeutralFloor(key: "lvl04_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground001", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl04_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl04_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl04_ground003", rY: Direction.up),
]

var higherPath_Lvl05 = [
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.up),
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.left),
    NeutralFloor(key: "lvl05_higherpath001", rY: Direction.up),
    NeutralFloor(key: "lvl05_higherpath005", rY: Direction.right),
    NeutralFloor(key: "lvl05_higherpath001", rY: Direction.right),
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.up),
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.down),
    NeutralFloor(key: "lvl05_higherpath001", rY: Direction.right),
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.left),
    NeutralFloor(key: "lvl05_higherpath002", rY: Direction.right),
]

var neutral_Lvl05 = [
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground001", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground001", rY: Direction.left),
    NeutralFloor(key: "lvl05_ground002", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl05_ground005", rY: Direction.left),
]

var higherPath_Lvl06 = [
    NeutralFloor(key: "lvl06_higherpath002", rY: Direction.up),
    NeutralFloor(key: "lvl06_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl06_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl06_higherpath002", rY: Direction.left),
    NeutralFloor(key: "lvl06_higherpath001", rY: Direction.left),
    NeutralFloor(key: "lvl06_higherpath002", rY: Direction.up),
    NeutralFloor(key: "lvl06_higherpath001", rY: Direction.up),
    NeutralFloor(key: "lvl06_higherpath002", rY: Direction.down),
]

var neutral_Lvl06 = [
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground001", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground001", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground001", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.down),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground002", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.left),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.right),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.down),
    NeutralFloor(key: "lvl06_ground003", rY: Direction.left),
    NeutralFloor(key: "lvl06_ground005", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl06_ground004", rY: Direction.up),
    NeutralFloor(key: "lvl00_neutral002", rY: Direction.up),
]
