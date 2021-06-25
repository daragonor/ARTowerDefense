//
//  SettingsViewCell.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/8/21.
//

import UIKit

class SettingsViewCell: UITableViewCell, CellProtocol {
    struct ViewModel: CellViewModelProtocol, MenuCellViewModelProtocol {
        var identifier: String = "SettingsViewCell"
        var title: String
        var preference: SettingsPreferences
        var contentHeight: Float = 100.0
    }
    @IBOutlet weak var cardView: CardView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    var viewModel: ViewModel!
    func setup(with viewModel: CellViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        self.viewModel = viewModel
        titleLabel.text = viewModel.title
        optionSwitch.isOn = UserDefaults.standard.bool(forKey: viewModel.preference.key)
    }
    
    @IBAction func switchValueChangedAction(_ sender: Any) {
        UserDefaults.standard.set(optionSwitch.isOn, forKey: viewModel.preference.key)
    }
}
