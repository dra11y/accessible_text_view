import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A callback fired when the native platform text view is created.
typedef NativeTextViewCreatedCallback = void Function(
    NativeTextViewController controller);

/// The accessibility behavior (currently iOS only) of the native text view.
enum NativeTextViewBehavior {
  /// Use the default accessibility behavior of the platform.
  /// On iOS, this has limitations when more than one link is embedded in the text view.
  /// One in particular is lack of Switch Control access to links using Apple's default behavior.
  platformDefault,

  /// Augments Apple's default accessibility behavior in two ways:
  /// 1. Adds a long-press context menu popup with all of the links (like Android);
  /// 2. Make all links available and focusable with Switch Control on iOS.
  platformDefaultPlusLinksLongPressMenu,

  /// Overrides Apple's default accessibility behavior, and makes all non-link and
  /// link nodes separately focusable, similar to Safari. This works with both
  /// VoiceOver and Switch Control.
  linksAsFocusNodes,
}

/// Renders a native text view platform widget.
class NativeTextView extends StatefulWidget {
  const NativeTextView({
    super.key,

    /// Only accepts very simple HTML, such as links, boldface, and paragraph
    /// marks. More complex things such as image tags will not work.
    required this.html,
    this.textColor,
    this.linkColor,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,

    /// Uses data detection (Android and iOS) to auto-detect links that aren't explicitly
    /// added in the HTML, such as phone numbers and e-mail addresses.
    /// This doesn't seem to be 100% reliable on iOS.
    this.autoLinkify = true,

    /// If `true`, makes the text selectable, which can make the VoiceOver user experience
    /// a bit more complicated.
    this.isSelectable = false,
    this.maxLines = 0,

    /// Override dark or light mode. On iOS, this is currently the only way to prevent
    /// the long-press menu from a very annoying color invert if your app's theme does not
    /// follow the system theme.
    this.appearance = NativeTextViewAppearance.system,

    /// See the `NativeTextViewBehavior` enum for more info.
    this.accessibilityBehaviorIOS =
        NativeTextViewBehavior.platformDefaultPlusLinksLongPressMenu,

    /// Callback fired when the native platform view is created.
    this.onTextViewCreated,

    /// If `true`, captures the specified gestures while allowing Flutter to
    /// pick up other gestures such as swipes for scrolling.
    this.passTapAndLongPressGesturesToNativeView = true,
  }) : super();

  final String html;
  // When `null`, these values take on the DefaultTextStyle of the build context.
  final Color? textColor;
  final Color? linkColor;
  final Color? backgroundColor;
  final String? fontFamily;
  final double? fontSize;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool autoLinkify;
  final bool isSelectable;
  final int maxLines;
  final NativeTextViewAppearance appearance;
  final NativeTextViewBehavior accessibilityBehaviorIOS;
  final NativeTextViewCreatedCallback? onTextViewCreated;
  final bool passTapAndLongPressGesturesToNativeView;

  @override
  State<NativeTextView> createState() => _NativeTextViewState();
}

/// The persistent state of the native platform text view.
class _NativeTextViewState extends State<NativeTextView> {
  NativeTextViewController? controller;

  double wantedHeight = 0;

  Widget buildPlatformWidget(
      BuildContext context, NativeAccessibleTextViewOptions options) {
    final gestureRecognizers = widget.passTapAndLongPressGesturesToNativeView
        ? <Factory<OneSequenceGestureRecognizer>>{
            Factory<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
            ),
            Factory<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
            ),
            Factory<EagerGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          }
        : null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'com.dra11y.flutter/accessible_text_view',
        onPlatformViewCreated: (id) => _onPlatformViewCreated(id, options),
        gestureRecognizers: gestureRecognizers,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: 'com.dra11y.flutter/accessible_text_view',
        gestureRecognizers: gestureRecognizers,
        onPlatformViewCreated: (id) => _onPlatformViewCreated(id, options),
      );
    }
    return Text(
        '$defaultTargetPlatform is not yet supported by the accessible_text_view plugin');
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final colorScheme = Theme.of(context).colorScheme;
    final options = NativeAccessibleTextViewOptions(
      html: widget.html,
      textColor: widget.textColor ?? defaultTextStyle.color,
      linkColor: widget.linkColor ?? defaultTextStyle.decorationColor,
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      fontFamily: widget.fontFamily ?? defaultTextStyle.fontFamily,
      fontSize: widget.fontSize ?? defaultTextStyle.fontSize,
      autoLinkify: widget.autoLinkify,
      isSelectable: widget.isSelectable,
      maxLines: widget.maxLines,
      appearance: widget.appearance,
      accessibilityBehaviorIOS: widget.accessibilityBehaviorIOS,
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: wantedHeight,
        child: buildPlatformWidget(context, options),
      ),
    );
  }

  void _wantsHeight(double height) {
    if (height != wantedHeight) {
      setState(() {
        wantedHeight = height;
      });
    }
  }

  void _onPlatformViewCreated(int id, NativeAccessibleTextViewOptions options) {
    final controller = NativeTextViewController._(id);
    controller.setOptions(options);
    controller.wantsHeight = _wantsHeight;
    this.controller = controller;
    widget.onTextViewCreated?.call(controller);
  }
}

/// Used to override the appearance of the native platform text view on iOS.
enum NativeTextViewAppearance {
  light,
  dark,
  system,
}

/// Set the options of the native platform text view widget.
class NativeAccessibleTextViewOptions {
  NativeAccessibleTextViewOptions({
    this.html,
    this.textColor,
    this.linkColor,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,
    this.autoLinkify,
    this.isSelectable,
    this.maxLines,
    this.appearance,
    this.accessibilityBehaviorIOS,
  });

  final String? html;
  final Color? textColor;
  final Color? linkColor;
  final Color? backgroundColor;
  final String? fontFamily;
  final double? fontSize;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool? autoLinkify;
  final bool? isSelectable;
  final int? maxLines;
  final NativeTextViewAppearance? appearance;
  final NativeTextViewBehavior? accessibilityBehaviorIOS;

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return {
      'html': html,
      'textColor': textColor?.argb,
      'linkColor': linkColor?.argb,
      'backgroundColor': backgroundColor?.argb,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'autoLinkify': autoLinkify,
      'isSelectable': isSelectable,
      'maxLines': maxLines,
      'appearance': appearance?.name,
      if (isIOS) 'accessibilityBehavior': accessibilityBehaviorIOS?.name,
    };
  }
}

extension ColorExtension on Color {
  /// Convert a color to JSON-encodable format for the API.
  List<int> get argb => [alpha, red, green, blue];
}

/// A controller for the native platform text view to facilitate communication with Flutter.
class NativeTextViewController {
  NativeTextViewController._(int id)
      : _channel =
            MethodChannel('com.dra11y.flutter/accessible_text_view_$id') {
    _channel.setMethodCallHandler(onMethodCall);
  }

  final MethodChannel _channel;
  void Function(double height)? wantsHeight;

  Future<void> onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'wantsHeight':
        wantsHeight?.call(call.arguments as double);
        break;
      default:
        break;
    }
  }

  Future<void> setOptions(NativeAccessibleTextViewOptions options) async {
    return await _channel.invokeMethod('setOptions', options.toJson());
  }
}
