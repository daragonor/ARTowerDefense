//
//  GameViewController+MultipeerHelperDelegate.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/8/21.
//

import Foundation
import ARKit
import RealityKit
import MultipeerHelper
import MultipeerConnectivity
import UIKit

extension GameViewController: MultipeerHelperDelegate {
//    func shouldSendJoinRequest(
//        _ peer: MCPeerID,
//        with discoveryInfo: [String: String]?
//    ) -> Bool {
//        GameViewController.checkPeerToken(with: discoveryInfo)
//    }
    
    func setupMultipeerHelper() {
        multipeerHelper = MultipeerHelper(
            serviceName: "helper-test",
            sessionType: .both,
            delegate: self
        )
        
        // MARK: - Setting RealityKit Synchronization
        
        guard let syncService = multipeerHelper.syncService else {
            fatalError("could not create multipeerHelp.syncService")
        }
        
        arView.scene.synchronizationService = syncService
        
    }
}

