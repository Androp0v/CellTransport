//
//  PickerParameterRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 7/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct PickerParameterRow: View {

    @State var parameterName: String
    @Binding var selectedParameter: Int32
    @State var pickerOptions: [String]

    @State private var needsUpdate: Bool = false

    var setValue: ((Int32) -> Bool)?
    var getValue: (() -> Int32)?

    var body: some View {
        HStack {
            Text("\(parameterName):")
                .foregroundColor(needsUpdate ? .red : .primary)
            Spacer()
            Picker(selection: $selectedParameter,
                   label: UIDevice.current.userInterfaceIdiom == .mac
                    ? Text("")
                    : Text("\(pickerOptions[Int(selectedParameter)])")
            ) {
                ForEach(0 ..< pickerOptions.count) { index in
                    // SwiftUI detects selection by tag
                    Text(self.pickerOptions[index]).tag(Int32(index))
                }
            }
            .onChange(of: selectedParameter, perform: { _ in
                guard let setValue = setValue else { return }
                guard let getValue = getValue else { return }
                needsUpdate = setValue(selectedParameter)
                selectedParameter = getValue()
                checkForGlobalRestartCheck()
            })
            .pickerStyle(MenuPickerStyle())
       }
    }
}

struct PickerParameterRow_Previews: PreviewProvider {
    static var previews: some View {
        PickerParameterRow(parameterName: "Pickable parameter",
                           selectedParameter: .constant(0),
                           pickerOptions: ["Option 1",
                                           "Option 2",
                                           "Option 3"]
        )
        .previewLayout(.fixed(width: 300, height: 40))
    }
}
