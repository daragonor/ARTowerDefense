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

class CreepBundle: UnitBundle {
    internal init(bundle: ModelBundle, hpBarId: UInt64, type: CreepType, animation: AnimationPlaybackController? = nil, subscription: Cancellable? = nil) {
        self.type = type
        self.animation = animation
        self.subscription = subscription
        super.init(bundle: bundle, hpBarId: hpBarId, hp: type.maxHP, maxHP: type.maxHP)
    }
    var type: CreepType
    var animation: AnimationPlaybackController?
    var subscription: Cancellable?
}
