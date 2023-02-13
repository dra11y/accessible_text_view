//
//  AccessibleTextViewFactory.swift
//  accessible_text_view
//
//  Created by Grushka, Tom on 12-Feb-23.
//

import FlutterMacOS

public class AccessibleTextViewFactory: NSObject, FlutterPlatformViewFactory {
    public func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let textView = TextView()
        textView.setup(viewId: viewId, messenger: messenger)
        return textView
    }

    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    private let messenger: FlutterBinaryMessenger
}
