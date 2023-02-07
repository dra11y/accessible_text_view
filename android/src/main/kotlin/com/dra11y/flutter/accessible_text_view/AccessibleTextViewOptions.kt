package com.dra11y.flutter.accessible_text_view

import android.graphics.Typeface
import com.dra11y.flutter.native_flutter_fonts.FlutterFontRegistry
import com.dra11y.flutter.native_flutter_fonts.withItalic
import com.dra11y.flutter.native_flutter_fonts.withWeight
import kotlinx.serialization.SerialInfo
import kotlinx.serialization.Serializable
import kotlinx.serialization.Serializer

internal typealias APIColor = List<Double>

@Serializable
data class AccessibleTextViewOptions(
    val html: String? = null,
    val textStyle: TextStyle? = null,
    val linkStyle: TextStyle? = null,
    val backgroundColor: APIColor? = null,
    val brightness: Brightness? = null,
    val autoLinkify: Boolean? = null,
    val isSelectable: Boolean? = null,
    val maxLines: Int? = null,
    val accessibilityHintAndroid: String? = null,
    val errorCode: String? = null,
    val errorMessage: String? = null,
) {
    enum class Brightness {
        light,
        dark,
    }

    @Serializable
    data class TextStyle(
        val color: APIColor? = null,
        val backgroundColor: APIColor? = null,
        val fontFamily: String? = null,
        val fontSize: Float? = null,
        val fontWeight: Int? = null,
        val fontStyle: String? = null,
        val letterSpacing: Float? = null,
        val wordSpacing: Float? = null,
        val height: Float? = null,
        val decoration: String? = null,
        val decorationColor: APIColor? = null,
        val decorationStyle: String? = null,
        val decorationThickness: Float? = null,
        val overflow: String? = null,
    ) {

        val fontWeightOrDefault: Int
            get() = fontWeight ?: 400

        val isItalic: Boolean
            get() = fontStyle == "italic"

        val isUnderline: Boolean
            get() = decoration == "underline"

        val isLineThrough: Boolean
            get() = decoration == "lineThrough"

        fun resolveTypeface(): Typeface {
            return FlutterFontRegistry.resolve(
                fontFamily,
                weight = fontWeightOrDefault,
                isItalic = isItalic,
            )
                .withWeight(fontWeightOrDefault)
                .withItalic(isItalic)
        }
    }
}
