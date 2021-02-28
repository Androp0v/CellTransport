//
//  ParametersTableViewController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 27/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class ParametersTableViewController: UITableViewController {

    struct CellConfig {
        let name: String
        let typeIdentifier: String
        let setFromUI: ((String) -> Bool)?
        let getForUI: (() -> String?)?
    }

    private var cells: [CellConfig] = []

    // MARK: - Configuration

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register custom cells used
        tableView.register(UINib(nibName: "TextInputParameterTableViewCell", bundle: nil), forCellReuseIdentifier: "parameterTextInputCell")
        tableView.register(UINib(nibName: "SwitchParameterTableViewCell", bundle: nil), forCellReuseIdentifier: "parameterSwitchCell")

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
                                getForUI: { return String(Parameters.wON) }))
        cells.append(CellConfig(name: "Detachment probability:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setWOFF,
                                getForUI: { return String(Parameters.wOFF) }))
        cells.append(CellConfig(name: "Viscosity:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setViscosity,
                                getForUI: { return String(Parameters.n_w) }))
        cells.append(CellConfig(name: "Collisions enabled:",
                                typeIdentifier: "parameterSwitchCell",
                                setFromUI: toggleCollisions,
                                getForUI: { return String(Parameters.collisionsFlag) }))

        // Require simulation restart
        cells.append(CellConfig(name: "Number of cells:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: setNCells,
                                getForUI: { return String(Parameters.nCells) }))
        cells.append(CellConfig(name: "Number of organelles:",
                                typeIdentifier: "parameterTextInputCell",
                                setFromUI: nil,
                                getForUI: { return String(Parameters.nbodies) }))
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

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
        default:
            return UITableViewCell()
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}
