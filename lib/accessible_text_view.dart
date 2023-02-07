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
    this.textStyle,
    this.linkStyle,

    /// iOS does not follow the user's dynamic type scale setting exactly.
    /// For example, when the user's text size is 190%, the actual scaled font size
    /// is about 179% of normal size, and scaled values for UI are about 167%.
    /// At 190% on iOS, Flutter's textScale is 1.94. Setting this value to `true`
    /// (the default) will render the text on iOS at about the same size as it would be
    /// in a Flutter `Text` widget (slightly larger), while setting it to `false` will
    /// use Apple's native font scaling (slightly smaller).
    this.useFlutterTextScale = true,

    /// Defaults to `MediaQuery.of(context).textScaleFactor`
    this.flutterTextScaleFactor,
    this.backgroundColor = Colors.transparent,

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
    /// Leave as `null` to use the system theme.
    this.brightness,

    /// Callback fired when the native platform view is created.
    this.onTextViewCreated,

    /// If `true`, captures the specified gestures while allowing Flutter to
    /// pick up other gestures such as swipes for scrolling.
    this.passTapAndLongPressGesturesToNativeView = true,
  }) : super();

  final String html;
  // When `null`, these values take on the DefaultTextStyle of the build context.
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final bool useFlutterTextScale;
  final double? flutterTextScaleFactor;
  final Color backgroundColor;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool autoLinkify;
  final bool isSelectable;
  final int maxLines;
  final Brightness? brightness;
  final AccessibleTextViewCreatedCallback? onTextViewCreated;
  final bool passTapAndLongPressGesturesToNativeView;

  @override
  State<AccessibleTextView> createState() => _AccessibleTextViewState();
}

/// The persistent state of the native platform text view.
class _AccessibleTextViewState extends State<AccessibleTextView> {
  AccessibleTextViewController? controller;

  GlobalKey key = GlobalKey();

  // Must be at least 1 or view won't be created on Android.
  double wantedHeight = 1;

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

    /// If we provide a `linkStyle`, allow us to override the color/decoration/weight.
    /// Otherwise, fallback to `textStyle` or `defaultTextStyle`, but provide
    /// a different color, bold, and underline for accessibility of links.
    /// This way, we don't have to remember to provide these in `linkStyle`.
    final linkStyle =
        (widget.linkStyle ?? widget.textStyle ?? defaultTextStyle).copyWith(
      color: widget.linkStyle?.color ?? Theme.of(context).colorScheme.primary,
      decoration: widget.linkStyle?.decoration ?? TextDecoration.underline,
      fontWeight: widget.linkStyle?.fontWeight ?? FontWeight.bold,
    );

    final options = AccessibleTextViewOptions(
      html: widget.html,
      textStyle: widget.textStyle ?? defaultTextStyle,
      linkStyle: linkStyle,
      useFlutterTextScale: widget.useFlutterTextScale,
      flutterTextScaleFactor: widget.flutterTextScaleFactor ??
          MediaQuery.of(context).textScaleFactor,
      backgroundColor: widget.backgroundColor,
      autoLinkify: widget.autoLinkify,
      isSelectable: widget.isSelectable,
      maxLines: widget.maxLines,
      brightness: widget.brightness,
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

  void _wantsHeight(double? height) {
    if (height == null) return;
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

extension JsonEncodableTextDecoration on TextDecoration {
  String? toJsonString() {
    if (contains(TextDecoration.underline)) return 'underline';
    if (contains(TextDecoration.lineThrough)) return 'lineThrough';
    if (contains(TextDecoration.overline)) return 'overline';
    if (contains(TextDecoration.none)) return 'none';
    return null;
  }
}

extension JsonEncodableTextStyle on TextStyle {
  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'color': color?.argb,
      'backgroundColor': backgroundColor?.argb,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight?.value,
      'fontStyle': fontStyle?.name,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'height': height,
      'decoration': decoration?.toJsonString(),
      'decorationColor': decorationColor?.argb,
      'decorationStyle': decorationStyle?.name,
      'decorationThickness': decorationThickness,
      'overflow': overflow?.name,
    };
  }
}

/// Set the options of the native platform text view widget.
class AccessibleTextViewOptions {
  AccessibleTextViewOptions({
    this.html,
    this.textStyle,
    this.linkStyle,
    this.useFlutterTextScale,
    this.flutterTextScaleFactor,
    this.backgroundColor,
    this.autoLinkify,
    this.isSelectable,
    this.maxLines,
    this.brightness,
  });

  final String? html;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final bool? useFlutterTextScale;
  final double? flutterTextScaleFactor;
  final Color? backgroundColor;
  // When `true`, auto-linkifies URLs, e-mails, and phone numbers.
  // When `false`, does NOT remove hardcoded links in the HTML.
  final bool? autoLinkify;
  final bool? isSelectable;
  final int? maxLines;
  final Brightness? brightness;

  String toJson() => jsonEncode(toMap());

  Map<String, dynamic> toMap() {
    return {
      'html': html,
      'textStyle': textStyle?.toMap(),
      'linkStyle': linkStyle?.toMap(),
      'useFlutterTextScale': useFlutterTextScale,
      'flutterTextScaleFactor': flutterTextScaleFactor,
      'backgroundColor': backgroundColor?.argb,
      'autoLinkify': autoLinkify,
      'isSelectable': isSelectable,
      'maxLines': maxLines,
      'brightness': brightness?.name,
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
            MethodChannel('com.dra11y.flutter/accessible_text_view/$id') {
    _channel.setMethodCallHandler(onMethodCall);
  }

  final MethodChannel _channel;
  void Function(double? height)? wantsHeight;

  Future<void> onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'wantsHeight':
        wantsHeight?.call(double.tryParse(call.arguments.toString()));
        break;
      default:
        break;
    }
  }

  Future<void> setOptions(AccessibleTextViewOptions options) async {
    return await _channel.invokeMethod('setOptions', options.toJson());
  }
}
