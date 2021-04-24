//
//  TextInputParameterRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 6/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct TextInputParameterRow: View {

    @State var parameterName: String
    @Binding var fieldValue: String
    @State private var needsUpdate: Bool = false
    @State var showPopover: Bool = false

    var setValue: ((String) -> Bool)?
    var getValue: (() -> String)?
    var globalNeedsUpdate: Published<Bool>.Publisher

    var body: some View {
        HStack(spacing: 4) {
            Text(parameterName)
                .foregroundColor(needsUpdate ? .red : .primary)
            Spacer()
            TextField("",
                      text: $fieldValue,
                      onEditingChanged: { _ in },
                      onCommit: {
                        guard let setValue = setValue else { return }
                        guard let getValue = getValue else { return }
                        needsUpdate = setValue(fieldValue)
                        fieldValue = getValue()
                        globalRequiresRestartCheck()
                      })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(needsUpdate ? .red : .primary)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 0,
                       idealWidth: 80,
                       maxWidth: 80,
                       minHeight: 0,
                       idealHeight: 20,
                       maxHeight: .infinity,
                       alignment: .trailing)
            /*Button(action: {
                        // Action
                        showPopover = true
                    },
                    label: {
                        Image(systemName: "info.circle")
                    })
            .popover(isPresented: self.$showPopover, content: {
                Text("Popover!")
            })*/
        }
        .frame(minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading)
        .onReceive(globalNeedsUpdate, perform: { _ in
            guard let setValue = setValue else { return }
            needsUpdate = setValue(fieldValue)
        })
    }
}

struct TextInputParameterRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let notSetParameters = NotSetParameters.shared
            TextInputParameterRow(parameterName: "Parameter name:",
                                  fieldValue: .constant("0.0"),
                                  setValue: setWON,
                                  globalNeedsUpdate: notSetParameters.$needsRestart)
                .previewLayout(.fixed(width: 300, height: 40))
        }
    }
}
