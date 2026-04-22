type props = {
  caption: string,
  children: Node.node,
}

let make = (props: props) => {
  <figure class="inline-demo">
    <div class="inline-demo-stage"> {props.children} </div>
    <figcaption class="inline-demo-caption"> {Node.text(props.caption)} </figcaption>
  </figure>
}
