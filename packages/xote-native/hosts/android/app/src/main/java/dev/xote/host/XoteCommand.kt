package dev.xote.host

import org.json.JSONArray
import org.json.JSONObject

/**
 * One entry of a batch, decoded from the wire format in
 * `xote-native/src/host/protocol.mjs`.
 *
 * The wire format is a JSON array of arrays with the opcode first, which is why
 * this is `org.json` and a `when` rather than a data-binding library: the
 * elements are deliberately heterogeneous, and a style prop is an arbitrary
 * object.
 */
sealed class XoteCommand {
  data class Create(val id: Int, val type: String) : XoteCommand()

  data class CreateText(val id: Int, val text: String) : XoteCommand()

  data class SetProp(val id: Int, val key: String, val value: Any?) : XoteCommand()

  data class SetText(val id: Int, val text: String) : XoteCommand()

  data class Insert(val parent: Int, val child: Int, val index: Int) : XoteCommand()

  data class Remove(val parent: Int, val child: Int) : XoteCommand()

  data class Destroy(val id: Int) : XoteCommand()

  data class Listen(val id: Int, val event: String) : XoteCommand()

  data class Batch(val commands: List<XoteCommand>, val problems: List<String>)

  companion object {
    /** How many slots a command of each opcode occupies, opcode included. */
    private fun arity(op: Int): Int =
      when (op) {
        1, 2, 4, 8 -> 3
        3, 5 -> 4
        6 -> 3
        7 -> 2
        else -> Int.MAX_VALUE
      }

    /**
     * Decode a batch, skipping anything that cannot be read rather than
     * discarding the whole thing.
     *
     * The two halves of this bridge are versioned separately — a JavaScript
     * bundle can be newer than the app around it — so an opcode this host does
     * not know is a thing to skip and report, not a reason to drop every other
     * command in the batch alongside it. That is what makes the protocol's
     * append-only rule survivable in practice; see `protocol.mjs`.
     */
    fun decodeBatch(json: String): Batch {
      val commands = mutableListOf<XoteCommand>()
      val problems = mutableListOf<String>()

      val raw =
        try {
          JSONArray(json)
        } catch (error: Exception) {
          return Batch(emptyList(), listOf("batch is not JSON — ${error.message}"))
        }

      for (index in 0 until raw.length()) {
        val entry = raw.optJSONArray(index)
        if (entry == null) {
          problems.add("command $index is not an array")
          continue
        }
        val op = entry.optInt(0, -1)
        if (entry.length() < arity(op)) {
          problems.add("command $index has opcode $op and ${entry.length()} slots")
          continue
        }
        val command =
          when (op) {
            1 -> Create(entry.getInt(1), entry.getString(2))
            2 -> CreateText(entry.getInt(1), entry.getString(2))
            3 -> SetProp(entry.getInt(1), entry.getString(2), plain(entry.opt(3)))
            4 -> SetText(entry.getInt(1), entry.getString(2))
            5 -> Insert(entry.getInt(1), entry.getInt(2), entry.getInt(3))
            6 -> Remove(entry.getInt(1), entry.getInt(2))
            7 -> Destroy(entry.getInt(1))
            8 -> Listen(entry.getInt(1), entry.getString(2))
            else -> null
          }
        if (command == null) {
          problems.add("unknown opcode $op at command $index")
          continue
        }
        commands.add(command)
      }
      return Batch(commands, problems)
    }

    /**
     * `org.json` values into ordinary Kotlin ones, so nothing downstream has to
     * know where a style object came from. `JSONObject.NULL` is a *value*, not
     * `null`, and letting it through would make "clear this prop" arrive as an
     * object that is truthy.
     */
    private fun plain(value: Any?): Any? =
      when (value) {
        null, JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { plain(value.opt(it)) }
        is JSONArray -> (0 until value.length()).map { plain(value.opt(it)) }
        else -> value
      }
  }
}
