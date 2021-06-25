//
//  CreepEnciclopediaTableViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/6/21.
//

import UIKit

class CreepEnciclopediaViewCell: UITableViewCell, CellProtocol {
    struct ViewModel: CellViewModelProtocol, MenuCellViewModelProtocol {
        var identifier: String = "CreepEnciclopediaViewCell"
        var image: String
        var type: String
        var speed: String
        var resistance: String
        var description: String
        var contentHeight: Float = 150.0
    }
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var resistanceLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(with viewModel: CellViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        iconImageView.image = UIImage(named: viewModel.image)
        typeLabel.text = viewModel.type
        resistanceLabel.text = "Resistance: \(viewModel.resistance)"
        speedLabel.text = "Speed: \(viewModel.speed)"
        descriptionLabel.text = viewModel.description
    }
}

