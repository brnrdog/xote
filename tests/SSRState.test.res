open! Zekr

module Codec = SSRState.Codec

let roundTrip = (codec: Codec.t<'a>, value: 'a): option<'a> => {
  let json = codec.encode(value)
  codec.decode(json)
}

let suite = Suite.make(
  "SSRState Codec",
  [
    Test.make("int codec round-trips", () => {
      Assert.equal(roundTrip(Codec.int, 42), Some(42))
    }),
    Test.make("float codec round-trips", () => {
      Assert.equal(roundTrip(Codec.float, 3.14), Some(3.14))
    }),
    Test.make("string codec round-trips", () => {
      Assert.equal(roundTrip(Codec.string, "hello"), Some("hello"))
    }),
    Test.make("bool codec round-trips true", () => {
      Assert.equal(roundTrip(Codec.bool, true), Some(true))
    }),
    Test.make("bool codec round-trips false", () => {
      Assert.equal(roundTrip(Codec.bool, false), Some(false))
    }),
    Test.make("array codec round-trips", () => {
      let codec = Codec.array(Codec.int)
      Assert.equal(roundTrip(codec, [1, 2, 3]), Some([1, 2, 3]))
    }),
    Test.make("option codec round-trips Some", () => {
      let codec = Codec.option(Codec.int)
      Assert.equal(roundTrip(codec, Some(5)), Some(Some(5)))
    }),
    Test.make("option codec round-trips None", () => {
      let codec = Codec.option(Codec.int)
      Assert.equal(roundTrip(codec, None), Some(None))
    }),
    Test.make("tuple2 codec round-trips", () => {
      let codec = Codec.tuple2(Codec.int, Codec.string)
      Assert.equal(roundTrip(codec, (1, "a")), Some((1, "a")))
    }),
    Test.make("tuple3 codec round-trips", () => {
      let codec = Codec.tuple3(Codec.int, Codec.string, Codec.bool)
      Assert.equal(roundTrip(codec, (1, "a", true)), Some((1, "a", true)))
    }),
    Test.make("nested codec: array of options", () => {
      let codec = Codec.array(Codec.option(Codec.int))
      Assert.equal(roundTrip(codec, [Some(1), None, Some(3)]), Some([Some(1), None, Some(3)]))
    }),
    Test.make("int codec decoding a string returns None", () => {
      let json = Codec.string.encode("not a number")
      Assert.equal(Codec.int.decode(json), None)
    }),
    Test.make("empty array round-trips", () => {
      let codec = Codec.array(Codec.string)
      Assert.equal(roundTrip(codec, []), Some([]))
    }),
    Test.make("generateScript contains window.__XOTE_STATE__", () => {
      SSRState.clear()
      let script = SSRState.generateScript()
      Assert.contains(script, "window.__XOTE_STATE__")
    }),
  ],
)
