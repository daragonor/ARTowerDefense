//
//  UnitBundle.swift
//  First Attempt
//
//  Created by Daniel Aragon Ore on 3/27/21.
//  Copyright © 2021 Daniel Aragon. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import Combine

class UnitBundle: ModelBundle {
    internal init(bundle: ModelBundle, hpBarId: UInt64, hp: Float, maxHP: Float) {
        self.hpBarId = hpBarId
        self.hp = hp
        self.maxHP = maxHP
        super.init(bundle)
    }    
    
    var hpBarId: UInt64
    var hp: Float
    var maxHP: Float
}
