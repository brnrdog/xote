type props = {
  caption: string,
  children: View.node,
}

let make = (props: props) => {
  <figure class="inline-demo">
    <div class="inline-demo-stage"> {props.children} </div>
    <figcaption class="inline-demo-caption"> {View.text(props.caption)} </figcaption>
  </figure>
}
