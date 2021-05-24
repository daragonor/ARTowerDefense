//
//  CreepBundle.swift
//  First Attempt
//
//  Created by Daniel Aragon Ore on 3/27/21.
//  Copyright © 2021 Daniel Aragon. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import Combine

class PlacingBundle {
    internal init(model: ModelEntity, position: Position, towerId: UInt64? = nil) {
        self.model = model
        self.position = position
        self.towerId = towerId
    }
        
    var model: ModelEntity
    var position: Position
    var towerId: UInt64?
}
