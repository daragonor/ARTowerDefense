//
//  ViewController.swift
//  ARTowerDefense
//
//  Created by Daniel Aragon Ore on 5/1/21.
//

import UIKit
import RealityKit
import Combine
import MultipeerHelper

extension GameViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case stripTableView: return stripContext.count
        case menuTableView: return menuContext.count
        default: return .zero
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case menuTableView: return tableView.getCell(from: menuContext, at: indexPath)
        case stripTableView:
            let cell = tableView.getCell(from: stripContext, at: indexPath)
            cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
            return cell
        default: return UITableViewCell()
        }
    }
    
}

extension UITableView {
    func getCell(from context: [CellViewModelProtocol],
                 at indexPath: IndexPath) -> UITableViewCell {
        let row = context[indexPath.row]
        let cell = dequeueReusableCell(withIdentifier: row.identifier, for: indexPath)
        if let cell = cell as? CellProtocol { cell.setup(with: row) }
        return cell
    }
}
