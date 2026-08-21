(* The vendored OCaml 4.06 parsetree lives in `ast.ml`, kept verbatim from the
   compiler so `Marshal` round-trips exactly and a future AST re-sync stays a
   copy rather than a merge. Everything in this file is the project's own code. *)
open Ast
(* ---- @xote.component fine-grained rewriter ------------------------------
   Decomposes the JSX returned by an @xote.component into fine-grained reactive
   leaves instead of wrapping the whole block in one computed:

     - an attribute value that reads a Signal  ->  thunked, so JSX lowers it
       to `View.computedAttr` (only that attribute re-runs);
     - a <View.Text>/<View.Int>/<View.Float>/<View.Bool> child that reads a
       Signal  ->  thunked, so it lowers to a reactive text node (only that
       text node re-runs);
     - genuine control flow in *node position* (an `if`/`switch` producing
       nodes) whose result varies  ->  wrapped in `View.tracked`, the one
       place a structural swap is unavoidable.

   The element structure itself (tags, nesting) is emitted once and never
   rebuilt. Only the leaves that actually read signals become reactive. *)
open Asttypes
open Parsetree

let none : Location.t =
  { Location.loc_start = Lexing.dummy_pos; loc_end = Lexing.dummy_pos; loc_ghost = true }
let mkloc (txt : 'a) : 'a Location.loc = { Location.txt; loc = none }
let mkexp d = { pexp_desc = d; pexp_loc = none; pexp_attributes = [] }
let ident lid = mkexp (Pexp_ident (mkloc lid))
let apply f args = mkexp (Pexp_apply (f, List.map (fun a -> (Nolabel, a)) args))

(* Uncurried unit thunk: `Function$(fun () -> body)` with `res.arity 1`, the
   4.06-ppx encoding ReScript uses for uncurried funcs (see PR #34). A bare
   Pexp_fun would import as curried and be rejected in uncurried-by-default. *)
let res_arity n : attribute =
  let e = mkexp (Pexp_constant (Pconst_integer (string_of_int n, None))) in
  (mkloc "res.arity", PStr [ { pstr_desc = Pstr_eval (e, []); pstr_loc = none } ])
let unit_pat =
  { ppat_desc = Ppat_construct (mkloc (Longident.Lident "()"), None);
    ppat_loc = none; ppat_attributes = [] }
let thunk body =
  let fn = mkexp (Pexp_fun (Nolabel, None, unit_pat, body)) in
  { pexp_desc = Pexp_construct (mkloc (Longident.Lident "Function$"), Some fn);
    pexp_loc = none; pexp_attributes = [ res_arity 1 ] }

let view_tracked = Longident.Ldot (Longident.Lident "View", "tracked")
let wrap_tracked e = apply (ident view_tracked) [ thunk e ]

let view_child = Longident.Ldot (Longident.Lident "View", "child")
let wrap_child e = apply (ident view_child) [ e ]

(* ---- signal-read detection ----------------------------------------------
   A read is a tracked `get`: `Signal.get`, and equally `MaybeSignal.get` /
   `Prop.get` (the deprecated alias), which read through the static-or-reactive
   wrapper and subscribe just the same. Beyond the literal `Signal.get` /
   `X.MaybeSignal.get`, an alias environment threaded through the traversal also
   recognises indirect reads:
     - a value alias:    `let g = Signal.get` then `g(sig)`
     - a module alias:   `module S = Signal` then `S.get(sig)`
     - an open:          `open Signal` then a bare `get(sig)`
     - a reactive helper: `let cls = () => Signal.get(x) ? …` then `cls()` —
       a local function whose body eagerly reads a signal; calling it is a read.
     - a same-file module helper: `module Store = { let count = s => Signal.get(s) }`
       then `Store.count(s)` — collected per module while walking the structure.
   The environment is scoped by the traversal (bindings visible only after they
   appear); shadowing a name with a non-reactive binding removes it. *)
type env = {
  vals : string list;
  mods : string list;
  funcs : string list;
  (* reactive helpers reached through a same-file module, as "Store.count" *)
  qfuncs : string list;
  open_signal : bool;
}
let empty_env = { vals = []; mods = []; funcs = []; qfuncs = []; open_signal = false }

(* Modules whose `get` is a *tracked* read. `peek` is deliberately absent from
   every one of them: it is the untracked read. *)
let is_read_module_name = function
  | "Signal" | "MaybeSignal" | "Prop" -> true
  | _ -> false

let is_read_fn (env : env) (e : expression) : bool =
  match e.pexp_desc with
  | Pexp_ident { txt = Longident.Ldot (m, "get"); _ } ->
    (match m with
     | Longident.Lident name -> is_read_module_name name || List.mem name env.mods
     | Longident.Ldot (_, name) -> is_read_module_name name
     | _ -> false)
  | Pexp_ident { txt = Longident.Lident name; _ } ->
    List.mem name env.vals || (env.open_signal && name = "get")
  | _ -> false

let sub_exprs (e : expression) : expression list =
  match e.pexp_desc with
  | Pexp_apply (f, args) -> f :: List.map snd args
  | Pexp_ifthenelse (c, t, eo) -> c :: t :: (match eo with Some x -> [ x ] | None -> [])
  | Pexp_match (x, cases) | Pexp_try (x, cases) ->
    (* guards are evaluated eagerly alongside the scrutinee — a signal read in
       `| _ if Signal.get(flag) => …` must count, or the switch is never tracked *)
    x
    :: List.concat_map
         (fun c -> (match c.pc_guard with Some g -> [ g ] | None -> []) @ [ c.pc_rhs ])
         cases
  | Pexp_construct (_, Some x) -> [ x ]
  | Pexp_variant (_, Some x) -> [ x ]
  | Pexp_tuple xs | Pexp_array xs -> xs
  | Pexp_field (x, _) -> [ x ]
  | Pexp_setfield (a, _, b) -> [ a; b ]
  | Pexp_send (x, _) -> [ x ]
  | Pexp_record (fields, base) ->
    List.map snd fields @ (match base with Some b -> [ b ] | None -> [])
  | Pexp_constraint (x, _) -> [ x ]
  | Pexp_coerce (x, _, _) -> [ x ]
  | Pexp_sequence (a, b) -> [ a; b ]
  | Pexp_let (_, vbs, body) -> List.map (fun vb -> vb.pvb_expr) vbs @ [ body ]
  | Pexp_fun (_, def, _, body) -> (match def with Some d -> [ d ] | None -> []) @ [ body ]
  | Pexp_open (_, _, x) -> [ x ]
  | Pexp_assert x | Pexp_lazy x -> [ x ]
  | _ -> []

(* The map counterpart of sub_exprs: rebuild [e] with [f] applied to each
   immediate sub-expression, leaving everything else (patterns, guards,
   labels, types) untouched.

   These two look like hand-maintained duplicates and are tempting to unify —
   don't. They answer different questions, and the difference is `when` guards:

     - sub_exprs asks "what is *evaluated* when this expression runs?" Guards are,
       so they are included, which is the only reason a switch whose sole signal
       read sits in a guard gets tracked at all.
     - map_sub_exprs asks "what could be *node position*?" A guard is a boolean,
       never a node, so rewriting through it would be meaningless.

   Deriving sub_exprs from this function drops guards from read detection and
   silently un-tracks that switch. The example's `GuardSwitch` case is the
   regression test for exactly that. *)
let map_sub_exprs (f : expression -> expression) (e : expression) : expression =
  let d =
    match e.pexp_desc with
    | Pexp_apply (fn, args) -> Pexp_apply (f fn, List.map (fun (l, a) -> (l, f a)) args)
    | Pexp_ifthenelse (c, t, eo) -> Pexp_ifthenelse (f c, f t, Option.map f eo)
    | Pexp_match (x, cases) ->
      Pexp_match (f x, List.map (fun c -> { c with pc_rhs = f c.pc_rhs }) cases)
    | Pexp_try (x, cases) ->
      Pexp_try (f x, List.map (fun c -> { c with pc_rhs = f c.pc_rhs }) cases)
    | Pexp_construct (l, eo) -> Pexp_construct (l, Option.map f eo)
    | Pexp_variant (l, eo) -> Pexp_variant (l, Option.map f eo)
    | Pexp_tuple xs -> Pexp_tuple (List.map f xs)
    | Pexp_array xs -> Pexp_array (List.map f xs)
    | Pexp_field (x, l) -> Pexp_field (f x, l)
    | Pexp_setfield (a, l, b) -> Pexp_setfield (f a, l, f b)
    | Pexp_send (x, l) -> Pexp_send (f x, l)
    | Pexp_record (fields, base) ->
      Pexp_record (List.map (fun (l, v) -> (l, f v)) fields, Option.map f base)
    | Pexp_constraint (x, t) -> Pexp_constraint (f x, t)
    | Pexp_coerce (x, a, b) -> Pexp_coerce (f x, a, b)
    | Pexp_sequence (a, b) -> Pexp_sequence (f a, f b)
    | Pexp_let (r, vbs, body) ->
      Pexp_let (r, List.map (fun vb -> { vb with pvb_expr = f vb.pvb_expr }) vbs, f body)
    | Pexp_fun (l, def, p, body) -> Pexp_fun (l, Option.map f def, p, f body)
    | Pexp_open (o, l, x) -> Pexp_open (o, l, f x)
    | Pexp_assert x -> Pexp_assert (f x)
    | Pexp_lazy x -> Pexp_lazy (f x)
    | other -> other
  in
  { e with pexp_desc = d }

(* A reactive-helper *call*: `f(...)` where `f` is a local function whose body
   eagerly reads a signal (tracked in env.funcs). A *bare* `f` (passed, not
   called) is left alone — the runtime already treats a function attribute/child
   as a computed. *)
let is_reactive_call (env : env) (e : expression) : bool =
  match e.pexp_desc with
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Longident.Lident f; _ }; _ }, _) ->
    List.mem f env.funcs
  | Pexp_apply
      ({ pexp_desc = Pexp_ident { txt = Longident.Ldot (Longident.Lident m, f); _ }; _ }, _) ->
    List.mem (m ^ "." ^ f) env.qfuncs
  | _ -> false

