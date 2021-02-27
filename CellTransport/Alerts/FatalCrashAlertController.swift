//
//  FatalCrashAlertController.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 19/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit

class FatalCrashAlertController: UIAlertController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let closeAppAction = UIAlertAction(title: "OK",
                                           style: .default,
                                           handler: nil)
        self.addAction(closeAppAction)
    }

}
