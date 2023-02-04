package com.dra11y.flutter.accessible_text_view

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView

class AccessibleTextViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    companion object {
        private const val TAG = "AccessibleTextViewFa..y"
    }

    override fun create(context: Context, id: Int, o: Any?): PlatformView {
        Log.e(TAG, "creating FlutterAccessibleTextView in factory!")
        return FlutterAccessibleTextView(context, messenger, id)
    }

}