(* An *eager* read: a `Signal.get` (or reactive-helper call) that runs when this
   expression is evaluated, not one deferred inside a nested lambda. Reads inside
   `() => …`, `Computed.make(() => …)`, `Prop.reactive(Computed.make(() => …))`,
   etc. are already reactive on their own, so a value that only reads inside a
   lambda must NOT be re-wrapped in a thunk. Stops descending at fn boundaries. *)
let rec reads_signal_eager (env : env) (e : expression) : bool =
  match e.pexp_desc with
  | Pexp_fun _ -> false
  | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some _) -> false
  | _ ->
    is_reactive_call env e || is_read_fn env e
    || List.exists (reads_signal_eager env) (sub_exprs e)

(* Does `e` denote a function whose body eagerly reads a signal? Strip the
   function's own parameters (its uncurried `Function$` wrapper and `fun`s),
   then check the immediate body — reads_signal_eager stops at any further nested
   lambda, so a helper that merely *returns* a thunk is correctly not counted. *)
let func_reads (env : env) (e : expression) : bool =
  let rec strip_params b =
    match b.pexp_desc with Pexp_fun (_, _, _, body) -> strip_params body | _ -> b
  in
  match e.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some fn) ->
    reads_signal_eager env (strip_params fn)
  | Pexp_fun _ -> reads_signal_eager env (strip_params e)
  | _ -> false

