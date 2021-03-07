//
//  ParametersView.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 6/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct ParametersContent: View {

    // MARK: - Variables

    @EnvironmentObject var notSetParameters: NotSetParameters
    @State var showBottomSheet: Bool = true
    let mainController: GameViewController?
    
    let bottomSheetHeight: CGFloat = 60.0

    // Changing the value of this variables changes it on the rows too, since the
    // values are binded
    @State var wONString = String()
    @State var wOFFString = String()
    @State var nCellsString = String()
    @State var nBodiesPerCellString = String()
    @State var collisionsEnabled = Bool()
    @State var viscosityString = String()
    @State var molecularMotor = Int32()
    @State var boundaryConditions = Int32()
    @State var cellShape = Int32()

    // MARK: - View Body
    var body: some View {
        // Zstack containing the table itself and the restart simulation button
        // which muast be drawn on top of the other view.
        ZStack {
            NavigationView {
                Form {
                    List {
                        // MARK: - Dynamic parameters
                        Section(header: Text("Dynamic parameters"), content: {
                            TextInputParameterRow(parameterName: "Attachment probability:",
                                                  fieldValue: $wONString,
                                                  setValue: setWON,
                                                  getValue: getWON)
                                .onReceive(notSetParameters.$wON, perform: { value in
                                    self.wONString = value
                                })
                            TextInputParameterRow(parameterName: "Detachment probability:",
                                                  fieldValue: $wOFFString,
                                                  setValue: setWOFF,
                                                  getValue: getWOFF)
                                .onReceive(notSetParameters.$wOFF, perform: { value in
                                    self.wOFFString = value
                                })
                            TextInputParameterRow(parameterName: "Viscosity:",
                                                  fieldValue: $viscosityString,
                                                  setValue: setViscosity,
                                                  getValue: getViscosity)
                                .onReceive(notSetParameters.$n_w, perform: { value in
                                    self.viscosityString = value
                                })
                            SwitchParameterRow(parameterName: "Collisions enabled:",
                                               fieldValue: $collisionsEnabled,
                                               setValue: toggleCollisions,
                                               getValue: getCollisionsEnabled)
                                .onReceive(notSetParameters.$collisionsEnabled, perform: { value in
                                    self.collisionsEnabled = value
                                })
                            PickerParameterRow(parameterName: "Molecular motors",
                                               selectedParameter: $molecularMotor,
                                               pickerOptions: ["Kinesins",
                                                               "Dyneins"],
                                               setValue: setMolecularMotors,
                                               getValue: getMolecularMotors)
                                .onReceive(notSetParameters.$molecularMotors, perform: { value in
                                    self.molecularMotor = value
                                })
                            PickerParameterRow(parameterName: "Boundary conditions",
                                               selectedParameter: $boundaryConditions,
                                               pickerOptions: ["Reinject inside",
                                                               "Reinject outside",
                                                               "Contain inside"],
                                               setValue: setBoundaryConditions,
                                               getValue: getBoundaryConditions)
                                .onReceive(notSetParameters.$boundaryConditions, perform: { value in
                                    self.boundaryConditions = value
                                })

                        })

                        // MARK: - Require restart
                        Section(header: Text("Require restart"), content: {
                            TextInputParameterRow(parameterName: "Number of cells:",
                                                  fieldValue: $nCellsString,
                                                  setValue: setNCells,
                                                  getValue: getNCells)
                                .onReceive(notSetParameters.$nCells, perform: { value in
                                    self.nCellsString = value
                                })
                            TextInputParameterRow(parameterName: "Particles per cell:",
                                                  fieldValue: $nBodiesPerCellString,
                                                  setValue: setNBodiesPerCell,
                                                  getValue: getNBodiesPerCell)
                                .onReceive(notSetParameters.$nbodies, perform: { _ in
                                    self.nBodiesPerCellString = getNBodiesPerCell()
                                })
                                // Subscribe to changes on nCells too, since the displayed parameter
                                // depends on both nCells and nBodies
                                .onReceive(notSetParameters.$nCells, perform: { _ in
                                    self.nBodiesPerCellString = getNBodiesPerCell()
                                })
                            PickerParameterRow(parameterName: "Cell shape",
                                               selectedParameter: $cellShape,
                                               pickerOptions: ["Spherical",
                                                               "Orthogonal"],
                                               setValue: setCellShape,
                                               getValue: getCellShape)
                                .onReceive(notSetParameters.$cellShape, perform: { value in
                                    self.cellShape = value
                                })
                        })
                    }
                }
            }
            VStack {
                Spacer()
                ZStack(alignment: .center) {
                    Color.red
                    Button(action: {
                        DispatchQueue.global().async {
                            mainController?.restartSimulation()
                        }
                    }, label: {
                        Text("Restart simulation")
                    })
                    .foregroundColor(.white)
                }
                .frame(height: bottomSheetHeight)
                .onReceive(notSetParameters.$needsRestart, perform: { needsRestart in
                    showBottomSheet = needsRestart
                })
                .offset(y: showBottomSheet ? 0 : bottomSheetHeight)
                .animation(.easeInOut)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Parent view
struct ParametersView: View {

    @StateObject var notSetParameters = NotSetParameters.shared
    let mainController: GameViewController?

    var body: some View {
        ParametersContent(mainController: mainController)
            // Set the environment object first so notSetParameters is available
            // in ParametersContent view
            .environmentObject(notSetParameters)
    }
}

// MARK: - Preview provider
struct ParametersView_Previews: PreviewProvider {
    static var previews: some View {
        ParametersView(mainController: nil)
            .previewLayout(.fixed(width: 300, height: 800))
    }
}
