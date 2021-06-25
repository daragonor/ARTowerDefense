//
//  CellProtocol.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import Foundation

public protocol CellProtocol {
    func setup(with viewModel: CellViewModelProtocol)
}

public protocol CellViewModelProtocol {
    var identifier: String { get }
}

public protocol CellDelegate: AnyObject {}

public protocol MenuCellViewModelProtocol: CellViewModelProtocol {
    var contentHeight: Float { get }
}