(* ---- binding collectors ------------------------------------------------- *)
(* `let g = Signal.get` binds `g` as a value alias; `let cls = () => …Signal.get…`
   binds `cls` as a reactive helper; anything else shadows away a prior binding
   of that name. *)
let collect_val_aliases (env : env) (vbs : value_binding list) : env =
  List.fold_left
    (fun env vb ->
      match vb.pvb_pat.ppat_desc with
      | Ppat_var { txt = name; _ } ->
        let drop = List.filter (fun n -> n <> name) in
        if is_read_fn env vb.pvb_expr then
          { env with vals = name :: env.vals; funcs = drop env.funcs }
        else if func_reads env vb.pvb_expr then
          { env with funcs = name :: env.funcs; vals = drop env.vals }
        else { env with vals = drop env.vals; funcs = drop env.funcs }
      | _ -> env)
    env vbs

let is_read_module (me : module_expr) : bool =
  match me.pmod_desc with
  | Pmod_ident { txt = Longident.Lident name; _ } -> is_read_module_name name
  | Pmod_ident { txt = Longident.Ldot (_, name); _ } -> is_read_module_name name
  | _ -> false

let collect_mod_alias (env : env) (name : string Location.loc) (me : module_expr) : env =
  if is_read_module me then { env with mods = name.Location.txt :: env.mods } else env

let is_read_lid = function
  | Longident.Lident name -> is_read_module_name name
  | Longident.Ldot (_, name) -> is_read_module_name name
  | _ -> false

let collect_open (env : env) (lid : Longident.t) : env =
  if is_read_lid lid then { env with open_signal = true } else env

(* ---- JSX shape helpers -------------------------------------------------- *)
let has_jsx (e : expression) : bool =
  List.exists (fun ((n : string Location.loc), _) -> n.Location.txt = "JSX") e.pexp_attributes

let jsx_parts (e : expression) =
  match e.pexp_desc with
  | Pexp_apply (f, args) when has_jsx e -> Some (f, args)
  | _ -> None

(* A JSX fragment `<>…</>` is a `::`/`[]` list carrying the JSX attribute (not a
   Pexp_apply, so jsx_parts misses it). Its children are node position. *)
let is_jsx_fragment (e : expression) : bool =
  has_jsx e
  && (match e.pexp_desc with
      | Pexp_construct ({ txt = Longident.Lident ("::" | "[]"); _ }, _) -> true
      | _ -> false)

(* Lowercase leading char => intrinsic HTML/SVG element (children are nodes). *)
let is_element (f : expression) : bool =
  match f.pexp_desc with
  | Pexp_ident { txt = Longident.Lident s; _ } ->
    String.length s > 0 && s.[0] >= 'a' && s.[0] <= 'z'
  | _ -> false

(* View.Text / View.Int / View.Float / View.Bool: children are *values*. *)
let is_value_component (f : expression) : bool =
  match f.pexp_desc with
  | Pexp_ident { txt = Longident.Ldot (Longident.Lident "View", ("Text" | "Int" | "Float" | "Bool")); _ } ->
    true
  | _ -> false

(* Does this expression contain JSX anywhere? A value that builds nodes is not a
   scalar leaf, so it is never probed for a hidden read (the JSX inside it is
   decomposed on its own). *)
let rec contains_jsx (e : expression) : bool =
  jsx_parts e <> None || is_jsx_fragment e || List.exists contains_jsx (sub_exprs e)

(* ---- hidden reads --------------------------------------------------------
   Detection is syntactic, so a read behind a call the ppx cannot see the
   definition of — `Store.waitingCount(store)` from another module, a read
   pulled out of a data structure — looks exactly like a static value and
   compiles to one. That was the single silent failure mode.

   The ppx cannot resolve such a call, but it can *tell that one is there*: an
   expression made only of constants, identifiers, field accesses, lambdas and
   structural combinations of those provably calls nothing, and anything else
   might. Leaves in the second group are wrapped in `View.probe`, which decides
   at runtime — it evaluates the expression inside a throwaway computed and
   warns, naming this source location, if the evaluation actually subscribed to
   a signal. Inert leaves are emitted untouched, so the common cases (a literal,
   a prop, `item.name`) cost nothing. *)

(* A symbolic identifier (`>`, `++`, `===`) is a ReScript primitive operator, so
   applying one is as inert as its arguments. *)
let is_operator_name (s : string) : bool =
  String.length s > 0
  && (match s.[0] with 'a' .. 'z' | 'A' .. 'Z' | '_' -> false | _ -> true)

(* Xote's and rescript-signals' own entry points never hide a tracked read: they
   build nodes (`View.text`, `Html.div`) or reactive values that carry their own
   subscription (`Computed.make`, `MaybeSignal.reactive`), and the one function
   here that *is* a read — `Signal.get`/`MaybeSignal.get` — is recognised and
   thunked before probing is ever considered. `Signal.peek` is untracked by
   design. So a call into one of them is as inert as its arguments, and probing
   it would only report node-shaped values nobody can act on. *)
let is_library_module = function
  | "View" | "Html" | "XoteJSX" | "Signal" | "Computed" | "Effect" | "MaybeSignal" | "Prop" ->
    true
  | _ -> false

let is_library_call_path (lid : Longident.t) : bool =
  match lid with
  | Longident.Ldot (Longident.Lident m, _) | Longident.Ldot (Longident.Ldot (_, m), _) ->
    is_library_module m
  | _ -> false

