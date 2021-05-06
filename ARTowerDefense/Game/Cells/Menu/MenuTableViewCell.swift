//
//  MenuTableViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import UIKit

class MenuTableViewCell: UITableViewCell, CellProtocol {
    struct ViewModel: CellViewModelProtocol, MenuCellViewModelProtocol {
        var identifier: String = "Menu Cell"
        var title: String
        var contentHeight: Float = 50.0
        var onTap: () -> Void
    }
    var viewModel: ViewModel?
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        cardView.isUserInteractionEnabled = true
        cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTappedAction)))
    }
    
    func setup(with viewModel: CellViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        self.viewModel = viewModel
        titleLabel.text = viewModel.title
    }
    
    @objc func cellTappedAction() {
        self.viewModel?.onTap()
    }
}
