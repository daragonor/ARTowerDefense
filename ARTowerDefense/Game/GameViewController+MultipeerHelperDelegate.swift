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

enum CollaborativeSessionKeys: String {
    case requestMission
    case recieveMission
    var key: String { return self.rawValue }
}

struct CollaborativeSessionModel: Codable {
    var key: String
    var parameters: Data?
}

extension GameViewController: MultipeerHelperDelegate {
//    func shouldSendJoinRequest(
//        _ peer: MCPeerID,
//        with discoveryInfo: [String: String]?
//    ) -> Bool {
//        GameViewController.checkPeerToken(with: discoveryInfo)
//    }
    func receivedData(_ data: Data, _ peer: MCPeerID) {
        guard let decodedModel = try? JSONDecoder().decode(CollaborativeSessionModel.self, from: data), let collabSessionKey = CollaborativeSessionKeys.init(rawValue: decodedModel.key) else { return }
        switch collabSessionKey {
        case .requestMission:
            guard let mission = gameViewModel.currentMission else { break }
            let encodedableModel = CollaborativeSessionModel(key: CollaborativeSessionKeys.recieveMission.key, parameters: try? JSONEncoder().encode(mission))
            guard let data = try? JSONEncoder().encode(encodedableModel) else { return }
            multipeerHelper.sendToAllPeers(data)
        case .recieveMission:
            guard let params = decodedModel.parameters, let mission = try? JSONDecoder().decode(Int.self, from: params) else { return }
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: false, completion: nil)
            }
            
            menuViewModel.toMission(index: mission, connected: true)
        }
    }
    func setupMultipeerHelper() {
        multipeerHelper = MultipeerHelper(
            serviceName: "helper-test",
            sessionType: .both,
            delegate: self)
        // MARK: - Setting RealityKit Synchronization
        
        guard let syncService = multipeerHelper.syncService else {
            fatalError("could not create multipeerHelp.syncService")
        }
        
        arView.scene.synchronizationService = syncService
        
    }
}

