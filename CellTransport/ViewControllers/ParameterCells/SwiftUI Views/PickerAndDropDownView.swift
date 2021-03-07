//
//  PickerAndDropDownView.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct PickerAndDropDownView: View {

    var titleLabel: String
    var pickerOptions: [String]
    var setter: ((String) -> Bool)?
    var onPickerChange: ((String) -> Bool)
    @ObservedObject var selectedOption: ObservablePicker = ObservablePicker()
    @State var pickerColor: UIColor = .label
    
    var body: some View {
        Picker(selection: $selectedOption.value,
               label: Text(titleLabel)) {
                    ForEach(0 ..< pickerOptions.count) {
                       Text(self.pickerOptions[$0])
                    }
                 }
        .pickerStyle(DefaultPickerStyle())
        .padding(.leading, 15)
        .padding(.trailing, 12)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .foregroundColor(Color(pickerColor))
        .onChange(of: selectedOption.value, perform: { value in
            // Set value, ignore return since pickers can't fail
            _ = setter?(String(value))
            let needsRestart = onPickerChange(String(selectedOption.value))
            if needsRestart {
                pickerColor = .systemRed
            } else {
                pickerColor = .label
            }
        })
        .onAppear(perform: {
            let needsRestart = onPickerChange(String(selectedOption.value))
            if needsRestart {
                pickerColor = .systemRed
            } else {
                pickerColor = .label
            }
        })
    }

}

struct PickerAndDropDownView_Previews: PreviewProvider {
    static var previews: some View {
        PickerAndDropDownView(titleLabel: "Molecular motor:",
                              pickerOptions: ["Kinesins", "Dyneins"],
                              onPickerChange: {_ in return false}
        )
    }
}
