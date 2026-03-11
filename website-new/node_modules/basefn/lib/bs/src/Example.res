// Example usage of basefn-UI components

open Basefn
open Xote

module ExampleForm = {
  @jsx.component
  let make = () => {
    // Form state using signals
    let name = Signal.make("")
    let email = Signal.make("")
    let message = Signal.make("")
    let agreeToTerms = Signal.make(false)
    let selectedOption = Signal.make("option1")
    let isSubmitting = Signal.make(false)

    // Event handlers
    let handleNameChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(name, target["value"])
    }

    let handleEmailChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(email, target["value"])
    }

    let handleMessageChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(message, target["value"])
    }

    let handleCheckboxChange = _evt => {
      Signal.update(agreeToTerms, prev => !prev)
    }

    let handleSubmit = _evt => {
      Signal.set(isSubmitting, true)
      // Simulate API call
      Console.log("Submitting form...")
      Console.log(`Name: ${Signal.get(name)}`)
      Console.log(`Email: ${Signal.get(email)}`)
      Console.log(`Message: ${Signal.get(message)}`)

      let _ = setTimeout(() => {
        Signal.set(isSubmitting, false)
        ()
      }, 1000)
    }

    let selectOptions = Signal.make([
      ({value: "option1", label: "Option 1"}: selectOption),
      ({value: "option2", label: "Option 2"}: selectOption),
      ({value: "option3", label: "Option 3"}: selectOption),
    ])

    <div style="max-width: 50rem; margin: auto;">
      <h1> {Component.text("Contact Form Example")} </h1>

      <div style="margin-bottom: 1rem;">
        <Label text="Name" required={true} />
        <Input
          value={Reactive(name)}
          onInput={handleNameChange}
          type_={Input.Text}
          placeholder="Enter your name"
        />
      </div>

      <div style="margin-bottom: 1rem;">
        <Label text="Email" required={true} />
        <Input
          value={Reactive(email)}
          onInput={handleEmailChange}
          type_={Input.Email}
          placeholder="Enter your email"
        />
      </div>

      <div style="margin-bottom: 1rem;">
        <Label text="Choose an option" required={false} />
        <Select value={selectedOption} options={selectOptions} />
      </div>

      <div style="margin-bottom: 1rem;">
        <Label text="Message" required={false} />
        <Textarea
          value={Reactive(message)} onInput={handleMessageChange} placeholder="Enter your message"
        />
      </div>

      <div style="margin-bottom: 1rem;">
        <Checkbox
          checked={agreeToTerms}
          onChange={handleCheckboxChange}
          label="I agree to the terms and conditions"
        />
      </div>

      <div style="display: flex; gap: 1rem;">
        <Button onClick={handleSubmit} variant={Button.Primary} disabled={Reactive(isSubmitting)}>
          {Component.textSignal(() => Signal.get(isSubmitting) ? "Submitting..." : "Submit")}
        </Button>
        <Button label={Static("Cancel")} variant={Button.Ghost} />
      </div>
    </div>
  }
}

// Mount the example form
Component.mountById(<ExampleForm />, "root")
