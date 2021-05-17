//
//  StripViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/15/21.
//

import UIKit

class StripViewCell: UITableViewCell, CellProtocol {
    struct ViewModel: CellViewModelProtocol {
        var identifier: String = "StripViewCell"
        var image: UIImage
        var title: String?
        var onTap: () -> Void
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stripImageView: UIImageView!
    var viewModel: ViewModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.layer.cornerRadius = 30.0
    }
    
    func setup(with viewModel: CellViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        self.viewModel = viewModel
        if let title = viewModel.title {
            titleLabel.text = title
            titleLabel.isHidden = false
        } else { titleLabel.isHidden = true }
        stripImageView.image = viewModel.image
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapAction)))
    }
    
    @objc func onTapAction() {
        viewModel?.onTap()
    }
}
