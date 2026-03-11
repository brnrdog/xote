%%raw(`import './Basefn__Stepper.css'`)

open Xote

type orientation = Horizontal | Vertical

type stepStatus = Inactive | Active | Completed | Error

type step = {
  title: string,
  description: option<string>,
  status: stepStatus,
}

let statusToString = (status: stepStatus) => {
  switch status {
  | Inactive => "inactive"
  | Active => "active"
  | Completed => "completed"
  | Error => "error"
  }
}

@jsx.component
let make = (
  ~steps: array<step>,
  ~currentStep: Signal.t<int>,
  ~orientation: orientation=Horizontal,
  ~onStepClick: option<int => unit>=?,
) => {
  let handleStepClick = (index: int, status: stepStatus) => {
    switch onStepClick {
    | Some(callback) =>
      // Only allow clicking on completed steps or current step in non-linear mode
      switch status {
      | Completed | Active => callback(index)
      | _ => ()
      }
    | None => ()
    }
  }

  let getStepperClass = () => {
    let orientationClass = switch orientation {
    | Horizontal => "basefn-stepper--horizontal"
    | Vertical => "basefn-stepper--vertical"
    }
    "basefn-stepper " ++ orientationClass
  }

  let getStepClass = (status: stepStatus, clickable: bool) => {
    let statusClass = "basefn-stepper__step--" ++ statusToString(status)
    let clickableClass = clickable ? " basefn-stepper__step--clickable" : ""
    "basefn-stepper__step " ++ statusClass ++ clickableClass
  }

  <div class={getStepperClass()}>
    {steps
    ->Array.mapWithIndex((step, index) => {
      let isClickable =
        onStepClick->Option.isSome && (step.status == Completed || step.status == Active)

      <div key={Int.toString(index)} class={getStepClass(step.status, isClickable)}>
        <div class="basefn-stepper__step-header" onClick={_ => handleStepClick(index, step.status)}>
          <div class="basefn-stepper__step-indicator">
            {switch step.status {
            | Completed => Component.text("\u2713")
            | Error => Component.text("\u00d7")
            | _ => Component.text(Int.toString(index + 1))
            }}
          </div>
          <div class="basefn-stepper__step-content">
            <div class="basefn-stepper__step-title"> {Component.text(step.title)} </div>
            {switch step.description {
            | Some(desc) =>
              <div class="basefn-stepper__step-description"> {Component.text(desc)} </div>
            | None => <> </>
            }}
          </div>
        </div>
        <div class="basefn-stepper__connector" />
      </div>
    })
    ->Component.fragment}
  </div>
}
