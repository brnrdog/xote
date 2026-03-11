%%raw(`import "./Basefn__Grid.css"`)

open Xote

// Grid template types
type columns =
  | Count(int) // Simple column count (e.g., 3 columns)
  | Template(string) // Custom template (e.g., "1fr 2fr 1fr")
  | Repeat(int, string) // Repeat pattern (e.g., Repeat(3, "1fr"))
  | AutoFit(string) // Auto-fit with min size (e.g., AutoFit("minmax(200px, 1fr)"))
  | AutoFill(string) // Auto-fill with min size

type rows =
  | Count(int)
  | Template(string)
  | Repeat(int, string)
  | Auto // Auto rows

// Auto flow direction
type autoFlow =
  | Row
  | Column
  | RowDense
  | ColumnDense

// Alignment options
type justifyItems =
  | Start
  | End
  | Center
  | Stretch

type alignItems =
  | Start
  | End
  | Center
  | Stretch
  | Baseline

type justifyContent =
  | Start
  | End
  | Center
  | Stretch
  | SpaceBetween
  | SpaceAround
  | SpaceEvenly

type alignContent =
  | Start
  | End
  | Center
  | Stretch
  | SpaceBetween
  | SpaceAround
  | SpaceEvenly

// Convert types to CSS values
let columnsToString = (cols: columns): string => {
  switch cols {
  | Count(n) => "repeat(" ++ Int.toString(n) ++ ", 1fr)"
  | Template(t) => t
  | Repeat(n, pattern) => "repeat(" ++ Int.toString(n) ++ ", " ++ pattern ++ ")"
  | AutoFit(minmax) => "repeat(auto-fit, " ++ minmax ++ ")"
  | AutoFill(minmax) => "repeat(auto-fill, " ++ minmax ++ ")"
  }
}

let rowsToString = (rows: rows): string => {
  switch rows {
  | Count(n) => "repeat(" ++ Int.toString(n) ++ ", auto)"
  | Template(t) => t
  | Repeat(n, pattern) => "repeat(" ++ Int.toString(n) ++ ", " ++ pattern ++ ")"
  | Auto => "auto"
  }
}

let autoFlowToString = (flow: autoFlow): string => {
  switch flow {
  | Row => "row"
  | Column => "column"
  | RowDense => "row dense"
  | ColumnDense => "column dense"
  }
}

let justifyItemsToString = (justify: justifyItems): string => {
  switch justify {
  | Start => "start"
  | End => "end"
  | Center => "center"
  | Stretch => "stretch"
  }
}

let alignItemsToString = (align: alignItems): string => {
  switch align {
  | Start => "start"
  | End => "end"
  | Center => "center"
  | Stretch => "stretch"
  | Baseline => "baseline"
  }
}

let justifyContentToString = (justify: justifyContent): string => {
  switch justify {
  | Start => "start"
  | End => "end"
  | Center => "center"
  | Stretch => "stretch"
  | SpaceBetween => "space-between"
  | SpaceAround => "space-around"
  | SpaceEvenly => "space-evenly"
  }
}

let alignContentToString = (align: alignContent): string => {
  switch align {
  | Start => "start"
  | End => "end"
  | Center => "center"
  | Stretch => "stretch"
  | SpaceBetween => "space-between"
  | SpaceAround => "space-around"
  | SpaceEvenly => "space-evenly"
  }
}

