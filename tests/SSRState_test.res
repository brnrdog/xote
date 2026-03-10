open Zekr
open Xote

module Codec = SSRState.Codec

let roundTrip = (codec: Codec.t<'a>, value: 'a): option<'a> => {
  let json = codec.encode(value)
  codec.decode(json)
}

let suite = Zekr.suite(
  "SSRState Codec",
  [
    test("int codec round-trips", () => {
      assertEqual(roundTrip(Codec.int, 42), Some(42))
    }),
    test("float codec round-trips", () => {
      assertEqual(roundTrip(Codec.float, 3.14), Some(3.14))
    }),
    test("string codec round-trips", () => {
      assertEqual(roundTrip(Codec.string, "hello"), Some("hello"))
    }),
    test("bool codec round-trips true", () => {
      assertEqual(roundTrip(Codec.bool, true), Some(true))
    }),
    test("bool codec round-trips false", () => {
      assertEqual(roundTrip(Codec.bool, false), Some(false))
    }),
    test("array codec round-trips", () => {
      let codec = Codec.array(Codec.int)
      assertEqual(roundTrip(codec, [1, 2, 3]), Some([1, 2, 3]))
    }),
    test("option codec round-trips Some", () => {
      let codec = Codec.option(Codec.int)
      assertEqual(roundTrip(codec, Some(5)), Some(Some(5)))
    }),
    test("option codec round-trips None", () => {
      let codec = Codec.option(Codec.int)
      assertEqual(roundTrip(codec, None), Some(None))
    }),
    test("tuple2 codec round-trips", () => {
      let codec = Codec.tuple2(Codec.int, Codec.string)
      assertEqual(roundTrip(codec, (1, "a")), Some((1, "a")))
    }),
    test("tuple3 codec round-trips", () => {
      let codec = Codec.tuple3(Codec.int, Codec.string, Codec.bool)
      assertEqual(roundTrip(codec, (1, "a", true)), Some((1, "a", true)))
    }),
    test("nested codec: array of options", () => {
      let codec = Codec.array(Codec.option(Codec.int))
      assertEqual(
        roundTrip(codec, [Some(1), None, Some(3)]),
        Some([Some(1), None, Some(3)]),
      )
    }),
    test("int codec decoding a string returns None", () => {
      let json = Codec.string.encode("not a number")
      assertEqual(Codec.int.decode(json), None)
    }),
    test("empty array round-trips", () => {
      let codec = Codec.array(Codec.string)
      assertEqual(roundTrip(codec, []), Some([]))
    }),
    test("generateScript contains window.__XOTE_STATE__", () => {
      SSRState.clear()
      let script = SSRState.generateScript()
      assertContains(script, "window.__XOTE_STATE__")
    }),
  ],
)
