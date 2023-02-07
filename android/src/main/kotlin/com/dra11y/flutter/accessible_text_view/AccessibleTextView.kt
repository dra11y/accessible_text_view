package com.dra11y.flutter.accessible_text_view

import android.content.Context
import android.content.res.Configuration
import android.graphics.Typeface
import android.os.Build
import android.text.Spannable
import android.text.method.LinkMovementMethod
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.view.View.IMPORTANT_FOR_ACCESSIBILITY_YES
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import androidx.core.text.HtmlCompat
import androidx.core.text.HtmlCompat.FROM_HTML_MODE_LEGACY
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import kotlin.math.roundToInt
import kotlin.reflect.typeOf

class AccessibleTextView(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val id: Int,
) : PlatformView, MethodCallHandler {
    private val textView: TextView
    private val methodChannel: MethodChannel
    private var html: String = ""
    private var autoLinkify: Boolean = true
    private var textTypeface: Typeface? = null
    private var textStyle: AccessibleTextViewOptions.TextStyle? = null
    private var linkStyle: AccessibleTextViewOptions.TextStyle? = null
    private var options: AccessibleTextViewOptions? = null

    companion object {
        private const val TAG = "AccessibleTextView"
    }

    init {
        textView = object : TextView(context) {
            override fun onConfigurationChanged(newConfig: Configuration?) {
                super.onConfigurationChanged(newConfig)
                Log.d(TAG, "onConfigurationChanged $newConfig")
                refreshOptions()
            }
        }
        methodChannel = MethodChannel(messenger, "com.dra11y.flutter/accessible_text_view/$id")
        methodChannel.setMethodCallHandler(this)
        textView.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            computeLinePixelHeight()?.let { pixelHeight ->
                wantsHeight(pixelHeight * textView.lineCount)
            }
        }
    }

    fun getFontSize(): Float = textStyle?.fontSize ?: run {
        val textAppearance = TypedValue()
        context.theme.resolveAttribute(android.R.attr.textAppearance, textAppearance, true)
        val textAppearanceStyle = context.obtainStyledAttributes(textAppearance.data, intArrayOf(android.R.attr.textSize))
        val textSize = textAppearanceStyle.getDimension(0, 0f)
        textAppearanceStyle.recycle()
        textSize / context.resources.displayMetrics.scaledDensity
    }

    fun computeLinePixelHeight(): Float? = with(context.resources.displayMetrics) {
        textStyle?.height?.let { height ->
            height * getFontSize() * scaledDensity / density
        }
    }
//            (it.height ?: 1.0f) *
//            (it.fontSize ?: (textSize / paint.density)) * paint.density
//        }

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
        Log.e(TAG, "refreshOptions $options")
        var needsUpdate = false
        options.html?.let {
            html = it
            needsUpdate = true
        }
        options.autoLinkify?.let {
            autoLinkify = it
            needsUpdate = true
        }

        options.textStyle?.let { textStyle ->
            textStyle.color?.let { textView.setTextColor(it.toColor()) }
            this.textStyle = textStyle
            textTypeface = textStyle.resolveTypeface()
            val fontSize = getFontSize()
            println("textStyle.fontSize = $fontSize")
            println("textStyle.height = ${textStyle.height}")
            textView.textSize = fontSize
            textStyle.height?.let { height ->
                /// lineSpacing on Android is only the extra spacing, not including the font height itself.
                val lineSpacing = (height - 1.0f) * fontSize * context.resources.displayMetrics.scaledDensity
                println("lineSpacing = $lineSpacing")
                textView.setLineSpacing(lineSpacing, 1f)
            }
            needsUpdate = true
        }

        options.linkStyle?.let { linkStyle ->
            linkStyle.color?.let { textView.setLinkTextColor(it.toColor()) }
            this.linkStyle = linkStyle
            needsUpdate = true
        }

        textView.typeface = textTypeface ?: Typeface.DEFAULT
        options.isSelectable?.let { textView.setTextIsSelectable(it) }

        // Android doesn't support 0 maxLines, therefore, when 0, set it to "infinity."
        options.maxLines?.let { textView.maxLines = if (it < 1) Int.MAX_VALUE else it }

        if (needsUpdate) update()
        return true
    }

    private fun setOptions(methodCall: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "setOptions")
        val json = Json { ignoreUnknownKeys = true }
        options = json.decodeFromString<AccessibleTextViewOptions>(methodCall.arguments as String)
        if (refreshOptions()) result.success(null)
        else result.error("setOptions", "Could not set options.", null)
    }

    private fun update() {
        Log.d(TAG, "update")

        val htmlSpannable = HtmlCompat.fromHtml(html, FROM_HTML_MODE_LEGACY) as Spannable

        if (autoLinkify) {
            htmlSpannable.autoLinkify()
        }

        // Format spans with bold and sort them in order for TalkBack.
        htmlSpannable.formatSpans(linkStyle)

        textView.linksClickable = true
        textView.movementMethod = LinkMovementMethod.getInstance()
        textView.text = htmlSpannable
    }

    override fun dispose() {}
}