let rec is_inert (e : expression) : bool =
  match e.pexp_desc with
  (* Leaves; and lambdas, whose body is deferred — whatever it reads, it reads
     reactively, so the lambda itself calls nothing now. *)
  | Pexp_constant _ | Pexp_ident _ | Pexp_fun _ | Pexp_function _ | Pexp_unreachable -> true
  | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some _) -> true
  (* An application is inert only when the callee provably calls nothing of its
     own: a primitive operator, or one of Xote's own entry points. *)
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Longident.Lident op; _ }; _ }, args)
    when is_operator_name op ->
    List.for_all (fun (_, a) -> is_inert a) args
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = lid; _ }; _ }, args)
    when is_library_call_path lid ->
    List.for_all (fun (_, a) -> is_inert a) args
  (* Purely structural: inert exactly when all of its parts are. `sub_exprs`
     already enumerates those parts (`when` guards included), so deferring to it
     keeps this in step instead of re-deriving every constructor's shape here —
     one fewer hand-maintained copy of the AST layout. *)
  | Pexp_construct _ | Pexp_variant _ | Pexp_field _ | Pexp_constraint _ | Pexp_coerce _
  | Pexp_lazy _ | Pexp_tuple _ | Pexp_array _ | Pexp_record _ | Pexp_ifthenelse _
  | Pexp_match _ | Pexp_sequence _ | Pexp_let _ | Pexp_open _ ->
    List.for_all is_inert (sub_exprs e)
  (* Anything else — an ordinary call, a method send, try/assert — might reach a
     read the ppx cannot see, so it gets probed.

     This default must stay `false`. Routing it to `sub_exprs` instead would make
     any constructor missing from that function *vacuously* inert (`for_all` over
     an empty list is `true`) and switch the safety net off silently, which is
     the one direction this analysis must never fail in. *)
  | _ -> false

(* The file being rewritten, used when an expression carries no location. *)
let source_file = ref ""

let site_of (loc : Location.t) : string =
  let p = loc.Location.loc_start in
  let file =
    if p.Lexing.pos_fname = "" then !source_file else Filename.basename p.Lexing.pos_fname
  in
  let file = if file = "" then "@xote.component" else file in
  if p.Lexing.pos_lnum <= 0 then file
  else Printf.sprintf "%s:%d:%d" file p.Lexing.pos_lnum (p.Lexing.pos_cnum - p.Lexing.pos_bol + 1)

let view_probe = Longident.Ldot (Longident.Lident "View", "probe")
let str_const s = mkexp (Pexp_constant (Pconst_string (s, None)))
let wrap_probe (e : expression) : expression =
  apply (ident view_probe) [ str_const (site_of e.pexp_loc); thunk e ]

(* ---- render callbacks ----------------------------------------------------
   A prop whose value is a *function returning JSX* — `render={item => <li>…}`
   on View.For/Value/Maybe, or any user component taking a render callback.
   The lambda's body is node position, so it must be decomposed like any other
   node: without this, a bare child inside a render callback is never coerced
   and `<span> {item.name} </span>` fails to compile with "This has type:
   string". Only bodies that actually reach JSX qualify, so event handlers and
   other function props (`by={p => p.id}`, `onClick={…}`) are left alone. *)

(* The expression a block finally evaluates to (past lets/opens/sequences). *)
let rec tail_expr (e : expression) : expression =
  match e.pexp_desc with
  | Pexp_let (_, _, body) -> tail_expr body
  | Pexp_letmodule (_, _, body) -> tail_expr body
  | Pexp_open (_, _, x) -> tail_expr x
  | Pexp_sequence (_, b) -> tail_expr b
  | Pexp_constraint (x, _) -> tail_expr x
  | _ -> e

(* The body of a (possibly uncurried, possibly multi-parameter) function. *)
let rec fun_body (e : expression) : expression option =
  match e.pexp_desc with
  | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some fn) -> fun_body fn
  | Pexp_fun (_, _, _, body) ->
    (match fun_body body with Some inner -> Some inner | None -> Some body)
  | _ -> None

(* Does this expression produce JSX? Directly, or through control flow whose
   branches do — `() => if cond { <p/> } else { <span/> }` is as much a node
   producer as `() => <p/>`. *)
let rec returns_jsx (e : expression) : bool =
  let t = tail_expr e in
  if jsx_parts t <> None || is_jsx_fragment t then true
  else
    match t.pexp_desc with
    | Pexp_ifthenelse (_, a, b) ->
      returns_jsx a || (match b with Some x -> returns_jsx x | None -> false)
    | Pexp_match (_, cases) -> List.exists (fun c -> returns_jsx c.pc_rhs) cases
    | _ -> false

let is_render_callback (e : expression) : bool =
  match fun_body e with Some body -> returns_jsx body | None -> false

let is_children_label = function
  | Labelled "children" | Optional "children" -> true
  | _ -> false

let label_name = function Labelled n | Optional n -> Some n | Nolabel -> None

(* Labels that are never a reactive value leaf, so left exactly as written -
   neither thunked nor probed. An event handler is a callback, and `attrs` is
   the escape-hatch array whose entries carry their own reactivity (a signal, a
   `() => ...` thunk, `View.signalAttr`). Thunking either one produces a value
   its prop cannot hold - `array<(string, 'a)>` given a function, a
   `Dom.event => unit` given a `unit => _` - and the type error names no
   location, because the thunk the ppx emits has none. *)
let is_non_leaf_label (lbl : arg_label) : bool =
  match label_name lbl with
  | Some "attrs" -> true
  | Some n -> String.length n > 2 && n.[0] = 'o' && n.[1] = 'n' && n.[2] >= 'A' && n.[2] <= 'Z'
  | None -> false

(* A value-position expression should be thunked iff it *eagerly* reads a signal
   and isn't already JSX. Using the eager check means values that are already
   reactive on their own — a `() => …` thunk, a `Computed`, a `Prop.reactive(…)`
   — are left untouched (their reads are deferred inside a lambda), so
   @xote.component is a safe drop-in on components already written that way. *)
let should_thunk (env : env) (v : expression) : bool =
  reads_signal_eager env v && jsx_parts v = None

(* A value-position expression whose read status the ppx cannot decide: it is
   not a visible read (that is already thunked), and it is not provably
   call-free either. `View.probe` settles it at runtime. Node-shaped values are
   excluded — they are decomposed, not read. *)
