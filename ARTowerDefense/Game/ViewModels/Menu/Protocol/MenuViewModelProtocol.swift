//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine
import MultipeerConnectivity

protocol MenuViewModelProtocol {
    var viewStatePublisher: Published<MenuViewState>.Publisher { get }
    func presentMenu()
    func toMissions(connected: Bool, sessionType: SessionType)
    func toMission(index: Int, connected: Bool, sessionType: SessionType)
}

