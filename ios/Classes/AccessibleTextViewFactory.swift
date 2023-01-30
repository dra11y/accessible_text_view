//
//  AccessibleTextViewFactory.swift
//  accessible_text_view
//
//  Created by Grushka, Tom on 1/20/23.
//

import Flutter

public class AccessibleTextViewFactory: NSObject, FlutterPlatformViewFactory {
    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        TextView(withFrame: frame, viewId: viewId, messenger: messenger, arguments: args)
    }

    private let messenger: FlutterBinaryMessenger
}