let should_probe (env : env) (v : expression) : bool =
  (not (should_thunk env v)) && (not (is_inert v)) && not (contains_jsx v)

(* A value-position leaf: thunk a visible read, probe an unresolvable call,
   leave everything else exactly as written. *)
let leaf_value (env : env) (v : expression) : expression =
  if should_thunk env v then thunk v else if should_probe env v then wrap_probe v else v

(* `@xote.component` is the single annotation: it derives props exactly like
   `@jsx.component` (which we emit for the JSX transform to expand) *and*
   fine-grained-decomposes the returned JSX. One attribute replaces
   `@jsx.component` and makes the whole component tracked. *)
let is_xote_component ((name, _) : attribute) = name.Location.txt = "xote.component"
let strip_xote_component = List.filter (fun a -> not (is_xote_component a))
let jsx_component_attr : attribute = (mkloc "jsx.component", PStr [])

(* ---- decomposition ------------------------------------------------------ *)
let rec fine_node (env : env) (e : expression) : expression =
  match jsx_parts e with
  | Some (f, args) when is_value_component f ->
    { e with pexp_desc = Pexp_apply (f, List.map (value_arg env) args) }
  | Some (f, args) when is_element f ->
    (* intrinsic HTML/SVG element: attrs are value position (thunked when they
       eagerly read a signal, so they lower to computed attributes), children
       are node position *)
    { e with pexp_desc = Pexp_apply (f, List.map (element_arg env) args) }
  | Some (f, args) ->
    (* user component: children are node position, but its labelled props land
       in the component's *typed props record*, so thunking them would change
       their type and break compilation with a baffling error *)
    { e with pexp_desc = Pexp_apply (f, List.map (component_arg env) args) }
  | None when is_jsx_fragment e ->
    (* A fragment `<>…</>` is a JSX-tagged `::`/`[]` list, not a Pexp_apply, so
       jsx_parts misses it. Recurse fine_node into each child exactly like an
       element's children (map_children preserves the outer @JSX attribute), so
       nested reactive regions stay *independent*. Without this the whole fragment
       would be wrapped in one coarse thunk and any nested `if`/`switch` inside it
       would collapse into that single tracked scope — rebuilding every sibling on
       one signal change. *)
    map_children (fine_node env) e
  | None ->
    (match e.pexp_desc with
     | Pexp_ifthenelse _ | Pexp_match _ ->
       (* Control flow in node position: the *node structure* varies, which needs
          View.tracked. First recurse fine-grained into each branch body: that
          turns the branches' leaves into thunks, so when the tracked scope runs
          a branch to build its nodes the thunks are not invoked — the scope ends
          up tracking only the condition/scrutinee (the eager reads), while a leaf
          inside a branch keeps its own reactive scope. Net effect: changing a
          signal that only a branch leaf reads updates just that leaf and does NOT
          re-run the switch or rebuild the branch.

          The *eager* read check matters here too: a control-flow child that is
          already reactive on its own reads only inside a lambda, so it is left
          as-is rather than redundantly wrapped.

          A condition with no eager read needs no View.tracked — its structure
          cannot change — but its branches are still node position and must be
          decomposed all the same. Skipping them (as this did) meant a bare
          child inside a statically-conditioned branch never reached
          View.child, so `{if isActive { <b> {"yes"} </b> } else { … }}` failed
          to compile with "This has type: string" pointing at the literal
          rather than at the conditional. Conditioning on a plain bool (a prop,
          a local) is ordinary UI code, so this path matters as much as the
          reactive one. *)
       let branches = decompose_branches env e in
       if reads_signal_eager env e then wrap_tracked branches
       else
         (* No visible read, so no `View.tracked`. If the condition/scrutinee is
            not provably call-free, the structure may in fact depend on a signal
            the ppx cannot see; probe it so that failure is reported instead of
            silently rendering one frozen branch. *)
         probe_condition env branches
     | _ ->
       (match thread_binding env fine_node e with
        (* A block expression in node position — `{let x = …; <span/>}`. The tail
           is the node; recursing into it keeps the JSX inside fine-grained
           instead of collapsing the whole block into one coarse View.child thunk
           (which would rebuild the subtree, and lose element identity, on every
           dependency change). *)
        | Some threaded -> threaded
        | None ->
       (* A bare value child — `<div>{Signal.get(count)}</div>` — with no explicit
          <View.Int>/<View.Text> wrapper. Coerce it to a node with View.child:
          an eager signal read is thunked so it re-runs as reactive text; a static
          scalar becomes static text; a value that is already a node passes through
          untouched (View.child detects nodes at runtime). This removes the value-
          primitive ceremony under the annotation.

          Whatever else the expression is — an application, a pipe, an array,
          a `try`, a record — it can still *contain* JSX, and any JSX it
          contains is node position too. So descend first (see
          decompose_node_shaped), then coerce the result. *)
          let e = decompose_node_shaped env e in
          wrap_child (leaf_value env e)))

(* The binding forms a node-position expression can be wrapped in. Each threads
   the alias environment into its body and hands that body to [recurse]; the
   parts that are *not* node position — a sequenced statement, a bound value —
   go through the ordinary traversal instead. Returns None if [e] is not one.

   `fine_node` and `decompose_component_body` walk exactly these five wrappers
   with different destinations, and had a hand-written copy each. Adding a
   binding form to one and not the other is the same drift that left
   container-bound JSX unreached, so they share one list. *)