@jsx.component
let make = (
  ~columns: columns=Count(1),
  ~rows: option<rows>=?,
  ~gap: option<string>=?,
  ~rowGap: option<string>=?,
  ~columnGap: option<string>=?,
  ~autoFlow: option<autoFlow>=?,
  ~justifyItems: option<justifyItems>=?,
  ~alignItems: option<alignItems>=?,
  ~justifyContent: option<justifyContent>=?,
  ~alignContent: option<alignContent>=?,
  ~class=ReactiveProp.static(""),
  ~style=ReactiveProp.static(""),
  ~children,
) => {
  let className = Computed.make(() => {
    "basefn-grid " ++ class->ReactiveProp.get
  })

  let gridStyle = Computed.make(() => {
    let styles = []

    // Template columns (required)
    styles->Array.push("grid-template-columns: " ++ columnsToString(columns))

    // Template rows (optional)
    switch rows {
    | Some(r) => styles->Array.push("grid-template-rows: " ++ rowsToString(r))
    | None => ()
    }

    // Gap (can use single gap or separate row/column gaps)
    switch (gap, rowGap, columnGap) {
    | (Some(g), None, None) => styles->Array.push("gap: " ++ g)
    | (None, Some(rg), Some(cg)) => {
        styles->Array.push("row-gap: " ++ rg)
        styles->Array.push("column-gap: " ++ cg)
      }
    | (None, Some(rg), None) => styles->Array.push("row-gap: " ++ rg)
    | (None, None, Some(cg)) => styles->Array.push("column-gap: " ++ cg)
    | _ => () // Default gap from CSS
    }

    // Auto flow
    switch autoFlow {
    | Some(flow) => styles->Array.push("grid-auto-flow: " ++ autoFlowToString(flow))
    | None => ()
    }

    // Justify items
    switch justifyItems {
    | Some(justify) => styles->Array.push("justify-items: " ++ justifyItemsToString(justify))
    | None => ()
    }

    // Align items
    switch alignItems {
    | Some(align) => styles->Array.push("align-items: " ++ alignItemsToString(align))
    | None => ()
    }

    // Justify content
    switch justifyContent {
    | Some(justify) => styles->Array.push("justify-content: " ++ justifyContentToString(justify))
    | None => ()
    }

    // Align content
    switch alignContent {
    | Some(align) => styles->Array.push("align-content: " ++ alignContentToString(align))
    | None => ()
    }

    // Add custom styles
    let customStyle = style->ReactiveProp.get
    if customStyle !== "" {
      styles->Array.push(customStyle)
    }

    styles->Array.join("; ")
  })

  <div class={className} style={gridStyle}> {children} </div>
}

// Grid Item component for children that need custom placement
module Item = {
  type columnSpan =
    | Span(int)
    | StartEnd(int, int)
    | Auto

  type rowSpan =
    | Span(int)
    | StartEnd(int, int)
    | Auto

  let columnSpanToString = (span: columnSpan): string => {
    switch span {
    | Span(n) => "span " ++ Int.toString(n)
    | StartEnd(start, end) => Int.toString(start) ++ " / " ++ Int.toString(end)
    | Auto => "auto"
    }
  }

  let rowSpanToString = (span: rowSpan): string => {
    switch span {
    | Span(n) => "span " ++ Int.toString(n)
    | StartEnd(start, end) => Int.toString(start) ++ " / " ++ Int.toString(end)
    | Auto => "auto"
    }
  }

  @jsx.component
  let make = (
    ~column: option<columnSpan>=?,
    ~row: option<rowSpan>=?,
    ~justifySelf: option<justifyItems>=?,
    ~alignSelf: option<alignItems>=?,
    ~class=ReactiveProp.static(""),
    ~style=ReactiveProp.static(""),
    ~children,
  ) => {
    let className = Computed.make(() => {
      "basefn-grid-item " ++ class->ReactiveProp.get
    })

    let itemStyle = Computed.make(() => {
      let styles = []

      // Column placement
      switch column {
      | Some(col) => styles->Array.push("grid-column: " ++ columnSpanToString(col))
      | None => ()
      }

      // Row placement
      switch row {
      | Some(r) => styles->Array.push("grid-row: " ++ rowSpanToString(r))
      | None => ()
      }

      // Justify self
      switch justifySelf {
      | Some(justify) => styles->Array.push("justify-self: " ++ justifyItemsToString(justify))
      | None => ()
      }

      // Align self
      switch alignSelf {
      | Some(align) => styles->Array.push("align-self: " ++ alignItemsToString(align))
      | None => ()
      }

      // Add custom styles
      let customStyle = style->ReactiveProp.get
      if customStyle !== "" {
        styles->Array.push(customStyle)
      }

      styles->Array.join("; ")
    })

    <div class={className} style={itemStyle}> {children} </div>
  }
}
