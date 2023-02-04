package com.dra11y.flutter.accessible_text_view

import android.content.Context
import android.content.res.Configuration
import android.graphics.Typeface
import android.text.Spannable
import android.text.method.LinkMovementMethod
import android.util.Log
import android.view.View
import android.view.View.IMPORTANT_FOR_ACCESSIBILITY_YES
import android.widget.TextView
import androidx.core.text.HtmlCompat
import androidx.core.text.HtmlCompat.FROM_HTML_MODE_LEGACY
import com.dra11y.flutter.native_flutter_fonts.FlutterFontRegistry
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

class FlutterAccessibleTextView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
) : PlatformView, MethodCallHandler {
    private val textView: TextView
    private val methodChannel: MethodChannel
    private var html: String = ""
    private var autoLinkify: Boolean = true
    private var textTypeface: Typeface? = null
    private var linkTypeface: Typeface? = null
    private var options: AccessibleTextViewOptions? = null

    companion object {
        private const val TAG = "Fl..rAccessibleTextView"
    }

    init {
        textView = object : TextView(context) {
            override fun onConfigurationChanged(newConfig: Configuration?) {
                super.onConfigurationChanged(newConfig)
                Log.d(TAG, "onConfigurationChanged $newConfig")
                refreshOptions()
            }
        }
        methodChannel = MethodChannel(messenger, "com.dra11y.flutter/accessible_text_view_$id")
        methodChannel.setMethodCallHandler(this)
        textView.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            // Add one extra line "leading" as padding to the height of the text view.
            val unscaledHeight = textView.textSize * textView.lineCount + textView.paint.fontMetrics.leading
            // Divide by the density, rather than the scaledDensity, as Flutter doesn't care about the scale.
            // Otherwise, scaledDensity gets applied twice, and the calculated height is too tall.
            val wantedHeight = unscaledHeight / textView.paint.density
            wantsHeight(wantedHeight)
        }
    }

    // This function is called several times every time TalkBack focus changes.
    override fun getView(): View {
        // For TalkBack to see our text at all, this needs to be set here each time it is called, not on init.
        textView.importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
        return textView
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setOptions" -> setOptions(call, result)
            else -> result.notImplemented()
        }
    }

    private fun wantsHeight(wantedHeight: Float) {
        Log.d(TAG, "wantsHeight: $wantedHeight")
        methodChannel.invokeMethod("wantsHeight", wantedHeight)
    }

    private fun refreshOptions(): Boolean {
        val options = options ?: return false
        Log.d(TAG, "refreshOptions $options")
        var needsUpdate = false
        options.html?.let {
            html = it
            needsUpdate = true
        }
        options.autoLinkify?.let {
            autoLinkify = it
            needsUpdate = true
        }
        options.textColor?.let { textView.setTextColor(it.toColor()) }
        options.linkColor?.let { textView.setLinkTextColor(it.toColor()) }
        val textWeight = options.textWeight ?: 400
        val textIsItalic = options.textIsItalic ?: false
        val linkWeight = options.linkWeight ?: 700
        val linkIsItalic = options.linkIsItalic ?: false
        options.fontFamily?.let {
            textTypeface = FlutterFontRegistry.resolve(it, weight = textWeight, isItalic = textIsItalic)
            needsUpdate = true
        }
        options.fontFamily?.let {
            linkTypeface = FlutterFontRegistry.resolve(it, weight = linkWeight, isItalic = linkIsItalic)
            needsUpdate = true
        }
        textView.typeface = textTypeface ?: Typeface.DEFAULT
        options.fontSize?.let { textView.textSize = it }
        options.isSelectable?.let { textView.setTextIsSelectable(it) }
        options.maxLines?.let { textView.maxLines = if (it < 1) Int.MAX_VALUE else it }
        if (needsUpdate) update()
        return true
    }

    private fun setOptions(methodCall: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "setOptions")
        options = Json.decodeFromString<AccessibleTextViewOptions>(methodCall.arguments as String)
        if (refreshOptions()) result.success(null)
        else result.error("setOptions", "Could not set options.", null)
    }

    private fun update() {
        Log.d(TAG, "update")

        val htmlSpannable = HtmlCompat.fromHtml(html, FROM_HTML_MODE_LEGACY) as Spannable

        val linkTypeface = linkTypeface ?: Typeface.DEFAULT_BOLD

        if (autoLinkify) {
            htmlSpannable.autoLinkify()
        }

        // Format spans with bold and sort them in order for TalkBack.
        htmlSpannable.formatSpans(linkTypeface)

        textView.linksClickable = true
        textView.movementMethod = LinkMovementMethod.getInstance()
        textView.text = htmlSpannable
    }

    override fun dispose() {}
}
