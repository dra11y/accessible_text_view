package com.dra11y.flutter.accessible_text_view

import kotlinx.serialization.Serializable

enum class Appearance {
    light,
    dark,
    system,
}

@Serializable
data class AccessibleTextViewOptions(
    val html: String? = null,
    val textColor: List<Double>? = null,
    val textWeight: Int? = null,
    val textIsItalic: Boolean? = null,
    val linkColor: List<Double>? = null,
    val linkWeight: Int? = null,
    val linkIsItalic: Boolean? = null,
    val backgroundColor: List<Double>? = null,
    val appearance: Appearance? = null,
    val fontFamily: String? = null,
    val fontSize: Float? = null,
    val autoLinkify: Boolean? = null,
    val isSelectable: Boolean? = null,
    val maxLines: Int? = null,
    val errorCode: String? = null,
    val errorMessage: String? = null,
)

