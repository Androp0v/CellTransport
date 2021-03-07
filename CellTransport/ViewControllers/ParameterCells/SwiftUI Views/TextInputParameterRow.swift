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

    var setValue: ((String) -> Bool)?
    var getValue: (() -> String)?

    var body: some View {
        HStack(spacing: 8) {
            Text(parameterName)
                .foregroundColor(needsUpdate ? .red : .primary)
            Spacer()
            TextField("Parameter",
                      text: $fieldValue,
                      onEditingChanged: { _ in },
                      onCommit: {
                        guard let setValue = setValue else { return }
                        guard let getValue = getValue else { return }
                        needsUpdate = setValue(fieldValue)
                        fieldValue = getValue()
                        checkForGlobalRestartCheck()
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
        }
        .frame(minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .topLeading)
    }
}

struct TextInputParameterRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TextInputParameterRow(parameterName: "Parameter name:",
                                  fieldValue: .constant("0.0"),
                                  setValue: setWON)
                .previewLayout(.fixed(width: 300, height: 40))
        }
    }
}
