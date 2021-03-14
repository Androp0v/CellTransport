//
//  ParameterSectionTitleRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 6/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct ParameterSectionTitleRow: View {

    @State var sectionTitle: String

    var body: some View {
        HStack(spacing: 8) {
            Text(sectionTitle)
                .font(.system(.headline, design: .default))
            Spacer()
        }
        .frame(height: 40, alignment: .bottom)
    }
}

struct ParameterSectionTitleRow_Previews: PreviewProvider {
    static var previews: some View {
        ParameterSectionTitleRow(sectionTitle: "Parameter section")
            .previewLayout(.fixed(width: 300, height: 40))
    }
}
