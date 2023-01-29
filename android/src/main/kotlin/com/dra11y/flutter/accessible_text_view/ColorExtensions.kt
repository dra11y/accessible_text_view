package com.dra11y.flutter.accessible_text_view

import android.graphics.Color
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

fun List<Double>.toColor(): Int {
    val color = Color.argb(
        getOrNull(0)?.roundToInt() ?: 0,
        getOrNull(1)?.roundToInt() ?: 0,
        getOrNull(2)?.roundToInt() ?: 0,
        getOrNull(3)?.roundToInt() ?: 0,
    )
    println("color = ${color}")
    return color
}
