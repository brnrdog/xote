package dev.xote.host

import android.graphics.Color
import android.graphics.Typeface
import android.text.Layout

/**
 * A size in the style vocabulary: points, a percentage of something, or nothing
 * at all. `auto` and an absent value are the same thing here.
 *
 * A transliteration of `XoteDimension` in the iOS host. **Points are density-
 * independent**: the app writes the same numbers on both platforms, and the
 * host multiplies by the display density on the way to pixels — which on iOS is
 * free, because `UIView` frames are already in points, and on Android is not.
 * See [XoteHost.density].
 */
sealed class XoteDimension {
  data class Points(val value: Float) : XoteDimension()

  data class Percent(val value: Float) : XoteDimension()

  object Auto : XoteDimension()

  fun resolve(base: Float?): Float? =
    when (this) {
      is Points -> value
      is Percent -> base?.let { it * value / 100f }
      is Auto -> null
    }

  /** Resolvable without knowing what it is a percentage of. */
  val isDefinite: Boolean
    get() = this is Points
}

/**
 * A style object off the bridge, read with the types layout and Android want.
 *
 * The vocabulary is `xote-native/src/NativeStyle.res`; the reader is deliberately dumb,
 * because the wire format is already the shape ReScript wrote. Every key it
 * knows about is listed in `xote-native/src/host/capabilities.mjs`, and
 * `xote-native/test/surface_test.mjs` fails if the two disagree.
 */
class XoteStyle(values: Map<String, Any?>?) {
  val values: Map<String, Any?> = values ?: emptyMap()

  // ---- reading ------------------------------------------------------------

  fun number(key: String): Float? = (values[key] as? Number)?.toFloat()

  fun string(key: String): String? = values[key] as? String

  fun dimension(key: String): XoteDimension {
    number(key)?.let { return XoteDimension.Points(it) }
    val text = string(key)
    if (text != null && text.endsWith("%")) {
      text.dropLast(1).toFloatOrNull()?.let { return XoteDimension.Percent(it) }
    }
    return XoteDimension.Auto
  }

  // ---- box model ----------------------------------------------------------

  /** One edge of `margin` / `padding`, with the shorthands folded in. */
  private fun edge(prefix: String, side: String): Float {
    number(prefix + side)?.let { return it }
    val axis = if (side == "Left" || side == "Right") "Horizontal" else "Vertical"
    number(prefix + axis)?.let { return it }
    return number(prefix) ?: 0f
  }

  fun edges(prefix: String): XoteEdges =
    XoteEdges(
      left = edge(prefix, "Left"),
      right = edge(prefix, "Right"),
      top = edge(prefix, "Top"),
      bottom = edge(prefix, "Bottom"),
    )

  /** Padding plus border — the inset from a node's box to its content. */
  val inset: XoteEdges
    get() {
      val padding = edges("padding")
      val border = number("borderWidth") ?: 0f
      return XoteEdges(
        left = padding.left + border,
        right = padding.right + border,
        top = padding.top + border,
        bottom = padding.bottom + border,
      )
    }

  fun gap(isRow: Boolean): Float {
    number(if (isRow) "columnGap" else "rowGap")?.let { return it }
    return number("gap") ?: 0f
  }

  // ---- flex ---------------------------------------------------------------

  /** `flex: n` is `flexGrow: n, flexShrink: 1, flexBasis: 0`, as in CSS and RN. */
  val flexGrow: Float
    get() {
      number("flexGrow")?.let { return it }
      val flex = number("flex")
      if (flex != null && flex > 0f) return flex
      return 0f
    }

  val flexShrink: Float
    get() {
      number("flexShrink")?.let { return it }
      return if (number("flex") != null) 1f else 0f
    }

  val flexBasis: XoteDimension
    get() {
      if (values["flexBasis"] != null && string("flexBasis") != "auto") {
        return dimension("flexBasis")
      }
      val flex = number("flex")
      if (flex != null && flex > 0f) return XoteDimension.Points(0f)
      return XoteDimension.Auto
    }

  // ---- paint --------------------------------------------------------------

  fun color(key: String): Int? = string(key)?.let { colorFromHex(it) }

  val typeface: Typeface
    get() {
      val family = string("fontFamily")
      val base = if (family != null) Typeface.create(family, Typeface.NORMAL) else Typeface.DEFAULT
      // Android has one bold bit below API 28, so the seven named weights
      // collapse onto it. `Typeface.create(base, weight, italic)` on API 28+
      // would carry the distinction; this host targets older devices too, and a
      // wrong-but-close weight is better than a crash.
      val bold =
        when (string("fontWeight") ?: "regular") {
          "semibold", "bold", "heavy" -> true
          else -> false
        }
      return Typeface.create(base, if (bold) Typeface.BOLD else Typeface.NORMAL)
    }

  val alignment: Layout.Alignment
    get() =
      when (string("textAlign") ?: "auto") {
        "center" -> Layout.Alignment.ALIGN_CENTER
        "right" -> Layout.Alignment.ALIGN_OPPOSITE
        else -> Layout.Alignment.ALIGN_NORMAL
      }

  /** The `android:gravity` equivalent, for a `TextView`. */
  val gravity: Int
    get() =
      when (string("textAlign") ?: "auto") {
        "center" -> android.view.Gravity.CENTER_HORIZONTAL
        "right" -> android.view.Gravity.END
        else -> android.view.Gravity.START
      }

  companion object {
    /**
     * `#rgb`, `#rrggbb` and `#rrggbbaa`.
     *
     * Hand-rolled rather than `Color.parseColor`, for one reason that matters:
     * `parseColor` reads a leading pair as **alpha** in an eight-digit string,
     * and the wire format — like CSS, like the iOS host — puts alpha last. The
     * same colour would come out of the two platforms differently, and it would
     * look like a theme bug rather than a parsing one.
     */
    fun colorFromHex(hex: String): Int? {
      var digits = hex.trim()
      if (!digits.startsWith("#")) return null
      digits = digits.substring(1)

      if (digits.length == 3) {
        digits = digits.map { "$it$it" }.joinToString("")
      }
      if (digits.length != 6 && digits.length != 8) return null
      val value = digits.toLongOrNull(16) ?: return null

      val hasAlpha = digits.length == 8
      val r = ((value shr (if (hasAlpha) 24 else 16)) and 0xFF).toInt()
      val g = ((value shr (if (hasAlpha) 16 else 8)) and 0xFF).toInt()
      val b = ((value shr (if (hasAlpha) 8 else 0)) and 0xFF).toInt()
      val a = if (hasAlpha) (value and 0xFF).toInt() else 255
      return Color.argb(a, r, g, b)
    }
  }
}
