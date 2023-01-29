package com.dra11y.flutter.accessible_text_view

import android.content.Context
import android.text.Spannable
import android.text.SpannableString
import android.text.method.LinkMovementMethod
import android.text.style.URLSpan
import android.text.util.Linkify
import android.view.View
import android.view.View.IMPORTANT_FOR_ACCESSIBILITY_YES
import android.widget.TextView
import androidx.core.text.HtmlCompat
import androidx.core.text.HtmlCompat.FROM_HTML_MODE_COMPACT
import androidx.core.text.HtmlCompat.FROM_HTML_MODE_LEGACY
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

    init {
        textView = TextView(context)
        methodChannel = MethodChannel(messenger, "com.dra11y.flutter/accessible_text_view_$id")
        methodChannel.setMethodCallHandler(this)
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

    private fun setOptions(methodCall: MethodCall, result: MethodChannel.Result) {
        val options = Json.decodeFromString<AccessibleTextViewOptions>(methodCall.arguments as String)
        var needsUpdate = false
        options.html?.let {
            html = it
            needsUpdate = true
        }
        options.autoLinkify?.let {
            autoLinkify = it
            needsUpdate = true
        }
        options.textColor?.let {
            println("raw color = ${it}")
            textView.setTextColor(it.toColor())
        }
        options.linkColor?.let { textView.setLinkTextColor(it.toColor()) }
        options.fontFamily?.let { textView.typeface = FontRegistry.resolve(it) }
        options.fontSize?.let { textView.textSize = it }
        options.isSelectable?.let { textView.setTextIsSelectable(it) }
        options.maxLines?.let { textView.maxLines = if (it < 1) Int.MAX_VALUE else it }
        if (needsUpdate) update()
        result.success(null)
    }

    private fun update() {
        val htmlSpannable = HtmlCompat.fromHtml(html, FROM_HTML_MODE_LEGACY) as Spannable
        val htmlSpans = htmlSpannable.getSpans(0, htmlSpannable.length, URLSpan::class.java)
        val combinedSpannable = SpannableString(htmlSpannable)

        // Auto-linkify phone numbers and e-mails.
        if (autoLinkify) {
            Linkify.addLinks(combinedSpannable, Linkify.ALL)
            for (span: URLSpan in htmlSpans) {
                combinedSpannable.setSpan(
                    span,
                    htmlSpannable.getSpanStart(span),
                    htmlSpannable.getSpanEnd(span),
                    0,
                )
            }
        }

        textView.linksClickable = true
        textView.movementMethod = LinkMovementMethod.getInstance()
        textView.text = combinedSpannable
    }

    override fun dispose() {}
}
