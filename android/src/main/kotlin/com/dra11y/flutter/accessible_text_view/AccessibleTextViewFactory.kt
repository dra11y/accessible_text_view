package com.dra11y.flutter.accessible_text_view

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView

class AccessibleTextViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, o: Any?): PlatformView =
        FlutterAccessibleTextView(context, messenger, id)

}
