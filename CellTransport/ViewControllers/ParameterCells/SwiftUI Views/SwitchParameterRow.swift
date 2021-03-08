//
//  SwitchParameterRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 7/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct SwitchParameterRow: View {

    @State var parameterName: String
    @Binding var fieldValue: Bool
    @State private var needsUpdate: Bool = false

    var setValue: ((Bool) -> Bool)?
    var getValue: (() -> Bool)?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(parameterName)
                .foregroundColor(needsUpdate ? .red : .primary)
            Spacer()
            Toggle("", isOn: $fieldValue)
                .onChange(of: fieldValue, perform: { _ in
                    guard let setValue = setValue else { return }
                    guard let getValue = getValue else { return }
                    needsUpdate = setValue(fieldValue)
                    fieldValue = getValue()
                    globalRequiresRestartCheck()
                })
            /*Button(action: {
                // Action
            }) {
                Image(systemName: "info.circle")
            }*/
        }
        .frame(minWidth: 0,
                maxWidth: .infinity,
                minHeight: 0,
                maxHeight: .infinity,
                alignment: .center)
    }
}

struct SwitchParameterRow_Previews: PreviewProvider {
    static var previews: some View {
        SwitchParameterRow(parameterName: "Switch parameter",
                           fieldValue: .constant(true))
            .previewLayout(.fixed(width: 300, height: 40))
    }
}
