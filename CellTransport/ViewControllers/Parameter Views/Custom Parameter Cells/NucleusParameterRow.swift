//
//  NucleusParameterRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 14/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct NucleusParameterRow: View {

    @State var parameterName: String
    @Binding var toggleState: Bool
    @State var nucleusRadius: String
    @State var positionX: String
    @State var positionY: String
    @State var positionZ: String
    @State private var needsUpdate: Bool = false

    var setValue: ((Bool) -> Bool)?
    var getValue: (() -> Bool)?
    var globalNeedsUpdate: Published<Bool>.Publisher

    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Text(parameterName)
                    .foregroundColor(needsUpdate ? .red : .primary)
                Spacer()
                Toggle("", isOn: $toggleState)
                    .onChange(of: toggleState, perform: { _ in
                        guard let setValue = setValue else { return }
                        guard let getValue = getValue else { return }
                        needsUpdate = setValue(toggleState)
                        toggleState = getValue()
                        globalRequiresRestartCheck()
                    })
                /*Button(action: {
                    // Action
                }) {
                    Image(systemName: "info.circle")
                }*/
            }
            .frame(alignment: .top)

            if toggleState {
                List {
                    TextInputParameterRow(parameterName: "Radius (nm):",
                                          fieldValue: $nucleusRadius,
                                          globalNeedsUpdate: globalNeedsUpdate)
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                    TextInputParameterRow(parameterName: "Position x (nm):",
                                          fieldValue: $positionX,
                                          globalNeedsUpdate: globalNeedsUpdate)
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                    TextInputParameterRow(parameterName: "Position y (nm):",
                                          fieldValue: $positionY,
                                          globalNeedsUpdate: globalNeedsUpdate)
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                    TextInputParameterRow(parameterName: "Position z (nm):",
                                          fieldValue: $positionZ,
                                          globalNeedsUpdate: globalNeedsUpdate)
                        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                }
                .padding(.leading, 32)
            }

        }
        .frame(minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .top)
        .onReceive(globalNeedsUpdate, perform: { _ in
            guard let setValue = setValue else { return }
            needsUpdate = setValue(toggleState)
        })
    }
}

struct NucleusParameterRow_Previews: PreviewProvider {
    static var previews: some View {
        NucleusParameterRow(parameterName: "Nucleus enabled",
                            toggleState: .constant(true),
                            nucleusRadius: "5000",
                            positionX: "6500",
                            positionY: "0.0",
                            positionZ: "0.0",
                            globalNeedsUpdate: NotSetParameters.shared.$needsRestart)
            .previewLayout(.fixed(width: 300, height: 190))
    }
}
