import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A callback fired when the native platform text view is created.
typedef AccessibleTextViewCreatedCallback = void Function(
    AccessibleTextViewController controller);

/// Renders a native text view platform widget.
class AccessibleTextView extends StatefulWidget {
  const AccessibleTextView({
    super.key,

    /// Only accepts very simple HTML, such as links, boldface, and paragraph
    /// marks. More complex things such as image tags will not work.
    required this.html,
    this.textColor,
    this.textWeight,
    this.linkColor,
    this.linkWeight,
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
    this.appearance = AccessibleTextViewAppearance.system,

    /// Callback fired when the native platform view is created.
    this.onTextViewCreated,

    /// If `true`, captures the specified gestures while allowing Flutter to
    /// pick up other gestures such as swipes for scrolling.
    this.passTapAndLongPressGesturesToNativeView = true,
  }) : super();

  final String html;
  // When `null`, these values take on the DefaultTextStyle of the build context.
  final Color? textColor;
  final FontWeight? textWeight;
  final Color? linkColor;
  final FontWeight? linkWeight;
  final Color? backgroundColor;
  final String? fontFamily;
  final double? fontSize;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool autoLinkify;
  final bool isSelectable;
  final int maxLines;
  final AccessibleTextViewAppearance appearance;
  final AccessibleTextViewCreatedCallback? onTextViewCreated;
  final bool passTapAndLongPressGesturesToNativeView;

  @override
  State<AccessibleTextView> createState() => _AccessibleTextViewState();
}

/// The persistent state of the native platform text view.
class _AccessibleTextViewState extends State<AccessibleTextView> {
  AccessibleTextViewController? controller;

  GlobalKey key = GlobalKey();

  double wantedHeight = 0;

  Widget buildPlatformWidget(
      BuildContext context, AccessibleTextViewOptions options) {
    final gestureRecognizers = widget.passTapAndLongPressGesturesToNativeView
        ? <Factory<OneSequenceGestureRecognizer>>{
            Factory<TapGestureRecognizer>(
              () => TapGestureRecognizer(),
            ),
            Factory<LongPressGestureRecognizer>(
              () => LongPressGestureRecognizer(),
            ),
          }
        : null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        key: key,
        viewType: 'com.dra11y.flutter/accessible_text_view',
        onPlatformViewCreated: (id) => _onPlatformViewCreated(id, options),
        gestureRecognizers: gestureRecognizers,
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        key: key,
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
    final options = AccessibleTextViewOptions(
      html: widget.html,
      textColor: widget.textColor ?? defaultTextStyle.color,
      textWeight: widget.textWeight ?? FontWeight.normal,
      linkColor: widget.linkColor ?? Theme.of(context).colorScheme.primary,
      linkWeight: widget.linkWeight ?? FontWeight.bold,
      backgroundColor: widget.backgroundColor ?? Colors.transparent,
      fontFamily: widget.fontFamily ?? defaultTextStyle.fontFamily,
      fontSize: widget.fontSize ?? defaultTextStyle.fontSize,
      autoLinkify: widget.autoLinkify,
      isSelectable: widget.isSelectable,
      maxLines: widget.maxLines,
      appearance: widget.appearance,
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

  void _onPlatformViewCreated(int id, AccessibleTextViewOptions options) {
    final controller = AccessibleTextViewController._(id);
    controller.setOptions(options);
    controller.wantsHeight = _wantsHeight;
    this.controller = controller;
    widget.onTextViewCreated?.call(controller);
  }
}

/// Used to override the appearance of the native platform text view on iOS.
enum AccessibleTextViewAppearance {
  light,
  dark,
  system,
}

/// Set the options of the native platform text view widget.
class AccessibleTextViewOptions {
  AccessibleTextViewOptions({
    this.html,
    this.textColor,
    this.textWeight,
    this.linkColor,
    this.linkWeight,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,
    this.autoLinkify,
    this.isSelectable,
    this.maxLines,
    this.appearance,
  });

  final String? html;
  final Color? textColor;
  final FontWeight? textWeight;
  final Color? linkColor;
  final FontWeight? linkWeight;
  final Color? backgroundColor;
  final String? fontFamily;
  final double? fontSize;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool? autoLinkify;
  final bool? isSelectable;
  final int? maxLines;
  final AccessibleTextViewAppearance? appearance;

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return {
      'html': html,
      'textColor': textColor?.argb,
      'textWeight': textWeight?.value,
      'linkColor': linkColor?.argb,
      'linkWeight': linkWeight?.value,
      'backgroundColor': backgroundColor?.argb,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'autoLinkify': autoLinkify,
      'isSelectable': isSelectable,
      'maxLines': maxLines,
      'appearance': appearance?.name,
    };
  }
}

extension ColorExtension on Color {
  /// Convert a color to JSON-encodable format for the API.
  List<int> get argb => [alpha, red, green, blue];
}

/// A controller for the native platform text view to facilitate communication with Flutter.
class AccessibleTextViewController {
  AccessibleTextViewController._(int id)
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

  Future<void> setOptions(AccessibleTextViewOptions options) async {
    return await _channel.invokeMethod('setOptions', options.toJson());
  }
}
