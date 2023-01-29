import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef NativeTextViewCreatedCallback = void Function(
    NativeTextViewController controller);

enum NativeTextViewBehavior {
  platformDefault,
  platformDefaultPlusLinksLongPressMenu,
  linksAsFocusNodes,
}

class NativeTextView extends StatefulWidget {
  const NativeTextView({
    super.key,
    required this.html,
    this.textColor,
    this.linkColor,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,
    this.autoLinkify = true,
    this.isSelectable = false,
    this.maxLines = 0,
    this.appearance = NativeTextViewAppearance.system,
    this.accessibilityBehaviorIOS =
        NativeTextViewBehavior.platformDefaultPlusLinksLongPressMenu,
    this.onTextViewCreated,
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

enum NativeTextViewAppearance {
  light,
  dark,
  system,
}

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
  List<int> get argb => [alpha, red, green, blue];
}

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
