//
//  PickerParameterTableViewCell.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 28/2/21.
//  Copyright © 2021 Raúl Montón Pinillos. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

class ObservablePicker: ObservableObject {
    // @Published object to share values to SwiftUI view
    @Published public var value: Int = 0
}

class PickerParameterTableViewCell<Content: View>: BaseParameterTableViewCell {

    private weak var controller: UIHostingController<Content>?
    public var pickerSwiftUIView: PickerAndDropDownView?

    /// Picker changes passed by SwiftUI subview
    var pickerUpdated: (String) -> Bool = { _ in return false}

    // Combine-related: @Published object to share values to SwiftUI view
    private var observablePicker = ObservablePicker()
    private var cancellables: Set<AnyCancellable> = []

    override func fetchParameterValue() {
        // Update swiftUI value
        guard let value = valueGetter?() else { return }
        guard let valuePosition = Int(value) else { return }
        observablePicker.value = valuePosition
    }

    /// Create a UIHostingController to host a SwiftUI view.
    /// The only way to have a dropdown menu on pure Mac Catalyst (without messing around with AppKit) is to
    /// create a SwiftUI view with a Picker (which will be automatically converted to a dropdown menu if using the
    /// .mac idiom). Since the app uses storyboards, the workaround is to host a SwiftUI view inside the contentView
    /// of the UITableViewCell which stores the Picker.
    /// - Parameters:
    ///   - pickerView: Picker SwiftUI view to host
    ///   - parent: Parent ViewController
    func host(_ pickerView: Content, parent: UIViewController) {

        // Store picker view as a property in the container class
        pickerSwiftUIView = pickerView as? PickerAndDropDownView

        if let controller = controller {
            controller.rootView = pickerView
            controller.view.layoutIfNeeded()

            pickerSwiftUIView?.onPickerChange = pickerUpdated

            // This is where values of SwiftUI view and UIKit get glued together
            self.observablePicker.$value.assign(to: \.selectedOption.value,
                                                on: pickerSwiftUIView!)
                .store(in: &self.cancellables)
            
        } else {
            let swiftUICellViewController = UIHostingController(rootView: pickerView)
            controller = swiftUICellViewController
            swiftUICellViewController.view.backgroundColor = .clear

            layoutIfNeeded()

            parent.addChild(swiftUICellViewController)
            contentView.addSubview(swiftUICellViewController.view)
            swiftUICellViewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!,
                                                         attribute: NSLayoutConstraint.Attribute.leading,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.leading,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!,
                                                         attribute: NSLayoutConstraint.Attribute.trailing,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.trailing,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!,
                                                         attribute: NSLayoutConstraint.Attribute.top,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.top,
                                                         multiplier: 1.0,
                                                         constant: 0.0))
            contentView.addConstraint(NSLayoutConstraint(item: swiftUICellViewController.view!,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         relatedBy: NSLayoutConstraint.Relation.equal,
                                                         toItem: contentView,
                                                         attribute: NSLayoutConstraint.Attribute.bottom,
                                                         multiplier: 1.0,
                                                         constant: 0.0))

            swiftUICellViewController.didMove(toParent: parent)
            swiftUICellViewController.view.layoutIfNeeded()

            pickerSwiftUIView?.onPickerChange = pickerUpdated

            // This is where values of SwiftUI view and UIKit get glued together
            self.observablePicker.$value.assign(to: \.selectedOption.value,
                                                on: pickerSwiftUIView!)
                .store(in: &self.cancellables)
        
        }
    }
}
