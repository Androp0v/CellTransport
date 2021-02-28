//
//  ParametersViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 27/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import SwiftUI

class ParametersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var bottomSheetView: UIView!

    var heightConstraint: NSLayoutConstraint?

    struct CellConfig {
        let name: String
        let typeIdentifier: String
        let setFromUI: ((String) -> Bool)?
        let getForUI: (() -> String?)?
        let pickerOptions: [String]?
    }

    private var cells: [CellConfig] = []

    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set initial restart simulation view height to zero (hidden)
        heightConstraint = bottomSheetView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true

        // Register custom cells used
        tableView.register(UINib(nibName: "TextInputParameterTableViewCell", bundle: nil), forCellReuseIdentifier: "parameterTextInputCell")
        tableView.register(UINib(nibName: "SwitchParameterTableViewCell", bundle: nil), forCellReuseIdentifier: "parameterSwitchCell")
        tableView.register(PickerParameterTableViewCell<PickerAndDropDownView>.self, forCellReuseIdentifier: "parameterPickerCell")

        // Datasource and delegate
        self.tableView.delegate = self
        self.tableView.dataSource = self

        // Top spacing for segmented control bar
        self.tableView.contentInset = UIEdgeInsets(top: 97.5, left: 0, bottom: 0, right: 0)

        // Footer to remove bottom separators
        self.tableView.tableFooterView = UIView()

        // Automatic height
        self.tableView.rowHeight = UITableView.automaticDimension

        // MARK: - Add cells

        // Dynamic values: can be changed on-the-fly
        cells.append(CellConfig(name: "Attachment probability:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setWON,
                                getForUI: { return String(Parameters.wON) },
                                pickerOptions: nil))
        cells.append(CellConfig(name: "Detachment probability:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setWOFF,
                                getForUI: { return String(Parameters.wOFF) },
                                pickerOptions: nil))
        cells.append(CellConfig(name: "Viscosity:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setViscosity,
                                getForUI: { return String(Parameters.n_w) },
                                pickerOptions: nil))
        cells.append(CellConfig(name: "Collisions enabled:",
                                typeIdentifier: "parameterSwitchCell",
                                setFromUI: toggleCollisions,
                                getForUI: { return String(Parameters.collisionsFlag) },
                                pickerOptions: nil))
        cells.append(CellConfig(name: "Molecular motors:",
                                typeIdentifier: "parameterPickerCell",
                                setFromUI: setMolecularMotors,
                                getForUI: getMolecularMotors,
                                pickerOptions: ["Kinesins", "Dyneins"]))

        // Require simulation restart
        cells.append(CellConfig(name: "Number of cells:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setNCells,
                                getForUI: { return String(Parameters.nCells) },
                                pickerOptions: nil))
        cells.append(CellConfig(name: "Number of organelles:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: nil,
                                getForUI: { return String(Parameters.nbodies) },
                                pickerOptions: nil))
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cells.count
    }

    // MARK: - Cell creation

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch cells[indexPath.row].typeIdentifier {

        case "parameterTextInputCell":
            // TextInput cells initialization
            var cell = tableView.dequeueReusableCell(withIdentifier: "parameterTextInputCell", for: indexPath) as? TextInputParameterTableViewCell
            cell?.setTitleLabel(text: cells[indexPath.row].name)
            cell?.valueGetter = cells[indexPath.row].getForUI
            cell?.valueSetter = cells[indexPath.row].setFromUI
            cell?.fetchParameterValue()
            guard cell != nil else {
                cell = TextInputParameterTableViewCell.init()
                return cell!
            }
            return cell!

        case "parameterSwitchCell":
            // Switch cells initialization
            var cell = tableView.dequeueReusableCell(withIdentifier: "parameterSwitchCell", for: indexPath) as? SwitchParameterTableViewCell
            cell?.setTitleLabel(text: cells[indexPath.row].name)
            cell?.valueGetter = cells[indexPath.row].getForUI
            cell?.valueSetter = cells[indexPath.row].setFromUI
            cell?.fetchParameterValue()
            guard cell != nil else {
                cell = SwitchParameterTableViewCell.init()
                return cell!
            }
            return cell!

        case "parameterPickerCell":
            // Switch cells initialization
            var cell = tableView.dequeueReusableCell(withIdentifier: "parameterPickerCell",
                                                     for: indexPath) as? PickerParameterTableViewCell<PickerAndDropDownView>
            cell?.valueGetter = cells[indexPath.row].getForUI
            cell?.valueSetter = cells[indexPath.row].setFromUI
            guard cell != nil else {
                cell = PickerParameterTableViewCell.init()
                // Create a HostViewController for the SwiftUI view (only way to have pickers/dropdown menus on .mac idiom)
                cell!.host(PickerAndDropDownView(titleLabel: cells[indexPath.row].name,
                                                 pickerOptions: cells[indexPath.row].pickerOptions ?? [],
                                                 setter: cells[indexPath.row].setFromUI),
                           parent: self)
                cell?.fetchParameterValue()
                return cell!
            }
            // Create a HostViewController for the SwiftUI view (only way to have pickers/dropdown menus on .mac idiom)
            cell!.host(PickerAndDropDownView(titleLabel: cells[indexPath.row].name,
                                             pickerOptions: ["Kinesins", "Dyneins"],
                                             setter: cells[indexPath.row].setFromUI),
                       parent: self)
            cell?.fetchParameterValue()
            return cell!

        default:
            return UITableViewCell()
        }

    }

}
