//
//  TowerEnciclopediaTableViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/6/21.
//

import UIKit

class TowerEnciclopediaViewCell: UITableViewCell, CellProtocol {
    struct ViewModel: CellViewModelProtocol, MenuCellViewModelProtocol {
        var identifier: String = "TowerEnciclopediaViewCell"
        var image: String
        var type: String
        var damage: String
        var speed: String
        var range: String
        var description: String
        var contentHeight: Float = 150.0
    }
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var damageLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var rangeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setup(with viewModel: CellViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        iconImageView.image = UIImage(named: viewModel.image)
        typeLabel.text = viewModel.type
        damageLabel.text = "Damage: \(viewModel.damage)"
        speedLabel.text = "Speed: \(viewModel.speed)"
        rangeLabel.text = "Range: \(viewModel.range)"
        descriptionLabel.text = viewModel.description
    }
}

