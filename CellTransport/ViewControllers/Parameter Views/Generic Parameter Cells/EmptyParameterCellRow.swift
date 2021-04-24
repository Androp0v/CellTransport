//
//  EmptyParameterCellRow.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 6/3/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import SwiftUI

struct EmptyParameterCellRow: View {
    var body: some View {
        Spacer()
            .frame(minWidth: 0,
                   idealWidth: .infinity,
                   maxWidth: .infinity,
                   minHeight: 97.5,
                   idealHeight: 97.5,
                   maxHeight: 97.5,
                   alignment: .center)
    }
}

struct EmptyParameterCell_Previews: PreviewProvider {
    static var previews: some View {
        EmptyParameterCellRow()
    }
}
