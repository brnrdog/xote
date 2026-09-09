package dev.xote.host

import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The host conformance suite, replayed against Android views.
 *
 * The cases and the answers live in `native/conformance/suite.json`, shared with
 * the JavaScript hosts and with iOS — Gradle points this target's assets at that
 * directory rather than copying it, so there is one file and it cannot drift. A
 * host passes by applying the real wire format and ending up with the same node
 * tree, the same frames, the same text and the same **view tree**, not by being
 * written any particular way.
 *
 * This is an instrumented test rather than a JVM one because it needs real
 * `View`s, exactly as the iOS suite needs a simulator. It is also the only thing
 * in this repository that can tell you the Kotlin is right — there is no Android
 * toolchain where the JavaScript tests run.
 *
 * Text is measured by the same stub the reference host uses, because two hosts
 * can agree on layout and will never agree on font metrics.
 */
@RunWith(AndroidJUnit4::class)
class XoteConformanceTest {
  private val stubCharWidth = 7f
  private val stubLineHeight = 16f

  /**
   * A fixed-width font that wraps on whole characters. Must stay identical to
   * `stubMeasure` in `native/host/reference.mjs`.
   */
  private fun stubMeasure(
    text: String,
    availableWidth: Float?,
    widthMode: XoteMeasureMode,
  ): XoteSize {
    if (text.isEmpty()) return XoteSize(0f, 0f)
    val natural = text.length * stubCharWidth
    if (widthMode == XoteMeasureMode.UNDEFINED || availableWidth == null) {
      return XoteSize(natural, stubLineHeight)
    }
    val usable =
      if (widthMode == XoteMeasureMode.EXACTLY) availableWidth else min(availableWidth, natural)
    val perLine = max(1f, floor(usable / stubCharWidth))
    return XoteSize(
      width = if (widthMode == XoteMeasureMode.EXACTLY) availableWidth else min(natural, usable),
      height = ceil(text.length / perLine) * stubLineHeight,
    )
  }

  @Test
  fun conformance() {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val json =
      context.assets.open("suite.json").bufferedReader().use { it.readText() }
    val cases = JSONArray(json)
    assertTrue("suite.json is empty", cases.length() > 0)

    for (caseIndex in 0 until cases.length()) {
      val testCase = cases.getJSONObject(caseIndex)
      val name = testCase.getString("name")
      val viewport = testCase.getJSONObject("viewport")

      val root = XoteBox(context)
      // The suite's viewport is in points; the host multiplies by density on the
      // way to pixels, so the root is sized in pixels to match.
      val host = XoteHost(root)
      host.density = 1f
      host.measureOverride = { text, width, mode -> stubMeasure(text, width, mode) }
      val width = viewport.getDouble("width").toInt()
      val height = viewport.getDouble("height").toInt()
      root.layout(0, 0, width, height)
      root.layoutParams = FrameLayout.LayoutParams(width, height)

      val steps = testCase.getJSONArray("steps")
      val expected = testCase.getJSONArray("expected")

      for (stepIndex in 0 until steps.length()) {
        host.apply(steps.getJSONArray(stepIndex).toString())
        val want = expected.getJSONObject(stepIndex)
        val got = host.conformanceSnapshot()
        val step = "$name step $stepIndex"

        assertMap(step, "children", want.getJSONObject("structure"), got.structure)
        assertMap(step, "subviews", want.getJSONObject("views"), got.views)

        val texts = want.getJSONObject("texts")
        for (id in texts.keys()) {
          assertEquals("$step: text of $id", texts.getString(id), got.texts[id.toInt()])
        }

        val frames = want.getJSONObject("frames")
        assertEquals(
          "$step: the set of boxes on screen",
          frames.keys().asSequence().map { it.toInt() }.toSet(),
          got.frames.keys,
        )
        for (id in frames.keys()) {
          val wanted = frames.getJSONArray(id)
          val actual = got.frames[id.toInt()]!!
          for (axis in 0 until 4) {
            assertTrue(
              "$step: node $id frame $actual should be $wanted",
              abs(actual[axis] - wanted.getDouble(axis).toFloat()) <= 0.5f,
            )
          }
        }
      }
    }
  }

  /** Parent-to-children, for either tree. */
  private fun assertMap(
    step: String,
    what: String,
    want: JSONObject,
    got: Map<Int, List<Int>>,
  ) {
    assertEquals(
      "$step: the set of nodes with $what",
      want.keys().asSequence().map { it.toInt() }.toSet(),
      got.keys,
    )
    for (id in want.keys()) {
      val wanted = want.getJSONArray(id)
      val expected = (0 until wanted.length()).map { wanted.getInt(it) }
      assertEquals("$step: $what of $id", expected, got[id.toInt()] ?: emptyList<Int>())
    }
  }
}
