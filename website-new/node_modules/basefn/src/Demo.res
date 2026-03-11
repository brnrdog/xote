// Demo application showcasing basefn-UI components

%%raw(`import './styles/variables.css'`)
%%raw(`import './eita.css'`)

open Xote
open Basefn

@get external target: Dom.event => Dom.element = "target"
@set external setValue: (Dom.element, string) => unit = "value"
@get external key: Dom.event => string = "key"

@get external value: Dom.element => string = "value"
@send external preventDefault: Dom.event => unit = "preventDefault"

module Demo = {
  @jsx.component
  let make = () => {
    // Form state using signals
    let name = Signal.make("")
    let email = Signal.make("")
    let password = Signal.make("")
    let message = Signal.make("")
    let agreeToTerms = Signal.make(false)
    let newsletter = Signal.make(false)
    let selectedOption = Signal.make("option1")
    let selectedColor = Signal.make("blue")
    let isSubmitting = Signal.make(false)
    let downloadProgress = Signal.make(65.0)

    // Tier 3 component states
    let isModalOpen = Signal.make(false)
    let sliderValue = Signal.make(50.0)
    let switchEnabled = Signal.make(false)
    let darkModeSwitch = Signal.make(true)
    let notificationsSwitch = Signal.make(false)
    let toastVisible = Signal.make(false)

    // Tier 4 component states
    let currentStep = Signal.make(1)
    let isDrawerOpen = Signal.make(false)

    // Layout component states
    let activeNavItem = Signal.make("home")
    let sidebarCollapsed = Signal.make(false)

    // Event handlers
    let handleNameChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(name, target["value"])
    }

