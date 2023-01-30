package com.dra11y.flutter.accessible_text_view

import android.graphics.Typeface
import android.os.Build
import android.text.Spannable
import android.text.SpannableString
import android.text.TextPaint
import android.text.style.URLSpan
import android.text.util.Linkify

fun Typeface.withWeight(weight: Int): Typeface = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
    Typeface.create(this, weight, isItalic)
} else {
    val style = if (weight > 400) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
    Typeface.create(this, style.style)
}

fun Spannable.autoLinkify() {
    val autoSpannable = SpannableString(this)
    Linkify.addLinks(autoSpannable, Linkify.ALL)
    val autoSpans = autoSpannable.getSpans(0, autoSpannable.length, URLSpan::class.java)
    for (span in autoSpans) {
        setSpan(
            span,
            autoSpannable.getSpanStart(span),
            autoSpannable.getSpanEnd(span),
            0,
        )
    }
}

fun Spannable.formatSpans(typeface: Typeface) {
    val spans = getSpans(0, length, URLSpan::class.java)
        .sortedBy { getSpanStart(it) }
    for (span in spans) {
        val urlSpan = object : URLSpan(span.url) {
            override fun updateDrawState(ds: TextPaint) {
                super.updateDrawState(ds)
                ds.typeface = typeface
            }
        }
        setSpan(
            urlSpan,
            getSpanStart(span),
            getSpanEnd(span),
            0,
        )
        // Remove the old span so we don't get duplicates in TalkBack.
        removeSpan(span)
    }
}
