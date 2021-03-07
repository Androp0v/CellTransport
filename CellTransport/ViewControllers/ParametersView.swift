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

    let bottomSheetHeight: CGFloat = 90.0

    // Changing the value of this variables changes it on the rows too, since the
    // values are binded
    @State var wONString = String()
    @State var wOFFString = String()
    @State var nCellsString = String()

    // MARK: - View Body
    var body: some View {
        // Zstack containing the table itself and the restart simulation button
        // which muast be drawn on top of the other view.
        ZStack {
            List {
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
                ParameterSectionTitleRow(sectionTitle: "Require restart")
                TextInputParameterRow(parameterName: "Number of cells:",
                                      fieldValue: $nCellsString,
                                      setValue: setNCells,
                                      getValue: getNCells)
                    .onReceive(notSetParameters.$nCells, perform: { value in
                        self.nCellsString = value
                    })
            }
            VStack {
                Spacer()
                ZStack(alignment: .center) {
                    Color.red
                    Button(action: {}, label: {
                        Text("Restart simulation")
                    })
                    .foregroundColor(.white)
                }
                .frame(height: bottomSheetHeight)
                .onReceive(notSetParameters.$needsRestart, perform: { needsRestart in
                    showBottomSheet = needsRestart
                })
                .offset(y: showBottomSheet ? 0 : bottomSheetHeight)
            }
            .ignoresSafeArea()
        }
    }
}

struct ParametersView: View {

    @StateObject var notSetParameters = NotSetParameters.shared

    var body: some View {
        NavigationView {
            ParametersContent()
                // Set the environment object first so notSetParameters is available
                // in ParametersContent view
                .environmentObject(notSetParameters)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ParametersView_Previews: PreviewProvider {
    static var previews: some View {
        ParametersView()
            .previewLayout(.fixed(width: 300, height: 800))
    }
}
