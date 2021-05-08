//
//  GameViewModel.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation
import Combine

protocol MenuViewModelProtocol {
    var viewStatePublisher: Published<MenuViewState>.Publisher { get }
    func presentMenu()
}

