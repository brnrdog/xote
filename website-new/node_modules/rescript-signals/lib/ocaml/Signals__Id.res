let next = ref(0)
let make = () => {
	next := next.contents + 1
	next.contents
}