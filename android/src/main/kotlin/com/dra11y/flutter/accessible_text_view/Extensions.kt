package com.dra11y.flutter.accessible_text_view

import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.provider.CalendarContract.Colors
import android.text.Spannable
import android.text.SpannableString
import android.text.TextPaint
import android.text.style.URLSpan
import android.text.util.Linkify

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

fun Spannable.formatSpans(linkStyle: AccessibleTextViewOptions.TextStyle?) {
    if (linkStyle == null) return

    val spans = getSpans(0, length, URLSpan::class.java)
        .sortedBy { getSpanStart(it) }
    val typeface = linkStyle.resolveTypeface()
    val color = linkStyle.color?.toColor() ?: Color.BLUE
    val underlineColor = linkStyle.decorationColor?.toColor() ?: Color.BLUE

    for (span in spans) {
        val urlSpan = object : URLSpan(span.url) {
            override fun updateDrawState(ds: TextPaint) {
                super.updateDrawState(ds)
                ds.typeface = typeface
                ds.color = color
                ds.isUnderlineText = linkStyle.isUnderline
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    ds.underlineColor = underlineColor
                    linkStyle.decorationThickness?.let { thickness ->
                        ds.underlineThickness = thickness
                    }
                    ds.isStrikeThruText = linkStyle.isLineThrough
                }
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
