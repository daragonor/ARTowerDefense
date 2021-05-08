//
//  StartMenuTableViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/3/21.
//

import UIKit

class HeaderTableViewCell: UITableViewCell, CellProtocol  {
    struct ViewModel: MenuCellViewModelProtocol {
        var identifier: String = "HeaderTableViewCell"
        var contentHeight: Float = 300.0
    }
    func setup(with viewModel: CellViewModelProtocol) {}
}
