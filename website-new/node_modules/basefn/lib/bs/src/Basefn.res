%%raw(`import './basefn.css'`)
// Main basefn UI module - exposes all components and utilities

// Re-export component types
type selectOption = Basefn__Select.selectOption
type inputType = Basefn__Input.inputType
type buttonVariant = Basefn__Button.variant
type badgeVariant = Basefn__Badge.variant
type badgeSize = Basefn__Badge.size
type spinnerSize = Basefn__Spinner.size
type spinnerVariant = Basefn__Spinner.variant
type separatorOrientation = Basefn__Separator.orientation
type separatorVariant = Basefn__Separator.variant
type kbdSize = Basefn__Kbd.size
type typographyVariant = Basefn__Typography.variant
type typographyAlign = Basefn__Typography.align
type alertVariant = Basefn__Alert.variant
type progressSize = Basefn__Progress.size
type progressVariant = Basefn__Progress.variant
type tab = Basefn__Tabs.tab
type accordionItem = Basefn__Accordion.accordionItem
type breadcrumbItem = Basefn__Breadcrumb.breadcrumbItem
type modalSize = Basefn__Modal.size
type tooltipPosition = Basefn__Tooltip.position
type switchSize = Basefn__Switch.size
type dropdownMenuItem = Basefn__Dropdown.menuItem
type dropdownMenuContent = Basefn__Dropdown.menuContent
type toastVariant = Basefn__Toast.variant
type toastPosition = Basefn__Toast.position
type stepperOrientation = Basefn__Stepper.orientation
type stepStatus = Basefn__Stepper.stepStatus
type stepperStep = Basefn__Stepper.step
type drawerPosition = Basefn__Drawer.position
type drawerSize = Basefn__Drawer.size
type timelineOrientation = Basefn__Timeline.orientation
type timelineVariant = Basefn__Timeline.variant
type timelineItem = Basefn__Timeline.timelineItem
type sidebarSize = Basefn__Sidebar.size
type sidebarNavItem = Basefn__Sidebar.navItem
type sidebarNavSection = Basefn__Sidebar.navSection
type topbarSize = Basefn__Topbar.size
type topbarNavItem = Basefn__Topbar.navItem
type appLayoutContentWidth = Basefn__AppLayout.contentWidth
type appLayoutTopbarPosition = Basefn__AppLayout.topbarPosition
type iconName = Basefn__Icon.name
type iconSize = Basefn__Icon.size
type skeletonVariant = Basefn__Skeleton.variant
type skeletonAnimation = Basefn__Skeleton.animation
type scrollAreaOrientation = Basefn__ScrollArea.orientation
type scrollAreaScrollbarSize = Basefn__ScrollArea.scrollbarSize
type toggleVariant = Basefn__Toggle.variant
type toggleSize = Basefn__Toggle.size
type buttonGroupOrientation = Basefn__ButtonGroup.orientation
type toggleGroupSelectionType = Basefn__ToggleGroup.selectionType
type toggleGroupItem = Basefn__ToggleGroup.toggleItem
type toggleGroupVariant = Basefn__ToggleGroup.variant
type toggleGroupSize = Basefn__ToggleGroup.size
type popoverPosition = Basefn__Popover.position
type popoverAlign = Basefn__Popover.align
type hoverCardPosition = Basefn__HoverCard.position
type hoverCardAlign = Basefn__HoverCard.align
type alertDialogVariant = Basefn__AlertDialog.variant
type contextMenuItem = Basefn__ContextMenu.menuItem
type contextMenuContent = Basefn__ContextMenu.menuContent
type spotlightItem = Basefn__Spotlight.spotlightItem
type gridColumns = Basefn__Grid.columns
type gridRows = Basefn__Grid.rows
type gridAutoFlow = Basefn__Grid.autoFlow
type gridJustifyItems = Basefn__Grid.justifyItems
type gridAlignItems = Basefn__Grid.alignItems
type gridJustifyContent = Basefn__Grid.justifyContent
type gridAlignContent = Basefn__Grid.alignContent
type gridItemColumnSpan = Basefn__Grid.Item.columnSpan
type gridItemRowSpan = Basefn__Grid.Item.rowSpan
type breakpoint = Basefn__Responsive.breakpoint
type currentBreakpoint = Basefn__Responsive.currentBreakpoint
type responsiveValue<'a> = Basefn__Responsive.responsiveValue<'a>

// Form Components
module Button = {
  include Basefn__Button
}
module Input = {
  include Basefn__Input
}
module Textarea = {
  include Basefn__Textarea
}
module Select = {
  include Basefn__Select
}
module Checkbox = {
  include Basefn__Checkbox
}
module Radio = {
  include Basefn__Radio
}
module Label = {
  include Basefn__Label
}

// Tier 1 Foundation Components
module Badge = {
  include Basefn__Badge
}
module Spinner = {
  include Basefn__Spinner
}
module Separator = {
  include Basefn__Separator
}
module Kbd = {
  include Basefn__Kbd
}
module Typography = {
  include Basefn__Typography
}

// Tier 2
module Card = {
  include Basefn__Card
}
module Avatar = {
  include Basefn__Avatar
}
module Grid = {
  include Basefn__Grid
}
module Alert = {
  include Basefn__Alert
}
module Progress = {
  include Basefn__Progress
}
module Tabs = {
  include Basefn__Tabs
}
module Accordion = {
  include Basefn__Accordion
}
module Breadcrumb = {
  include Basefn__Breadcrumb
}

// Tier 3
module Modal = {
  include Basefn__Modal
}
module Tooltip = {
  include Basefn__Tooltip
}
module Switch = {
  include Basefn__Switch
}
module Slider = {
  include Basefn__Slider
}
module Dropdown = {
  include Basefn__Dropdown
}
module Toast = {
  include Basefn__Toast
}

// Tier 4 - Navigation & Layout
module Stepper = {
  include Basefn__Stepper
}
module Drawer = {
  include Basefn__Drawer
}
module Timeline = {
  include Basefn__Timeline
}

// Application Layout
module Sidebar = {
  include Basefn__Sidebar
}
module Topbar = {
  include Basefn__Topbar
}
module AppLayout = {
  include Basefn__AppLayout
}

// Theme
module Theme = {
  include Basefn__Theme
}
module ThemeToggle = {
  include Basefn__ThemeToggle
}

// Icons
module Icon = {
  include Basefn__Icon
}

// New shadcn-style components
module Skeleton = {
  include Basefn__Skeleton
}
module AspectRatio = {
  include Basefn__AspectRatio
}
module ScrollArea = {
  include Basefn__ScrollArea
}
module Toggle = {
  include Basefn__Toggle
}
module ButtonGroup = {
  include Basefn__ButtonGroup
}
module ToggleGroup = {
  include Basefn__ToggleGroup
}
module Popover = {
  include Basefn__Popover
}
module HoverCard = {
  include Basefn__HoverCard
}
module AlertDialog = {
  include Basefn__AlertDialog
}
module ContextMenu = {
  include Basefn__ContextMenu
}
module Spotlight = {
  include Basefn__Spotlight
}

// Responsive Utilities
module Responsive = {
  include Basefn__Responsive
}
