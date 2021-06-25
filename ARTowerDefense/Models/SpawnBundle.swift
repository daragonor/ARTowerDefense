//
//  SpawnBundle.swift
//  First Attempt
//
//  Created by Daniel Aragon Ore on 3/27/21.
//  Copyright © 2021 Daniel Aragon. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import Combine

class SpawnBundle {
    internal init(model: ModelEntity, position: Position, map: Int) {
        self.model = model
        self.position = position
        self.map = map
    }
    
    var model: ModelEntity
    var position: Position
    var map: Int
}
