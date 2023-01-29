package com.dra11y.flutter.accessible_text_view

import kotlinx.serialization.Serializable

@Serializable
data class AccessibleTextViewOptions(
    val html: String? = null,
    val textColor: List<Double>? = null,
    val linkColor: List<Double>? = null,
    val fontFamily: String? = null,
    val fontSize: Float? = null,
    val autoLinkify: Boolean? = null,
    val isSelectable: Boolean? = null,
    val maxLines: Int? = null,
    val errorCode: String? = null,
    val errorMessage: String? = null,
)

