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
    case requestPlacingStatus
    case recievePlacingStatus
    case updateCoins
    case updateHP
    case updateWaves
    
    //TODO
    case insertTower
    case upgradeTower
    case sellTower
    case rotateTower
    
    var key: String { return self.rawValue }
}

struct CollaborativeSessionModel: Codable {
    var key: String
    var parameters: Data?
}

extension GameViewController: MultipeerHelperDelegate {
    func receivedData(_ data: Data, _ peer: MCPeerID) {
        guard let decodedModel = try? JSONDecoder().decode(CollaborativeSessionModel.self, from: data), let collabSessionKey = CollaborativeSessionKeys.init(rawValue: decodedModel.key) else { return }
        switch collabSessionKey {
        case .requestMission:
            guard let mission = gameViewModel.currentMission else { break }
            let encodedableModel = CollaborativeSessionModel(key: CollaborativeSessionKeys.recieveMission.key, parameters: try? JSONEncoder().encode(mission))
            guard let data = try? JSONEncoder().encode(encodedableModel) else { return }
            multipeerHelper.sendToAllPeers(data)
            
        case .requestPlacingStatus:
            guard let params = decodedModel.parameters, let entities = try? JSONDecoder().decode([String].self, from: params) else { return }
            guard !entities.isEmpty else { return }
            self.gameViewModel.checkPlacing(on: entities.compactMap({UInt64($0)}), source: .coop)
            
        case .insertTower:
            guard let params = decodedModel.parameters, let towerTypeString = try? JSONDecoder().decode(String.self, from: params), let towerType = TowerType(rawValue: towerTypeString) else { return }
            self.gameViewModel.placeTower(with: towerType, from: .coop)
        case .upgradeTower:
            guard let params = decodedModel.parameters,
                  let towerKey = try? JSONDecoder().decode(String.self, from: params),
                  let typeKey = towerKey.split(separator: "-").first, let type = TowerType(rawValue: String(typeKey)),
                  let lvlKey = towerKey.split(separator: "-").last, let lvl = TowerLevel(rawValue: String(lvlKey)) else { return }
            self.gameViewModel.upgradeTower(with: type, towerLvl: lvl, from: .coop)
        case .sellTower:
            guard let params = decodedModel.parameters,
                  let towerKey = try? JSONDecoder().decode(String.self, from: params),
                  let typeKey = towerKey.split(separator: "-").first, let type = TowerType(rawValue: String(typeKey)),
                  let lvlKey = towerKey.split(separator: "-").last, let lvl = TowerLevel(rawValue: String(lvlKey)) else { return }
            self.gameViewModel.sellTower(with: type, towerLvl: lvl, from: .coop)
        case .rotateTower:
            guard let params = decodedModel.parameters, let clockwise = try? JSONDecoder().decode(Bool.self, from: params) else { return }
            self.gameViewModel.rotateTower(clockwise: clockwise, from: .coop)
        case .recieveMission:
            DispatchQueue.main.async {
                self.dismiss(animated: false, completion: nil)
                guard let params = decodedModel.parameters, let mission = try? JSONDecoder().decode(Int.self, from: params) else { return }
                self.menuViewModel.toMission(index: mission, connected: true, sessionType: self.gameViewModel.sessionType)
            }
        case .recievePlacingStatus:
            guard let params = decodedModel.parameters, let stripKey = try? JSONDecoder().decode(String.self, from: params) else { return }
            switch stripKey {
            case "placing":
                self.gameViewModel.updateSyncStrip(with: .host, for: .placing)
            case let towerKey where towerKey.contains("-"):
                guard let typeKey = towerKey.split(separator: "-").first, let type = TowerType(rawValue: String(typeKey)) else { return }
                guard let lvlKey = towerKey.split(separator: "-").last, let lvl = TowerLevel(rawValue: String(lvlKey)) else { return }
                self.gameViewModel.updateSyncStrip(with: .host, for: .tower(type: type, lvl: lvl))
            case "none":
                self.gameViewModel.updateSyncStrip(with: .host, for: .none)
            default:
                break
            }
        case .updateCoins:
            guard let params = decodedModel.parameters, let coins = try? JSONDecoder().decode(String.self, from: params) else { return }
            DispatchQueue.main.async {
                self.coinsLabel.text = coins
            }
        case .updateHP:
            guard let params = decodedModel.parameters, let hp = try? JSONDecoder().decode(String.self, from: params) else { return }
            DispatchQueue.main.async {
                self.hpLabel.text = hp
            }
        case .updateWaves:
            guard let params = decodedModel.parameters, let waves = try? JSONDecoder().decode(String.self, from: params) else { return }
            DispatchQueue.main.async {
                self.waveLabel.text = waves
            }
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