and thread_binding (env : env) (recurse : env -> expression -> expression) (e : expression)
    : expression option =
  match e.pexp_desc with
  | Pexp_let (r, vbs, body) ->
    let vbs' = List.map (map_local_vb env) vbs in
    let env' = collect_val_aliases env vbs in
    Some { e with pexp_desc = Pexp_let (r, vbs', recurse env' body) }
  | Pexp_letmodule (name, me, body) ->
    let env' = collect_mod_alias env name me in
    Some { e with pexp_desc = Pexp_letmodule (name, me, recurse env' body) }
  | Pexp_open (o, l, x) ->
    let env' = collect_open env l.Location.txt in
    Some { e with pexp_desc = Pexp_open (o, l, recurse env' x) }
  | Pexp_sequence (a, b) ->
    Some { e with pexp_desc = Pexp_sequence (map_expr env a, recurse env b) }
  | Pexp_constraint (x, t) -> Some { e with pexp_desc = Pexp_constraint (recurse env x, t) }
  | _ -> None

(* Descend through a node-position expression that is not itself JSX, and
   decompose the node-shaped things inside it: JSX, and functions returning
   JSX. Everything else is rebuilt unchanged.

   This is deliberately shape-agnostic. Special-casing containers (application
   arguments, then arrays, then …) kept missing one: `View.fragment([<p/>])`,
   `xs->Array.map(x => <li> {x} </li>)`, `opt->Option.getOr(<p/>)` and
   `try { <p/> } catch { … }` are all just JSX sitting somewhere inside an
   expression whose value becomes a node. Walking the whole expression covers
   them uniformly, and covers shapes nobody has written yet. *)
and decompose_node_shaped (env : env) (e : expression) : expression =
  map_sub_exprs (decompose_here env) e

(* Decompose one expression *in place*, whatever shape it happens to be: JSX is
   fine-grained, a function returning JSX is entered through its parameters, and
   anything else is descended into on the chance it holds JSX further down.

   Both callers need exactly this trio — `decompose_node_shaped` applies it to
   every sub-expression, `map_local_vb` applies it to a binding's value — and
   they had drifted apart once already, which is how container-bound JSX
   (`let rows = [<li/>]`) went unreached. Naming it keeps them in step.

   `component_arg` deliberately does *not* use this: a user-component prop that
   is not node-shaped is left exactly as written, rather than descended into. *)
and decompose_here (env : env) (e : expression) : expression =
  if jsx_parts e <> None || is_jsx_fragment e then fine_node env e
  else if is_render_callback e then fine_callback env e
  else decompose_node_shaped env e

(* Wrap the condition/scrutinee (and any `when` guards) of an *untracked*
   control-flow child in `View.probe`. These drive the structural swap, so a
   read hidden in one of them freezes the whole branch, not just one value. *)
and probe_condition (env : env) (e : expression) : expression =
  let p (v : expression) = if should_probe env v then wrap_probe v else v in
  match e.pexp_desc with
  | Pexp_ifthenelse (c, t, eo) -> { e with pexp_desc = Pexp_ifthenelse (p c, t, eo) }
  | Pexp_match (s, cases) ->
    { e with
      pexp_desc =
        Pexp_match
          (p s, List.map (fun cs -> { cs with pc_guard = Option.map p cs.pc_guard }) cases) }
  | _ -> e

(* Recurse fine_node into the *node-position* bodies of control flow (the
   condition/scrutinee and any guards stay untouched — they are value position
   and should drive the structural swap). *)
and decompose_branches (env : env) (e : expression) : expression =
  match e.pexp_desc with
  | Pexp_ifthenelse (c, t, eo) ->
    { e with pexp_desc = Pexp_ifthenelse (c, fine_node env t, Option.map (fine_node env) eo) }
  | Pexp_match (s, cases) ->
    { e with pexp_desc = Pexp_match (s, List.map (fun cs -> { cs with pc_rhs = fine_node env cs.pc_rhs }) cases) }
  | _ -> e

and element_arg (env : env) ((lbl, v) : arg_label * expression) : arg_label * expression =
  if is_children_label lbl then (lbl, map_children (fine_node env) v)
  else
    match lbl with
    | Labelled _ | Optional _ ->
      (* attribute: value position. Thunk it if reactive so it lowers to a
         computed attribute; leave plain JSX/static/already-function values. *)
      if is_non_leaf_label lbl then (lbl, v) else (lbl, leaf_value env v)
    | Nolabel -> (lbl, v)

and component_arg (env : env) ((lbl, v) : arg_label * expression) : arg_label * expression =
  (* User-component props are left untouched: an eager `Signal.get(x)` prop is a
     legitimate one-shot read of a plain-typed prop (pass the signal itself when
     the prop should be reactive). The exceptions are node-shaped values, which
     are node position wherever they appear: children, any prop whose value is
     itself JSX, and any prop whose value is a *function returning* JSX (a
     render callback) — recurse so their reactive leaves stay fine-grained and
     their bare children are coerced. *)
  if is_children_label lbl then (lbl, map_children (fine_node env) v)
  else if jsx_parts v <> None || is_jsx_fragment v then (lbl, fine_node env v)
  else if is_render_callback v then (lbl, fine_callback env v)
  else (lbl, v)

(* Decompose the body of a render callback, walking past its parameters (and
   the uncurried `Function$` wrapper) to the node-position body. *)
and fine_callback (env : env) (e : expression) : expression =
  match e.pexp_desc with
  | Pexp_construct (({ txt = Longident.Lident "Function$"; _ } as c), Some fn) ->
    { e with pexp_desc = Pexp_construct (c, Some (fine_callback env fn)) }
  | Pexp_fun (l, def, p, body) ->
    { e with pexp_desc = Pexp_fun (l, def, p, fine_callback env body) }
  | _ -> fine_node env e

and value_arg (env : env) ((lbl, v) : arg_label * expression) : arg_label * expression =
  if is_children_label lbl then (lbl, map_children (leaf_value env) v)
  else
    match lbl with
    | Labelled "value" -> (lbl, leaf_value env v)
    | _ -> (lbl, v)

(* Map [f] over a JSX children list (a `::`/`[]` spine); tolerate a bare
   single child that is not wrapped in a list. *)
and map_children f (v : expression) : expression =
  match v.pexp_desc with
  | Pexp_construct
      ( ({ txt = Longident.Lident "::"; _ } as c),
        Some ({ pexp_desc = Pexp_tuple [ hd; tl ]; _ } as tup) ) ->
    let hd' = f hd in
    let tl' = map_children f tl in
    { v with pexp_desc = Pexp_construct (c, Some { tup with pexp_desc = Pexp_tuple [ hd'; tl' ] }) }
  | Pexp_construct ({ txt = Longident.Lident "[]"; _ }, None) -> v
  | _ -> f v

(* ---- traversal: find @xote.component and decompose ----------------------- *)
and map_expr (env : env) (e : expression) : expression =
  let d =
    match e.pexp_desc with
    | Pexp_fun (l, def, p, body) -> Pexp_fun (l, def, p, map_expr env body)
    | Pexp_let (r, vbs, body) ->
      (* aliases bound here are visible in the body, not in the RHSs *)
      let vbs' = List.map (map_vb env) vbs in
      let env' = collect_val_aliases env vbs in
      Pexp_let (r, vbs', map_expr env' body)
    | Pexp_letmodule (name, me, body) ->
      let env' = collect_mod_alias env name me in
      Pexp_letmodule (name, me, map_expr env' body)
    | Pexp_open (o, l, x) ->
      let env' = collect_open env l.Location.txt in
      Pexp_open (o, l, map_expr env' x)
    | Pexp_sequence (a, b) -> Pexp_sequence (map_expr env a, map_expr env b)
    | Pexp_apply (f, args) ->
      Pexp_apply (map_expr env f, List.map (fun (l, a) -> (l, map_expr env a)) args)
    | Pexp_ifthenelse (c, t, eo) ->
      Pexp_ifthenelse (map_expr env c, map_expr env t, Option.map (map_expr env) eo)
    | Pexp_match (x, cases) ->
      Pexp_match (map_expr env x, List.map (fun cs -> { cs with pc_rhs = map_expr env cs.pc_rhs }) cases)
    | Pexp_constraint (x, t) -> Pexp_constraint (map_expr env x, t)
    | Pexp_tuple xs -> Pexp_tuple (List.map (map_expr env) xs)
    | Pexp_array xs -> Pexp_array (List.map (map_expr env) xs)
    | Pexp_construct (l, eo) -> Pexp_construct (l, Option.map (map_expr env) eo)
    | other -> other
  in
  { e with pexp_desc = d }

and map_vb (env : env) (vb : value_binding) : value_binding =
  match List.find_opt is_xote_component vb.pvb_attributes with
  | Some _ ->
    (* swap @xote.component -> @jsx.component and decompose the returned JSX *)
    { vb with
      pvb_attributes = jsx_component_attr :: strip_xote_component vb.pvb_attributes;
      pvb_expr = decompose_component_body env vb.pvb_expr }
  | None -> { vb with pvb_expr = map_expr env vb.pvb_expr }

(* A binding *inside* an annotated component. Its value is rendered as part of
   that component, so JSX bound to a name — `let row = <p> {"x"} </p>` — and a
   local helper returning JSX — `let btn = label => <button> {label} </button>`
   — are decomposed exactly like inline markup. Without this the annotation
   stopped at the component's return expression, and pulling a piece of markup
   out into a local binding silently lost fine-grained leaves and required the
   value-primitive wrappers back. *)
and map_local_vb (env : env) (vb : value_binding) : value_binding =
  if List.exists is_xote_component vb.pvb_attributes then map_vb env vb
  else
    (* Whatever shape the value is — JSX, a helper returning JSX, or JSX sitting
       one container down (`let rows = [<li/>]`, `Some(<h1/>)`, a tuple,
       `xs => Array.map(xs, x => <li/>)`) — it is rendered as part of this
       component, so it is decomposed like inline markup.

       Stopping at the first two shapes was the third instance of one bug: an
       expression that ends up in node position was not reached by the traversal.
       It was also the worst-behaved one, because unreached leaves are never
       *visited* — so they get no `View.probe` either, and a reactive attribute
       inside container-bound JSX compiled to a frozen value with no warning. *)
    { vb with pvb_expr = decompose_here env vb.pvb_expr }

(* Walk to the component's tail (return) expression, threading the alias env
   through lets/opens and running the normal traversal on non-tail parts (so a
   nested reactive leaves still work), then fine-grain the returned JSX. *)
and decompose_component_body (env : env) (e : expression) : expression =
  match e.pexp_desc with
  (* Uncurried function encoding: `Function$(fun … -> body)` (with res.arity on
     the construct, preserved by the record-with). Unwrap to reach the fun. *)
  | Pexp_construct (({ txt = Longident.Lident "Function$"; _ } as c), Some fn) ->
    { e with pexp_desc = Pexp_construct (c, Some (decompose_component_body env fn)) }
  | Pexp_fun (l, def, p, body) ->
    { e with pexp_desc = Pexp_fun (l, def, p, decompose_component_body env body) }
  | _ ->
    (match thread_binding env decompose_component_body e with
     | Some threaded -> threaded
     | None -> fine_node env e)

(* Does this file opt in to the annotation at all? A file containing at least
   one @xote.component is written in the fine-grained style, so JSX anywhere in
   it — including plain helper functions like
   `let filterButton = (label, …) => <button> {label} </button>` — is
   decomposed too. Helpers that return markup are components in all but name,
   and requiring the value-primitive wrappers back in them was the last place
   the two styles collided.

   Files with no annotation are left completely untouched, so a project mixing
   @jsx.component code with explicit thunks keeps its current semantics. *)
let rec structure_has_component (s : structure) : bool =
  List.exists
    (fun si ->
      match si.pstr_desc with
      | Pstr_value (_, vbs) ->
        List.exists (fun vb -> List.exists is_xote_component vb.pvb_attributes) vbs
      | Pstr_module mb -> module_has_component mb.pmb_expr
      | Pstr_recmodule mbs -> List.exists (fun mb -> module_has_component mb.pmb_expr) mbs
      | _ -> false)
    s

and module_has_component (me : module_expr) : bool =
  match me.pmod_desc with
  | Pmod_structure s -> structure_has_component s
  | Pmod_constraint (m, _) -> module_has_component m
  | Pmod_functor (_, _, b) -> module_has_component b
  | _ -> false

(* Set once per file, before the traversal runs. *)
let fine_grain_helpers = ref false

(* Structure items are threaded left-to-right so a top-level `let g = Signal.get`,
   `module S = Signal`, or `open Signal` is visible to later items. *)
let rec map_structure (env : env) (s : structure) : structure =
  let _, rev =
    List.fold_left
      (fun (env, acc) si -> (update_env_si env si, map_si env si :: acc))
      (env, []) s
  in
  List.rev rev

and update_env_si (env : env) si =
  match si.pstr_desc with
  | Pstr_value (_, vbs) -> collect_val_aliases env vbs
  | Pstr_module mb ->
    let env = collect_mod_alias env mb.pmb_name mb.pmb_expr in
    collect_module_funcs env mb.pmb_name.Location.txt mb.pmb_expr
  | Pstr_open od -> collect_open env od.popen_lid.Location.txt
  | _ -> env

(* `module Store = { let count = s => Signal.get(s) }` in this file makes
   `Store.count(s)` a read like any local helper. Walk the module body with the
   surrounding environment (so it can use outer aliases), then qualify the
   reactive names it introduced. Only same-file modules are reachable — a helper
   imported from another file is what `View.probe` covers. *)
and collect_module_funcs (env : env) (name : string) (me : module_expr) : env =
  match me.pmod_desc with
  | Pmod_structure s | Pmod_constraint ({ pmod_desc = Pmod_structure s; _ }, _) ->
    let inner = List.fold_left update_env_si env s in
    let added before after = List.filter (fun n -> not (List.mem n before)) after in
    let names = added env.funcs inner.funcs @ added env.vals inner.vals in
    { env with qfuncs = List.map (fun n -> name ^ "." ^ n) names @ env.qfuncs }
  | _ -> env

and map_si (env : env) si =
  match si.pstr_desc with
  | Pstr_value (r, vbs) ->
    let f = if !fine_grain_helpers then map_local_vb env else map_vb env in
    { si with pstr_desc = Pstr_value (r, List.map f vbs) }
  | Pstr_module mb -> { si with pstr_desc = Pstr_module (map_mb env mb) }
  | Pstr_recmodule mbs -> { si with pstr_desc = Pstr_recmodule (List.map (map_mb env) mbs) }
  | Pstr_include incl ->
    { si with pstr_desc = Pstr_include { incl with pincl_mod = map_mod env incl.pincl_mod } }
  | Pstr_eval (e, attrs) -> { si with pstr_desc = Pstr_eval (map_expr env e, attrs) }
  | _ -> si

and map_mb (env : env) mb = { mb with pmb_expr = map_mod env mb.pmb_expr }
and map_mod (env : env) me =
  match me.pmod_desc with
  | Pmod_structure s -> { me with pmod_desc = Pmod_structure (map_structure env s) }
  (* `module Widget: Sig = { … }` and functor bodies still contain components;
     skipping them would leave @xote.component silently unexpanded *)
  | Pmod_constraint (m, mt) -> { me with pmod_desc = Pmod_constraint (map_mod env m, mt) }
  | Pmod_functor (name, mt, body) ->
    { me with pmod_desc = Pmod_functor (name, mt, map_mod env body) }
  | _ -> me

(* ---- ReScript -ppx binary protocol: `ppx <infile> <outfile>` ------------ *)
let impl_magic = "Caml1999M022"
let usage =
  "xote ppx: fine-grained @xote.component rewriter for ReScript.\n\
   Invoked by the compiler via rescript.json ppx-flags as `ppx <ast-in> <ast-out>`."

let () =
  let n = Array.length Sys.argv in
  (* `--help` doubles as the postinstall/CI smoke test: it proves the binary
     loads and executes on the host (right libc, right arch) without an AST. *)
  if n = 2 && (Sys.argv.(1) = "--help" || Sys.argv.(1) = "-h") then begin
    print_endline usage;
    exit 0
  end;
  if n < 3 then begin
    prerr_endline usage;
    exit 2
  end;
  let infile = Sys.argv.(n - 2) and outfile = Sys.argv.(n - 1) in
  let ic = open_in_bin infile in
  let magic = really_input_string ic (String.length impl_magic) in
  let name : string = input_value ic in
  let payload : Obj.t = input_value ic in
  close_in ic;
  (* Interface ASTs (Caml1999N…) legitimately pass through untouched. A
     different *implementation* magic means the compiler's ppx ABI moved and
     @xote.component cannot be expanded — fail the build here with a clear
     message rather than passing the AST through and letting it die later on
     a confusing type error. *)
  let is_impl = String.length magic >= 9 && String.sub magic 0 9 = "Caml1999M" in
  if is_impl && magic <> impl_magic then begin
    prerr_endline
      ("xote ppx: unsupported AST magic " ^ magic ^ " (this ppx expects " ^ impl_magic
       ^ "), so @xote.component cannot be expanded in " ^ name
       ^ ". The installed ReScript version's ppx ABI is newer than this ppx supports; "
       ^ "upgrade xote, or remove it from ppx-flags.");
    exit 2
  end;
  let oc = open_out_bin outfile in
  output_string oc magic;
  output_value oc name;
  (if magic = impl_magic then
     let structure = (Obj.magic payload : structure) in
     source_file := Filename.basename name;
     fine_grain_helpers := structure_has_component structure;
     output_value oc (map_structure empty_env structure)
   else output_value oc payload);
  close_out oc

