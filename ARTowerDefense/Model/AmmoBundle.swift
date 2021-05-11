//
//  AmmoBundle.swift
//  First Attempt
//
//  Created by Daniel Aragon Ore on 3/27/21.
//  Copyright © 2021 Daniel Aragon. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import Combine

class AmmoBundle: ModelBundle {
    internal init(bundle: ModelBundle) {
        self.subscriptions = []
        super.init(bundle)
    }
    var subscriptions: [Cancellable]
}