    let handleEmailChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(email, target["value"])
    }

    let handlePasswordChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(password, target["value"])
    }

    let handleMessageChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(message, target["value"])
    }

    let handleTermsChange = _evt => {
      Signal.update(agreeToTerms, prev => !prev)
    }

    let handleNewsletterChange = _evt => {
      Signal.update(newsletter, prev => !prev)
    }

    let handleColorChange = evt => {
      let target = Obj.magic(evt)["target"]
      Signal.set(selectedColor, target["value"])
    }

    let handleSubmit = _evt => {
      Signal.set(isSubmitting, true)
      Console.log("=== Form Submission ===")
      Console.log(`Name: ${Signal.get(name)}`)
      Console.log(`Email: ${Signal.get(email)}`)
      Console.log(`Password: ${Signal.get(password)}`)
      Console.log(`Message: ${Signal.get(message)}`)
      Console.log(`Selected Option: ${Signal.get(selectedOption)}`)
      Console.log(`Selected Color: ${Signal.get(selectedColor)}`)
      Console.log(`Agree to Terms: ${Signal.get(agreeToTerms)->Bool.toString}`)
      Console.log(`Newsletter: ${Signal.get(newsletter)->Bool.toString}`)

      // Simulate API call
      setTimeout(() => {
        Signal.set(isSubmitting, false)
        Console.log("Form submitted successfully!")
      }, 2000)->ignore
    }

    let handleReset = _evt => {
      Signal.set(name, "")
      Signal.set(email, "")
      Signal.set(password, "")
      Signal.set(message, "")
      Signal.set(agreeToTerms, false)
      Signal.set(newsletter, false)
      Signal.set(selectedOption, "option1")
      Signal.set(selectedColor, "blue")
      Console.log("Form reset")
    }

    let selectOptions: array<selectOption> = [
      {value: "option1", label: "Web Development"},
      {value: "option2", label: "Mobile Development"},
      {value: "option3", label: "UI/UX Design"},
      {value: "option4", label: "Other"},
    ]
    let selectOptionsSignal = Signal.make(selectOptions)

    <>
      {Component.textSignal(() => Signal.get(selectedOption))}
      <h1> {Component.text("basefn-UI Component Library")} </h1>
      <p style="color: #6b7280; margin-bottom: 2rem;">
        {Component.text(
          "A demonstration of all form components with both static and reactive values.",
        )}
      </p>

      <Card style="margin-bottom: 2rem;">
        <Grid>
          <Avatar src="https://upload.wikimedia.org/wikipedia/commons/a/ad/Schopfkarakara.jpg" />
          <div>
            <Typography
              text={ReactiveProp.Static("Crested Caracara")}
              variant=Typography.Unstyled
              class="bold"
            />
            <Typography text={ReactiveProp.Static("Bird of prey")} variant=Typography.Small />
          </div>
        </Grid>
        <br />
        <Grid>
          <Avatar src="https://upload.wikimedia.org/wikipedia/commons/a/ad/Schopfkarakara.jpg" />
          <div>
            <Typography
              text={ReactiveProp.Static("Crested Caracara")} variant=Typography.P class="bold"
            />
          </div>
        </Grid>
        <br />
        <Grid>
          <Avatar
            src="https://upload.wikimedia.org/wikipedia/commons/a/ad/Schopfkarakara.jpg" size={Sm}
          />
          <div>
            <Typography
              text={ReactiveProp.Static("Crested Caracara")} variant=Typography.Unstyled
            />
          </div>
        </Grid>
        <br />
        <Grid gap="1rem">
          <Avatar
            src="https://upload.wikimedia.org/wikipedia/commons/a/ad/Schopfkarakara.jpg" size={Lg}
          />
          <div>
            <Typography text={ReactiveProp.Static("Crested Caracara")} variant=Typography.H4 />
            <Typography
              text={ReactiveProp.Static("Bird of prey")}
              variant=Typography.H6
              class="muted font-normal"
            />
          </div>
        </Grid>
      </Card>

      <Card>
        <Label text="Full Name" required={true} />
        <Input
          value={Reactive(name)}
          onInput={handleNameChange}
          type_={Input.Text}
          placeholder="John Doe"
        />
        <br />
        <Label text="Email Address" required={true} />
        <Input
          value={Reactive(email)}
          onInput={handleEmailChange}
          type_={Input.Email}
          placeholder="john@example.com"
        />
        <br />
        <Label text="Password" required={true} />
        <Input
          value={Reactive(password)}
          onInput={handlePasswordChange}
          type_={Input.Password}
          placeholder="Enter a secure password"
        />
      </Card>
      <br />
      <Card>
        <Label text="Area of Interest" required={false} />
        <Select
          value={selectedOption}
          options={selectOptionsSignal}
          onChange={e => {
            let target = Obj.magic(e)["target"]
            Signal.set(selectedOption, target["value"])
          }}
        />
        <br />
        <Label text="Favorite Color" required={false} />
        <div style="display: flex; gap: 1rem; margin-top: 0.5rem;">
          <Radio
            checked={Computed.make(() => Signal.get(selectedColor) == "blue")}
            onChange={handleColorChange}
            value="blue"
            label="Blue"
            name="radio"
          />
          <Radio
            checked={Computed.make(() => Signal.get(selectedColor) == "green")}
            onChange={handleColorChange}
            value="green"
            label="Green"
            name="radio"
          />
          <Radio
            checked={Computed.make(() => Signal.get(selectedColor) == "red")}
            onChange={handleColorChange}
            value="red"
            label="Red"
            name="radio"
          />
        </div>
      </Card>
      <br />
      <Card>
        <Label text="Message" required={false} />
        <Textarea
          value={Reactive(message)}
          onInput={handleMessageChange}
          placeholder="Tell us more about yourself..."
        />
      </Card>
      <br />
      <Card>
        <div style="margin-bottom: 1.5rem;">
          <Checkbox
            checked={agreeToTerms}
            onChange={handleTermsChange}
            label="I agree to the terms and conditions"
          />
        </div>

        <div style="margin-bottom: 2rem;">
          <Checkbox
            checked={newsletter}
            onChange={handleNewsletterChange}
            label="Subscribe to our newsletter"
          />
        </div>

        <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
          {Component.SignalFragment(
            Computed.make(() => {
              [
                <Button
                  label={Signal.get(isSubmitting) ? Static("Submitting...") : Static("Submit Form")}
                  onClick={handleSubmit}
                  variant={Button.Primary}
                  disabled={isSubmitting->ReactiveProp.Reactive}
                />,
              ]
            }),
          )}
          <Button
            label={Static("reset")}
            onClick={handleReset}
            variant={Button.Secondary}
            disabled={isSubmitting->ReactiveProp.Reactive}
          />
          <Button
            label={Static("Cancel")}
            variant={Button.Ghost}
            disabled={isSubmitting->ReactiveProp.Reactive}
          />
        </div>
      </Card>

      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Alerts")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Display important messages with different severity levels.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <Alert
            title="Information"
            message={Signal.make("This is an informational alert message.")}
            variant={Alert.Info}
          />
          <Alert
            title="Success"
            message={Signal.make("Your changes have been saved successfully!")}
            variant={Alert.Success}
          />
          <Alert
            title="Warning"
            message={Signal.make("Please review your input before proceeding.")}
            variant={Alert.Warning}
          />
          <Alert
            title="Error"
            message={Signal.make("An error occurred while processing your request.")}
            variant={Alert.Error}
          />
          <Alert
            message={Signal.make("This is a dismissible alert. Click the X to close it.")}
            variant={Alert.Info}
            dismissible={true}
          />
        </div>
      </div>

      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Progress")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Show progress indicators for ongoing operations.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 2rem;">
          <div>
            <Progress value={Signal.make(25.0)} variant={Progress.Primary} showLabel={true} />
          </div>
          <div>
            <Progress
              value={Signal.make(50.0)} variant={Progress.Success} showLabel={true} label="Upload"
            />
          </div>
          <div>
            <Progress
              value={Signal.make(75.0)}
              variant={Progress.Warning}
              showLabel={true}
              label="Processing"
            />
          </div>
          <div>
            <Progress
              value={Signal.make(100.0)}
              variant={Progress.Success}
              showLabel={true}
              label="Complete"
            />
          </div>
          <div>
            <Progress
              value={downloadProgress}
              variant={Progress.Primary}
              showLabel={true}
              label="Dynamic Progress"
            />
            <Button
              label={Static("Simulate Progress")}
              onClick={_evt => {
                Signal.set(downloadProgress, 0.0)
                let intervalId = ref(None)
                let id = setInterval(() => {
                  Signal.update(downloadProgress, prev => {
                    let next = prev +. 5.0
                    if next >= 100.0 {
                      switch intervalId.contents {
                      | Some(id) => clearInterval(id)
                      | None => ()
                      }
                      100.0
                    } else {
                      next
                    }
                  })
                }, 100)
                intervalId := Some(id)
              }}
              variant={Button.Secondary}
            />
          </div>
          <div>
            <p style="color: #6b7280; margin-bottom: 0.5rem;">
              {Component.text("Indeterminate progress:")}
            </p>
            <Progress value={Signal.make(0.0)} variant={Progress.Primary} indeterminate={true} />
          </div>
        </div>
      </div>

      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Tabs")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Organize content into tabbed sections.")}
        </p>
        <Tabs
          tabs={[
            {
              value: "account",
              label: "Account",
              content: <div>
                <Typography
                  text={ReactiveProp.Static("Account Settings")} variant={Typography.H5}
                />
                <p style="color: #6b7280; margin-top: 0.5rem;">
                  {Component.text(
                    "Manage your account settings and preferences here. You can update your profile information, change your password, and configure notification settings.",
                  )}
                </p>
              </div>,
            },
            {
              value: "security",
              label: "Security",
              content: <div>
                <Typography
                  text={ReactiveProp.Static("Security Settings")} variant={Typography.H5}
                />
                <p style="color: #6b7280; margin-top: 0.5rem;">
                  {Component.text(
                    "Configure your security preferences including two-factor authentication, active sessions, and security logs.",
                  )}
                </p>
                <div style="margin-top: 1rem;">
                  <Checkbox
                    checked={Signal.make(true)}
                    onChange={_ => ()}
                    label="Enable two-factor authentication"
                  />
                </div>
              </div>,
            },
            {
              value: "notifications",
              label: "Notifications",
              content: <div>
                <Typography
                  text={ReactiveProp.Static("Notification Preferences")} variant={Typography.H5}
                />
                <p style="color: #6b7280; margin-top: 0.5rem;">
                  {Component.text("Choose how you want to receive notifications.")}
                </p>
                <div style="display: flex; flex-direction: column; gap: 0.75rem; margin-top: 1rem;">
                  <Checkbox
                    checked={Signal.make(true)} onChange={_ => ()} label="Email notifications"
                  />
                  <Checkbox
                    checked={Signal.make(false)} onChange={_ => ()} label="SMS notifications"
                  />
                  <Checkbox
                    checked={Signal.make(true)} onChange={_ => ()} label="Push notifications"
                  />
                </div>
              </div>,
            },
            {
              value: "billing",
              label: "Billing",
              content: <div>
                <Typography
                  text={ReactiveProp.Static("Billing Information")} variant={Typography.H5}
                />
                <p style="color: #6b7280; margin-top: 0.5rem;">
                  {Component.text(
                    "View and manage your billing information, payment methods, and invoices.",
                  )}
                </p>
              </div>,
              disabled: true,
            },
          ]}
        />
      </div>

      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Accordion")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Collapsible content sections with expand/collapse functionality.")}
        </p>
        <Accordion
          items={[
            {
              value: "faq1",
              title: "What is basefn-UI?",
              content: <p>
                {Component.text(
                  "basefn-UI is a modern, reactive UI component library built with ReScript and Xote. It provides a comprehensive set of accessible and customizable components for building web applications.",
                )}
              </p>,
            },
            {
              value: "faq2",
              title: "How do I install basefn-UI?",
              content: <div>
                <p>
                  {Component.text(
                    "You can install basefn-UI via npm or yarn. Here's how to get started:",
                  )}
                </p>
                <br />
                <Typography
                  text={ReactiveProp.Static("npm install basefn-ui")} variant={Typography.Code}
                />
              </div>,
            },
            {
              value: "faq3",
              title: "Is basefn-UI customizable?",
              content: <p>
                {Component.text(
                  "Yes! basefn-UI is fully customizable. You can override the default styles using CSS variables or by providing custom CSS classes. Each component accepts standard HTML attributes including className and style.",
                )}
              </p>,
            },
            {
              value: "faq4",
              title: "Does basefn-UI support TypeScript?",
              content: <p>
                {Component.text(
                  "basefn-UI is built with ReScript, which provides excellent type safety. While it doesn't directly use TypeScript, ReScript's type system is even more robust and catches errors at compile time.",
                )}
              </p>,
            },
          ]}
          multiple={true}
          defaultOpen={["faq1"]}
        />
      </div>

      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Breadcrumb")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Navigation breadcrumbs to show the current page hierarchy.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 1.5rem;">
          <div>
            <p style="color: #6b7280; margin-bottom: 0.5rem; font-size: 0.875rem;">
              {Component.text("Default separator:")}
            </p>
            <Breadcrumb
              items={[
                {label: "Home", href: Some("#"), onClick: None},
                {label: "Products", href: Some("#"), onClick: None},
                {label: "Electronics", href: Some("#"), onClick: None},
                {label: "Laptops", href: None, onClick: None},
              ]}
            />
          </div>
          <div>
            <p style="color: #6b7280; margin-bottom: 0.5rem; font-size: 0.875rem;">
              {Component.text("Custom separator:")}
            </p>
            <Breadcrumb
              items={[
                {label: "Home", href: Some("#"), onClick: None},
                {label: "Settings", href: Some("#"), onClick: None},
                {label: "Account", href: None, onClick: None},
              ]}
              separator=">"
            />
          </div>
          <div>
            <p style="color: #6b7280; margin-bottom: 0.5rem; font-size: 0.875rem;">
              {Component.text("With onClick handlers:")}
            </p>
            <Breadcrumb
              items={[
                {
                  label: "Dashboard",
                  href: None,
                  onClick: Some(() => Console.log("Navigate to Dashboard")),
                },
                {
                  label: "Users",
                  href: None,
                  onClick: Some(() => Console.log("Navigate to Users")),
                },
                {label: "Profile", href: None, onClick: None},
              ]}
              separator="\u2022"
            />
          </div>
        </div>
      </div>

      <Separator orientation={Separator.Horizontal} variant={Separator.Solid} label={"Tier 3"} />

      <div style="margin-top: 3rem;">
        <Typography
          text={ReactiveProp.Static("Interactive Components")}
          variant={Typography.H2}
          align={Typography.Left}
        />
        <Typography
          text={ReactiveProp.Static("Explore the Tier 3 advanced interactive components below.")}
          variant={Typography.Muted}
        />
      </div>

      // Modal Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Modal / Dialog")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Display content in an overlay dialog.")}
        </p>
        <Button
          label={Static("Open Modal")}
          onClick={_ => Signal.set(isModalOpen, true)}
          variant={Button.Primary}
        />
        <Modal
          isOpen={isModalOpen}
          onClose={() => Signal.set(isModalOpen, false)}
          title="Example Modal"
          size={Modal.Md}
          footer={<div style="display: flex; gap: 0.5rem;">
            <Button
              label={Static("Cancel")}
              onClick={_ => Signal.set(isModalOpen, false)}
              variant={Button.Ghost}
            />
            <Button
              label={Static("Confirm")}
              onClick={_ => {
                Console.log("Confirmed!")
                Signal.set(isModalOpen, false)
              }}
              variant={Button.Primary}
            />
          </div>}
        >
          <p>
            {Component.text(
              "This is a modal dialog. You can include any content here. Click the backdrop or the close button to dismiss.",
            )}
          </p>
          <p style="margin-top: 1rem;">
            {Component.text("Modals are great for focused user interactions and confirmations.")}
          </p>
        </Modal>
      </div>

      // Switch Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Switch / Toggle")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Binary on/off switches for settings and preferences.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <Switch checked={switchEnabled} label="Enable feature" />
          <Switch checked={darkModeSwitch} label="Dark mode" size={Switch.Lg} />
          <Switch checked={notificationsSwitch} label="Push notifications" size={Switch.Sm} />
          <Switch
            checked={Signal.make(true)} label="Disabled switch" disabled={true} size={Switch.Md}
          />
        </div>
      </div>

      // Slider Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Slider")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Select a value from a range.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 2rem;">
          <Slider value={sliderValue} label="Volume" showValue={true} />
          <Slider
            value={Signal.make(25.0)}
            label="Brightness"
            min={0.0}
            max={100.0}
            step={5.0}
            showValue={true}
          />
          <Slider
            value={Signal.make(3.0)}
            min={0.0}
            max={5.0}
            step={1.0}
            label="Rating"
            showValue={true}
            markers={["0", "1", "2", "3", "4", "5"]}
          />
        </div>
      </div>

      // Tooltip Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Tooltip")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Show contextual information on hover.")}
        </p>
        <div style="display: flex; gap: 1rem; flex-wrap: wrap;">
          <Tooltip content="This appears on top" position={Tooltip.Top}>
            <Button label={Static("Hover me )(top)")} variant={Button.Secondary} />
          </Tooltip>
          <Tooltip content="This appears on bottom" position={Tooltip.Bottom}>
            <Button label={Static("Hover me )(bottom)")} variant={Button.Secondary} />
          </Tooltip>
          <Tooltip content="This appears on left" position={Tooltip.Left}>
            <Button label={Static("Hover me )(left)")} variant={Button.Secondary} />
          </Tooltip>
          <Tooltip content="This appears on right" position={Tooltip.Right}>
            <Button label={Static("Hover me )(right)")} variant={Button.Secondary} />
          </Tooltip>
        </div>
      </div>

      // Dropdown Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Dropdown Menu")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Contextual menu with actions.")}
        </p>
        <div style="display: flex; gap: 1rem;">
          <Dropdown
            trigger={<Button label={Static("Actions")} variant={Button.Secondary} />}
            items={[
              Dropdown.Item({
                label: "Edit",
                onClick: () => Console.log("Edit clicked"),
              }),
              Dropdown.Item({
                label: "Duplicate",
                onClick: () => Console.log("Duplicate clicked"),
              }),
              Dropdown.Separator,
              Dropdown.Item({
                label: "Archive",
                onClick: () => Console.log("Archive clicked"),
              }),
              Dropdown.Item({
                label: "Delete",
                onClick: () => Console.log("Delete clicked"),
                danger: true,
              }),
            ]}
          />
          <Dropdown
            trigger={<Button label={Static("More options")} variant={Button.Ghost} />}
            items={[
              Dropdown.Item({
                label: "Settings",
                onClick: () => Console.log("Settings"),
              }),
              Dropdown.Item({
                label: "Help",
                onClick: () => Console.log("Help"),
              }),
              Dropdown.Separator,
              Dropdown.Item({
                label: "Disabled item",
                onClick: () => Console.log("Should not fire"),
                disabled: true,
              }),
            ]}
            align=#right
          />
        </div>
      </div>

      // Toast Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Toast / Notification")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Temporary notification messages.")}
        </p>
        <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
          <Button
            label={Static("Show Toast")}
            onClick={_ => Signal.set(toastVisible, true)}
            variant={Button.Primary}
          />
        </div>
        <Toast
          title="Success!"
          message="Your changes have been saved successfully."
          variant={Toast.Success}
          isVisible={toastVisible}
          onClose={() => Console.log("Toast closed")}
        />
      </div>

      <Separator orientation={Separator.Horizontal} variant={Separator.Solid} label={"Tier 4"} />

      <div style="margin-top: 3rem;">
        <Typography
          text={ReactiveProp.Static("Navigation & Layout")}
          variant={Typography.H2}
          align={Typography.Left}
        />
        <Typography
          text={ReactiveProp.Static("Explore the Tier 4 navigation and layout components below.")}
          variant={Typography.Muted}
        />
      </div>

      // Stepper Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Stepper")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Multi-step process indicator with progress tracking.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 2rem;">
          <div>
            <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.875rem;">
              {Component.text("Horizontal stepper:")}
            </p>
            <Stepper
              steps={[
                {
                  title: "Account Info",
                  description: Some("Enter your details"),
                  status: Stepper.Completed,
                },
                {
                  title: "Verification",
                  description: Some("Verify your email"),
                  status: Stepper.Active,
                },
                {
                  title: "Preferences",
                  description: Some("Set your preferences"),
                  status: Stepper.Inactive,
                },
                {
                  title: "Complete",
                  description: Some("All done!"),
                  status: Stepper.Inactive,
                },
              ]}
              currentStep={currentStep}
              orientation={Stepper.Horizontal}
              onStepClick={step => {
                Signal.set(currentStep, step)
                Console.log2("Step clicked:", step)
              }}
            />
          </div>
          <div>
            <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.875rem;">
              {Component.text("Vertical stepper:")}
            </p>
            <Stepper
              steps={[
                {
                  title: "Order Placed",
                  description: Some("Your order has been confirmed"),
                  status: Stepper.Completed,
                },
                {
                  title: "Processing",
                  description: Some("We are preparing your order"),
                  status: Stepper.Completed,
                },
                {
                  title: "Shipped",
                  description: Some("Your order is on the way"),
                  status: Stepper.Active,
                },
                {
                  title: "Delivered",
                  description: Some("Enjoy your purchase!"),
                  status: Stepper.Inactive,
                },
              ]}
              currentStep={Signal.make(2)}
              orientation={Stepper.Vertical}
            />
          </div>
        </div>
      </div>

      // Drawer Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Drawer / Sidebar")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Slide-in panels for additional content.")}
        </p>
        <div style="display: flex; gap: 0.75rem; flex-wrap: wrap;">
          <Button
            label={Static("Open Drawer")}
            onClick={_ => Signal.set(isDrawerOpen, true)}
            variant={Button.Primary}
          />
        </div>
        <Drawer
          isOpen={isDrawerOpen}
          onClose={() => Signal.set(isDrawerOpen, false)}
          title="Drawer Panel"
          position={Drawer.Right}
          size={Drawer.Md}
          footer={<div style="display: flex; gap: 0.5rem; justify-content: flex-end;">
            <Button
              label={Static("Cancel")}
              onClick={_ => Signal.set(isDrawerOpen, false)}
              variant={Button.Ghost}
            />
            <Button
              label={Static("Save")}
              onClick={_ => {
                Console.log("Saved!")
                Signal.set(isDrawerOpen, false)
              }}
              variant={Button.Primary}
            />
          </div>}
        >
          <div>
            <Typography text={ReactiveProp.Static("Drawer Content")} variant={Typography.H5} />
            <p style="margin-top: 1rem;">
              {Component.text(
                "This is a drawer panel. You can use it for navigation, forms, or any additional content that doesn't fit in the main view.",
              )}
            </p>
            <div style="margin-top: 1.5rem;">
              <Label text="Name" />
              <Input value={Static("")} type_={Input.Text} placeholder="Enter your name" />
            </div>
            <div style="margin-top: 1rem;">
              <Label text="Email" />
              <Input value={Static("")} type_={Input.Email} placeholder="Enter your email" />
            </div>
            <div style="margin-top: 1rem;">
              <Label text="Message" />
              <Textarea value={ReactiveProp.Static("")} placeholder="Enter a message" />
            </div>
          </div>
        </Drawer>
      </div>

      // Timeline Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Timeline")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Display chronological events in a visual timeline.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 2rem;">
          <div>
            <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.875rem;">
              {Component.text("Vertical timeline:")}
            </p>
            <Timeline
              items={[
                {
                  title: "Project Created",
                  timestamp: Some("2 hours ago"),
                  description: Some("Initial project setup and configuration"),
                  variant: Timeline.Success,
                  icon: Some("\u2713"),
                },
                {
                  title: "First Commit",
                  timestamp: Some("1 hour ago"),
                  description: Some("Added base components and styling"),
                  variant: Timeline.Success,
                  icon: Some("\u2713"),
                },
                {
                  title: "Code Review",
                  timestamp: Some("30 minutes ago"),
                  description: Some("Team reviewing the implementation"),
                  variant: Timeline.Primary,
                  icon: None,
                },
                {
                  title: "Deployment",
                  timestamp: Some("Pending"),
                  description: Some("Awaiting approval for production deployment"),
                  variant: Timeline.Default,
                  icon: None,
                },
              ]}
              orientation={Timeline.Vertical}
            />
          </div>
          <div>
            <p style="color: #6b7280; margin-bottom: 1rem; font-size: 0.875rem;">
              {Component.text("With different variants:")}
            </p>
            <Timeline
              items={[
                {
                  title: "Success Event",
                  timestamp: None,
                  description: Some("Operation completed successfully"),
                  variant: Timeline.Success,
                  icon: Some("\u2713"),
                },
                {
                  title: "Warning Event",
                  timestamp: None,
                  description: Some("Requires attention"),
                  variant: Timeline.Warning,
                  icon: Some("!"),
                },
                {
                  title: "Error Event",
                  timestamp: None,
                  description: Some("Operation failed"),
                  variant: Timeline.Error,
                  icon: Some("\u00d7"),
                },
              ]}
              orientation={Timeline.Vertical}
            />
          </div>
        </div>
      </div>

      <Separator
        orientation={Separator.Horizontal} variant={Separator.Solid} label={"App Layouts"}
      />

      <div style="margin-top: 3rem;">
        <Typography
          text={ReactiveProp.Static("Application Layouts")}
          variant={Typography.H2}
          align={Typography.Left}
        />
        <Typography
          text={ReactiveProp.Static(
            "Complete application layout structures with sidebar and topbar combinations.",
          )}
          variant={Typography.Muted}
        />
      </div>

      // Layout Examples Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Layout Variants")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Different application layout configurations.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 2rem;">
          // Sidebar Only Example
          <div>
            <Typography text={ReactiveProp.Static("Sidebar Only Layout")} variant={Typography.H5} />
            <p style="color: #6b7280; margin: 0.5rem 0 1rem 0; font-size: 0.875rem;">
              {Component.text("Application with sidebar navigation")}
            </p>
            <div
              style="border: 2px solid #e5e7eb; border-radius: 0.5rem; overflow: hidden; height: 400px;"
            >
              <AppLayout
                sidebar={<Sidebar
                  logo={Component.text("eita UI")}
                  sections={[
                    {
                      title: Some("Main"),
                      items: [
                        {
                          label: "Dashboard",
                          icon: Some("\u2302"),
                          active: Signal.get(activeNavItem) == "home",
                          url: "/profile",
                        },
                        {
                          label: "Analytics",
                          icon: Some("\u{1F4CA}"),
                          active: Signal.get(activeNavItem) == "analytics",
                          url: "/profile",
                        },
                      ],
                    },
                    {
                      title: Some("Settings"),
                      items: [
                        {
                          label: "Profile",
                          icon: Some("\u{1F464}"),
                          active: Signal.get(activeNavItem) == "profile",
                          url: "/profile",
                        },
                        {
                          label: "Settings",
                          icon: Some("\u2699"),
                          active: Signal.get(activeNavItem) == "settings",
                          url: "/profile",
                        },
                      ],
                    },
                  ]}
                  size={Sidebar.Md}
                />}
              >
                <div style="padding: 2rem;">
                  <Typography
                    text={ReactiveProp.Static("Main Content Area")} variant={Typography.H3}
                  />
                  <p style="margin-top: 1rem;">
                    {Component.text(
                      "This is the main content area. The sidebar provides persistent navigation.",
                    )}
                  </p>
                </div>
              </AppLayout>
            </div>
          </div>

          // Topbar Only Example
          <div>
            <Typography text={ReactiveProp.Static("Topbar Only Layout")} variant={Typography.H5} />
            <p style="color: #6b7280; margin: 0.5rem 0 1rem 0; font-size: 0.875rem;">
              {Component.text("Application with top navigation bar")}
            </p>
            <div
              style="border: 2px solid #e5e7eb; border-radius: 0.5rem; overflow: hidden; height: 300px;"
            >
              <AppLayout
                topbar={<Topbar
                  logo={Component.text("eita UI")}
                  navItems={[
                    {
                      label: "Home",
                      active: Signal.get(activeNavItem) == "home",
                      onClick: () => Signal.set(activeNavItem, "home"),
                    },
                    {
                      label: "Products",
                      active: Signal.get(activeNavItem) == "products",
                      onClick: () => Signal.set(activeNavItem, "products"),
                    },
                    {
                      label: "About",
                      active: Signal.get(activeNavItem) == "about",
                      onClick: () => Signal.set(activeNavItem, "about"),
                    },
                  ]}
                  rightContent={<div style="display: flex; gap: 0.5rem;">
                    <Button label={Static("Sign In")} variant={Button.Ghost} />
                    <Button label={Static("Sign Up")} variant={Button.Primary} />
                  </div>}
                />}
              >
                <div style="padding: 2rem;">
                  <Typography
                    text={ReactiveProp.Static("Main Content Area")} variant={Typography.H3}
                  />
                  <p style="margin-top: 1rem;">
                    {Component.text("This layout uses only a top navigation bar.")}
                  </p>
                </div>
              </AppLayout>
            </div>
          </div>

          // Sidebar + Topbar Example
          <div>
            <Typography
              text={ReactiveProp.Static("Sidebar + Topbar Layout")} variant={Typography.H5}
            />
            <p style="color: #6b7280; margin: 0.5rem 0 1rem 0; font-size: 0.875rem;">
              {Component.text("Full application layout with both sidebar and topbar")}
            </p>
            <div
              style="border: 2px solid #e5e7eb; border-radius: 0.5rem; overflow: hidden; height: 500px;"
            >
              <AppLayout
                sidebar={<Sidebar
                  logo={Component.text("basefn")}
                  sections={[
                    {
                      title: Some("Navigation"),
                      items: [
                        {
                          label: "Dashboard",
                          icon: Some("\u2302"),
                          active: true,
                          url: "/",
                        },
                        {
                          label: "Projects",
                          icon: Some("\u{1F4C1}"),
                          active: false,
                          url: "/",
                        },
                        {
                          label: "Tasks",
                          icon: Some("\u2713"),
                          active: false,
                          url: "/",
                        },
                      ],
                    },
                  ]}
                  size={Sidebar.Md}
                  collapsed={Signal.get(sidebarCollapsed)}
                />}
                topbar={<Topbar
                  onMenuClick={() => Signal.update(sidebarCollapsed, prev => !prev)}
                  rightContent={<div style="display: flex; align-items: center; gap: 1rem;">
                    <Badge label={Signal.make("3")} variant={Badge.Primary} />
                    <Avatar src="https://ui-avatars.com/api/?name=John+Doe" size={Avatar.Sm} />
                  </div>}
                />}
                sidebarSize={"md"}
                sidebarCollapsed={Signal.get(sidebarCollapsed)}
              >
                <div style="padding: 2rem;">
                  <Typography text={ReactiveProp.Static("Dashboard")} variant={Typography.H3} />
                  <p style="margin-top: 1rem;">
                    {Component.text(
                      "This is a complete application layout with both sidebar and topbar. Click the menu button in the topbar to toggle the sidebar.",
                    )}
                  </p>
                  <div
                    style="margin-top: 2rem; display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1rem;"
                  >
                    <Card>
                      <Typography
                        text={ReactiveProp.Static("Total Users")} variant={Typography.H6}
                      />
                      <Typography
                        text={ReactiveProp.Static("1,234")}
                        variant={Typography.H2}
                        class="text-primary"
                      />
                    </Card>
                    <Card>
                      <Typography
                        text={ReactiveProp.Static("Active Projects")} variant={Typography.H6}
                      />
                      <Typography text={ReactiveProp.Static("45")} variant={Typography.H2} />
                    </Card>
                    <Card>
                      <Typography
                        text={ReactiveProp.Static("Completed Tasks")} variant={Typography.H6}
                      />
                      <Typography text={ReactiveProp.Static("892")} variant={Typography.H2} />
                    </Card>
                  </div>
                </div>
              </AppLayout>
            </div>
          </div>
        </div>
      </div>

      <Separator
        orientation={Separator.Horizontal} variant={Separator.Dashed} label={"Foundational"}
      />

      <div style="margin-top: 3rem;">
        <Typography
          text={ReactiveProp.Static("Foundation Components")}
          variant={Typography.H2}
          align={Typography.Left}
        />
        <Typography
          text={ReactiveProp.Static("Explore the Tier 1 foundation components below.")}
          variant={Typography.Muted}
        />
      </div>

      // Badges Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Badges")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Display status indicators and labels with various styles.")}
        </p>
        <div style="display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: center;">
          <Badge label={Signal.make("Default")} variant={Badge.Default} />
          <Badge label={Signal.make("Primary")} variant={Badge.Primary} />
          <Badge label={Signal.make("Secondary")} variant={Badge.Secondary} />
          <Badge label={Signal.make("Success")} variant={Badge.Success} />
          <Badge label={Signal.make("Warning")} variant={Badge.Warning} />
          <Badge label={Signal.make("Error")} variant={Badge.Error} />
        </div>
        <div
          style="display: flex; gap: 0.75rem; flex-wrap: wrap; align-items: center; margin-top: 1rem;"
        >
          <Badge label={Signal.make("Small")} variant={Badge.Primary} size={Badge.Sm} />
          <Badge label={Signal.make("Medium")} variant={Badge.Primary} size={Badge.Md} />
          <Badge label={Signal.make("Large")} variant={Badge.Primary} size={Badge.Lg} />
          <Badge label={Signal.make("Online")} variant={Badge.Success} dot={true} />
          <Badge label={Signal.make("Away")} variant={Badge.Warning} dot={true} />
        </div>
      </div>

      <Separator orientation={Separator.Horizontal} variant={Separator.Dashed} label={"Spinners"} />

      // Spinners Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Spinners")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Loading indicators in different sizes and colors.")}
        </p>
        <div style="display: flex; gap: 2rem; flex-wrap: wrap; align-items: center;">
          <Spinner size={Spinner.Sm} variant={Spinner.Default} />
          <Spinner size={Spinner.Md} variant={Spinner.Primary} />
          <Spinner size={Spinner.Lg} variant={Spinner.Secondary} />
          <Spinner size={Spinner.Xl} variant={Spinner.Primary} />
        </div>
        <div style="display: flex; gap: 2rem; flex-wrap: wrap; margin-top: 1.5rem;">
          <Spinner size={Spinner.Md} variant={Spinner.Primary} label="Loading..." />
          <Spinner
            size={Spinner.Lg}
            variant={Spinner.Default}
            label={Signal.get(isSubmitting) ? "Submitting..." : "Ready"}
          />
        </div>
      </div>

      <Separator orientation={Separator.Horizontal} variant={Separator.Dotted} />

      // Keyboard Shortcuts Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Keyboard Shortcuts")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Display keyboard shortcuts in a visually appealing way.")}
        </p>
        <div style="display: flex; gap: 1.5rem; flex-wrap: wrap; align-items: center;">
          <div>
            <span style="color: #6b7280; margin-right: 0.5rem;"> {Component.text("Copy:")} </span>
            <Kbd keys={Signal.make(["Ctrl", "C"])} size={Kbd.Md} />
          </div>
          <div>
            <span style="color: #6b7280; margin-right: 0.5rem;"> {Component.text("Paste:")} </span>
            <Kbd keys={Signal.make(["Ctrl", "V"])} size={Kbd.Md} />
          </div>
          <div>
            <span style="color: #6b7280; margin-right: 0.5rem;"> {Component.text("Save:")} </span>
            <Kbd keys={Signal.make(["Ctrl", "S"])} size={Kbd.Md} />
          </div>
          <div>
            <span style="color: #6b7280; margin-right: 0.5rem;">
              {Component.text("Select All:")}
            </span>
            <Kbd keys={Signal.make(["Ctrl", "A"])} size={Kbd.Md} />
          </div>
        </div>
        <div style="margin-top: 1rem;">
          <Kbd keys={Signal.make(["Shift", "Alt", "F"])} size={Kbd.Sm} />
          <span style="color: #6b7280; margin-left: 0.5rem;">
            {Component.text("Format Document")}
          </span>
        </div>
      </div>

      <Separator orientation={Separator.Horizontal} variant={Separator.Solid} />

      // Typography Section
      <div style="margin-top: 2rem;">
        <Typography text={ReactiveProp.Static("Typography")} variant={Typography.H4} />
        <p style="color: #6b7280; margin: 0.5rem 0 1rem 0;">
          {Component.text("Consistent text styling across your application.")}
        </p>
        <div style="display: flex; flex-direction: column; gap: 1rem;">
          <Typography text={ReactiveProp.Static("Heading 1")} variant={Typography.H1} />
          <Typography text={ReactiveProp.Static("Heading 2")} variant={Typography.H2} />
          <Typography text={ReactiveProp.Static("Heading 3")} variant={Typography.H3} />
          <Typography text={ReactiveProp.Static("Heading 4")} variant={Typography.H4} />
          <Typography text={ReactiveProp.Static("Heading 5")} variant={Typography.H5} />
          <Typography text={ReactiveProp.Static("Heading 6")} variant={Typography.H6} />
          <Separator orientation={Separator.Horizontal} variant={Separator.Dashed} />
          <Typography
            text={ReactiveProp.Static(
              "This is a regular paragraph with normal text styling and comfortable line height.",
            )}
            variant={Typography.P}
          />
          <Typography
            text={ReactiveProp.Static(
              "This is a lead paragraph that stands out with larger text and is perfect for introductions.",
            )}
            variant={Typography.Lead}
          />
          <Typography
            text={ReactiveProp.Static("This is small text, useful for captions and helper text.")}
            variant={Typography.Small}
          />
          <Typography
            text={ReactiveProp.Static("This is muted text with reduced emphasis.")}
            variant={Typography.Muted}
          />
          <Typography
            text={ReactiveProp.Static("const hello = 'world'")} variant={Typography.Code}
          />
        </div>
      </div>

      <div
        style="margin-top: 3rem; padding: 1rem; background-color: #f3f4f6; border-radius: 0.5rem;"
      >
        <h3 style="margin-top: 0; color: #374151;"> {Component.text("Form State (Real-time)")} </h3>
        <pre
          style="background-color: #1f2937; color: #f9fafb; padding: 1rem; border-radius: 0.25rem; overflow-x: auto; font-size: 0.875rem;"
        >
          {Component.textSignal(() => {
            `Name: ${Signal.get(name)}
Email: ${Signal.get(email)}
Password: ${"*"->String.repeat(Signal.get(password)->String.length)}
Interest: ${Signal.get(selectedOption)}
Color: ${Signal.get(selectedColor)}
Message: ${Signal.get(message)->String.slice(~start=0, ~end=50)}${Signal.get(
                message,
              )->String.length > 50
                ? "..."
                : ""}
Terms: ${Signal.get(agreeToTerms)->Bool.toString}
Newsletter: ${Signal.get(newsletter)->Bool.toString}`
          })}
        </pre>
      </div>
    </>
  }
}

// Mount the demo application
Component.mountById(<Demo />, "root")
