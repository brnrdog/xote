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

(* Is this pattern the unit pattern `()`? A `() => …` is a deferred thunk; a
   lambda with a real parameter is a callback its callee runs. *)
let is_unit_pat (p : pattern) : bool =
  match p.ppat_desc with
  | Ppat_construct ({ txt = Longident.Lident "()"; _ }, None) -> true
  | _ -> false
(* The thunk carries its body's location: a type error on the thunk as a whole
   (a function where an `int` prop expects a value) is then reported at the
   expression the user wrote instead of nowhere. *)
let thunk body =
  let loc = body.pexp_loc in
  let fn = { pexp_desc = Pexp_fun (Nolabel, None, unit_pat, body); pexp_loc = loc; pexp_attributes = [] } in
  { pexp_desc = Pexp_construct (mkloc (Longident.Lident "Function$"), Some fn);
    pexp_loc = loc; pexp_attributes = [ res_arity 1 ] }

let view_tracked = Longident.Ldot (Longident.Lident "View", "tracked")
let wrap_tracked e = apply (ident view_tracked) [ thunk e ]

let view_child = Longident.Ldot (Longident.Lident "View", "child")
let wrap_child e = apply (ident view_child) [ e ]

let obj_magic = Longident.Ldot (Longident.Lident "Obj", "magic")
let array_concat = Longident.Ldot (Longident.Lident "Array", "concat")

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
  (* what each module alias in `mods` stands for: "Signal" / "MaybeSignal" /
     "Prop" — the read module decides which `get` a signal-typed name is read
     with, so the alias has to remember its target, not just that it is one *)
  mod_of : (string * string) list;
  funcs : string list;
  (* reactive helpers reached through a same-file module, as "Store.count" *)
  qfuncs : string list;
  open_signal : bool;
  (* ---- signal-typed names (see "signal-typed values" below) ----------------
     A name known to hold a `Signal.t` or a `MaybeSignal.t`, mapped to the
     module path it was named through (`Signal`, `Xote.Signal`, an alias `S`,
     `MaybeSignal`), so the read the ppx emits for it — `<path>.get(name)` —
     resolves exactly where the user's own spelling did. *)
  sigs : (string * Longident.t) list;
  (* the same, reached through a same-file module, as "Store.count" *)
  qsigs : (string * Longident.t) list;
  (* an optional prop annotated `Signal.t`/`MaybeSignal.t` with no default: an
     `option<Signal.t<_>>` in the body, never read directly — but a `Some(x)`
     case over it binds `x` as a signal-typed name *)
  opts : (string * Longident.t) list;
  (* read modules opened in scope ("Signal", "MaybeSignal", "Prop"), most
     recent first, so a bare `t<_>` annotation can be resolved *)
  opened : string list;
  (* local functions the ppx can see the definition of, as "f" or "Store.f":
     what is known about each parameter decides whether a signal-typed name
     passed to it is read first *)
  fns : (string * fn_info) list;
}

(* What a local function's body says about its parameters. `sig_params` are
   the ones it evidently receives as signals (annotated `Signal.t`, or passed
   bare to `Signal.get`/`peek`/another signal-aware callee); `val_params` the
   ones it evidently receives as values (annotated with any other type, or used
   as an operand, a structural part, a stdlib argument…). A parameter with no
   evidence either way is left alone at the call site. *)
and fn_info = {
  params : (arg_label * string option) list;
  sig_params : string list;
  val_params : string list;
}

let empty_env =
  { vals = []; mods = []; mod_of = []; funcs = []; qfuncs = []; open_signal = false;
    sigs = []; qsigs = []; opts = []; opened = []; fns = [] }

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

(* The same question for a *leaf*, where a lambda with a real parameter —
   `xs->Array.map(x => x ++ Signal.get(suffix))` — is a callback its callee
   runs while the leaf is evaluated, so a read inside it is eager too. Only a
   `() => …` thunk is deferred. (`reads_signal_eager` keeps the stricter rule:
   it also decides whether a *helper* is reactive, and a helper returning JSX
   whose attributes read signals must not count — those leaves are their own.) *)
let rec reads_signal_in_leaf (env : env) (e : expression) : bool =
  match e.pexp_desc with
  | Pexp_fun (_, _, p, body) -> (not (is_unit_pat p)) && reads_signal_in_leaf env body
  | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some fn) ->
    reads_signal_in_leaf env fn
  | _ ->
    is_reactive_call env e || is_read_fn env e
    || List.exists (reads_signal_in_leaf env) (sub_exprs e)

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

(* ---- signal-typed values --------------------------------------------------
   Everything above finds *reads* — a `Signal.get(x)` written out. This block
   finds *signals*: names the ppx can tell hold a `Signal.t` or a
   `MaybeSignal.t`, from the one place a syntactic ppx can learn a type — an
   annotation (`~count: Signal.t<int>`, `let x: Signal.t<int> = …`) or a
   constructor it knows (`let x = Signal.make(0)`, `Computed.make(…)`,
   `SSRState.signal(…)`, `MaybeSignal.reactive(…)`).

   Inside a JSX value leaf such a name *is* a read. `{count}`,
   `hidden={open_}` and `class={[name, tone]->Array.join(" ")}` are rewritten
   to read through `<path>.get(name)` (see `deref` below) and then handled by
   the ordinary rules: the leaf now visibly reads a signal, so it is thunked
   into a reactive attribute or text node. Without this, a bare `{count}` only
   worked because `View.child` duck-types a signal at runtime, and a derived
   expression over a signal-typed name was a type error.

   Names are scoped exactly like the alias environment: visible after their
   binding, removed by any rebinding — a `let`, a lambda parameter, a
   `switch` case pattern — so `render={count => <li> {count} </li>}` reads the
   row, not the signal of the same name. *)

let last_component = function
  | Longident.Lident n | Longident.Ldot (_, n) -> Some n
  | Longident.Lapply _ -> None

let replace_last (lid : Longident.t) (n : string) : Longident.t =
  match lid with
  | Longident.Ldot (p, _) -> Longident.Ldot (p, n)
  | _ -> Longident.Lident n

(* The read module a module path stands for ("Signal", "MaybeSignal", "Prop"),
   following a same-file alias (`module S = Signal`). *)
let read_module_of_path (env : env) (m : Longident.t) : string option =
  match last_component m with
  | Some n when is_read_module_name n -> Some n
  | Some n -> List.assoc_opt n env.mod_of
  | None -> None

(* `Signal.t<_>`, `Xote.Signal.t<_>`, `S.t<_>`, `MaybeSignal.t<_>`, `Prop.t<_>`:
   the module path to read a value of that type through. *)
let rec sig_path_of_type (env : env) (t : core_type) : Longident.t option =
  match t.ptyp_desc with
  | Ptyp_constr ({ txt = Longident.Ldot (m, "t"); _ }, _) ->
    (match read_module_of_path env m with Some _ -> Some m | None -> None)
  (* a bare `t<_>` under `open Signal` *)
  | Ptyp_constr ({ txt = Longident.Lident "t"; _ }, _) ->
    (match env.opened with m :: _ -> Some (Longident.Lident m) | [] -> None)
  | Ptyp_alias (t, _) -> sig_path_of_type env t
  | _ -> None

(* Is this annotation evidently *not* a signal? Any concrete constructor other
   than the signal types (`string`, `int`, `array<_>`, a record) — used as
   value evidence for a function parameter. A type variable or `_` says
   nothing. *)
let is_value_type (env : env) (t : core_type) : bool =
  match t.ptyp_desc with
  | Ptyp_constr _ | Ptyp_tuple _ | Ptyp_arrow _ | Ptyp_variant _ | Ptyp_object _ ->
    sig_path_of_type env t = None
  | _ -> false

(* A bare reference to a signal-typed name: `count`, or `Store.count` through a
   same-file module. *)
let is_sig_ident (env : env) (e : expression) : Longident.t option =
  match e.pexp_desc with
  | Pexp_ident { txt = Longident.Lident x; _ } -> List.assoc_opt x env.sigs
  | Pexp_ident { txt = Longident.Ldot (Longident.Lident m, x); _ } ->
    List.assoc_opt (m ^ "." ^ x) env.qsigs
  | _ -> None

(* Does this expression evidently hold a signal? A constructor the ppx knows
   (`Signal.make`, `Computed.make` and `SSRState.signal` return a `Signal.t`;
   `MaybeSignal.reactive/static/computed` a `MaybeSignal.t`), an annotated
   value, or a plain alias of a name already known. *)
let sig_path_of_expr (env : env) (e : expression) : Longident.t option =
  match e.pexp_desc with
  | Pexp_ident _ -> is_sig_ident env e
  | Pexp_constraint (_, t) -> sig_path_of_type env t
  | Pexp_apply ({ pexp_desc = Pexp_ident { txt = Longident.Ldot (m, fn); _ }; _ }, _) ->
    (match last_component m, fn with
     | Some "Computed", "make" | Some "SSRState", "signal" -> Some (replace_last m "Signal")
     | Some _, "make" ->
       (match read_module_of_path env m with Some "Signal" -> Some m | _ -> None)
     | Some _, ("reactive" | "static" | "computed" | "signal") ->
       (match read_module_of_path env m with
        | Some ("MaybeSignal" | "Prop") -> Some m
        | _ -> None)
     | _ -> None)
  | _ -> None

let rec pat_vars (p : pattern) : string list =
  match p.ppat_desc with
  | Ppat_var { txt; _ } -> [ txt ]
  | Ppat_alias (p, { txt; _ }) -> txt :: pat_vars p
  | Ppat_constraint (p, _) | Ppat_lazy p | Ppat_exception p | Ppat_open (_, p) -> pat_vars p
  | Ppat_tuple ps | Ppat_array ps -> List.concat_map pat_vars ps
  | Ppat_construct (_, Some p) | Ppat_variant (_, Some p) -> pat_vars p
  | Ppat_record (fields, _) -> List.concat_map (fun (_, p) -> pat_vars p) fields
  | Ppat_or (a, b) -> pat_vars a @ pat_vars b
  | _ -> []

let shadow_sigs (env : env) (names : string list) : env =
  if names = [] then env
  else
    let keep (n, _) = not (List.mem n names) in
    { env with
      sigs = List.filter keep env.sigs;
      opts = List.filter keep env.opts;
      fns = List.filter keep env.fns }

(* The simple binding shapes a name and its annotation can be read off:
   `x` and `x: T`. Anything else (a tuple, a record pattern) binds names the
   collectors only shadow. *)
let simple_binding (p : pattern) : (string * core_type option) option =
  match p.ppat_desc with
  | Ppat_var { txt; _ } -> Some (txt, None)
  | Ppat_constraint ({ ppat_desc = Ppat_var { txt; _ }; _ }, t) -> Some (txt, Some t)
  | _ -> None

(* A function parameter: its pattern shadows whatever it names; then, if it is
   annotated `Signal.t`/`MaybeSignal.t` — or optional with a default that
   evidently builds one — the name is a signal in the body. An optional
   parameter with no default is an `option<Signal.t<_>>` and is not. *)
let bind_param (env : env) (lbl : arg_label) (default : expression option) (p : pattern) : env =
  let env = shadow_sigs env (pat_vars p) in
  match simple_binding p, lbl, default with
  | None, _, _ -> env
  | Some (name, annotation), Optional _, None ->
    (* `~count: Signal.t<int>=?`: an option in the body, remembered so a
       `Some(count)` case can bind the payload as the signal *)
    (match Option.bind annotation (sig_path_of_type env) with
     | Some p -> { env with opts = (name, p) :: env.opts }
     | None -> env)
  | Some (name, annotation), _, _ ->
    let path =
      match Option.bind annotation (sig_path_of_type env) with
      | Some p -> Some p
      | None -> Option.bind default (sig_path_of_expr env)
    in
    (match path with Some p -> { env with sigs = (name, p) :: env.sigs } | None -> env)

(* A `switch x { | Some(y) => … }` over an optional signal prop `x` binds `y`
   as the signal for that case: the pattern shadows first, then re-enters. *)
let case_env (env : env) (scrutinee : expression) (c : case) : env =
  (* look the option up before the pattern shadows it: `| Some(count) =>`
     over `count` itself is the idiomatic spelling *)
  let unwrapped =
    match scrutinee.pexp_desc, c.pc_lhs.ppat_desc with
    | ( Pexp_ident { txt = Longident.Lident x; _ },
        Ppat_construct ({ txt = Longident.Lident "Some"; _ }, Some inner) ) ->
      (match List.assoc_opt x env.opts, simple_binding inner with
       | Some path, Some (y, _) -> Some (y, path)
       | _ -> None)
    | _ -> None
  in
  let env = shadow_sigs env (pat_vars c.pc_lhs) in
  match unwrapped with Some binding -> { env with sigs = binding :: env.sigs } | None -> env

(* ---- binding collectors ------------------------------------------------- *)
(* `let g = Signal.get` binds `g` as a value alias; `let cls = () => …Signal.get…`
   binds `cls` as a reactive helper; `let count = Signal.make(0)` (or an
   annotated `let count: Signal.t<int> = …`) binds `count` as a signal-typed
   name; anything else shadows away a prior binding of that name. *)
(* The parameter analysis of a local function (`fn_info_of`, defined with the
   walk it is built on, further down) — bound here so the collector can record
   what it learns about each function it meets. *)
let fn_info_ref : (env -> expression -> fn_info option) ref = ref (fun _ _ -> None)

let collect_val_aliases (env : env) (vbs : value_binding list) : env =
  List.fold_left
    (fun env vb ->
      let env = shadow_sigs env (pat_vars vb.pvb_pat) in
      match simple_binding vb.pvb_pat with
      | Some (name, annotation) ->
        let drop = List.filter (fun n -> n <> name) in
        let env =
          if is_read_fn env vb.pvb_expr then
            { env with vals = name :: env.vals; funcs = drop env.funcs }
          else if func_reads env vb.pvb_expr then
            { env with funcs = name :: env.funcs; vals = drop env.vals }
          else { env with vals = drop env.vals; funcs = drop env.funcs }
        in
        let env =
          match !fn_info_ref env vb.pvb_expr with
          | Some info -> { env with fns = (name, info) :: env.fns }
          | None -> env
        in
        let path =
          match Option.bind annotation (sig_path_of_type env) with
          | Some p -> Some p
          | None -> sig_path_of_expr env vb.pvb_expr
        in
        (match path with Some p -> { env with sigs = (name, p) :: env.sigs } | None -> env)
      | None -> env)
    env vbs

let read_module_target (me : module_expr) : string option =
  match me.pmod_desc with
  | Pmod_ident { txt = Longident.Lident name; _ } when is_read_module_name name -> Some name
  | Pmod_ident { txt = Longident.Ldot (_, name); _ } when is_read_module_name name -> Some name
  | _ -> None

let collect_mod_alias (env : env) (name : string Location.loc) (me : module_expr) : env =
  match read_module_target me with
  | Some target ->
    { env with
      mods = name.Location.txt :: env.mods;
      mod_of = (name.Location.txt, target) :: env.mod_of }
  | None -> env

let is_read_lid = function
  | Longident.Lident name -> is_read_module_name name
  | Longident.Ldot (_, name) -> is_read_module_name name
  | _ -> false

let collect_open (env : env) (lid : Longident.t) : env =
  if is_read_lid lid then
    let name = match lid with Longident.Lident n | Longident.Ldot (_, n) -> n | _ -> "Signal" in
    { env with open_signal = true; opened = name :: env.opened }
  else env

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
   neither thunked nor probed. An event handler is a callback; `attrs` is the
   escape-hatch array and `data` the data-attribute object, both containers
   whose *entries* carry their own reactivity (a signal, a `() => ...` thunk,
   `View.signalAttr`). Thunking any of them produces a value its prop cannot
   hold - `array<(string, 'a)>` or `Obj.t` given a function, a
   `Dom.event => unit` given a `unit => _` - and the type error names no
   location, because the thunk the ppx emits has none. *)
let is_non_leaf_label (lbl : arg_label) : bool =
  match label_name lbl with
  | Some "attrs" | Some "data" -> true
  (* the `int`-typed props of `Elements.props`: no reactive form exists for
     them, so a thunk (or a read of a signal-typed name) could only produce a
     type error — leave them to the type checker, which reports it at the
     value *)
  | Some ("maxLength" | "minLength" | "rows" | "cols" | "tabIndex") -> true
  | Some n -> String.length n > 2 && n.[0] = 'o' && n.[1] = 'n' && n.[2] >= 'A' && n.[2] <= 'Z'
  | None -> false

(* A value-position expression should be thunked iff it *eagerly* reads a signal
   and isn't already JSX. Using the eager check means values that are already
   reactive on their own — a `() => …` thunk, a `Computed`, a `Prop.reactive(…)`
   — are left untouched (their reads are deferred inside a lambda), so
   @xote.component is a safe drop-in on components already written that way. *)
let should_thunk (env : env) (v : expression) : bool =
  reads_signal_in_leaf env v && jsx_parts v = None

(* A value-position expression whose read status the ppx cannot decide: it is
   not a visible read (that is already thunked), and it is not provably
   call-free either. `View.probe` settles it at runtime. Node-shaped values are
   excluded — they are decomposed, not read. *)
let should_probe (env : env) (v : expression) : bool =
  (not (should_thunk env v)) && (not (is_inert v)) && not (contains_jsx v)

(* ---- deref: a signal-typed name inside a value leaf is a read -------------
   `count` becomes `Signal.get(count)` (through whatever path named it — see
   `env.sigs`), carrying the identifier's own source location so a type error
   still points at the name the user wrote.

   The rewrite only happens where the ppx can *justify* a read — where leaving
   the signal would have been a type error or a duck-typed runtime read, never
   where code that compiles today could mean the signal itself:

     - a bare leaf, a condition or scrutinee, a structural part (an array,
       tuple, record or variant payload), an operand of an operator (which
       includes template strings), a field access, the argument of a stdlib
       function (`String.trim(name)`, `Int.toString(count)`);
     - inside a *callback* — `xs->Array.map(x => x ++ suffix)` — which its
       callee runs while the leaf is evaluated. A `() => …` thunk is not
       entered: deferred code is the user's, and reads what it reads, so
       `{() => helper(count)}` still passes the signal.

   It does not happen for:

     - the bare signal arguments of a *signal-aware* callee: Xote's and
       rescript-signals' entry points (`Signal.get(count)`, `Signal.peek`,
       `MaybeSignal.reactive(count)`, `View.signalAttr("x", count)`), and a
       read alias (`g(count)` after `let g = Signal.get`, `S.get`, a bare `get`
       under `open Signal`);
     - a name under an explicit signal-typed constraint, `(count: Signal.t<_>)`
       — the typed way to say "the signal itself" to any callee;
     - the arguments of a callee the ppx cannot see into: a function from
       another module, or a local one whose body gives no evidence about that
       parameter. Such a call is left exactly as written (and probed, as
       before), so nothing that compiles today stops compiling;
     - a local function's parameter the body evidently receives as a signal
       (annotated `Signal.t`, or handed to `Signal.get`/`peek`). One it
       evidently receives as a value (`(who: string)`, or used as an operand or
       a stdlib argument) is read at the call site, so `greet(name)` reads. *)

(* ReScript's standard library: a call into it takes values. *)
let is_stdlib_module = function
  | "String" | "Int" | "Float" | "Array" | "Option" | "Result" | "List" | "Dict" | "JSON"
  | "Math" | "Date" | "Bool" | "BigInt" | "Nullable" | "Null" | "Console" | "Js" | "Belt"
  | "RegExp" | "Symbol" | "Object" | "Iterator" | "Map" | "Set" | "WeakMap" | "WeakSet"
  | "Promise" | "Error" | "Exn" | "Char" | "Bytes" | "Pervasives" | "Stdlib" | "Type" ->
    true
  | _ -> false

let rec first_component = function
  | Longident.Lident n -> Some n
  | Longident.Ldot (m, _) -> first_component m
  | Longident.Lapply _ -> None

let is_signal_aware_callee (env : env) (f : expression) : bool =
  match f.pexp_desc with
  | Pexp_ident { txt = Longident.Ldot (m, _); _ } ->
    (match last_component m with
     | Some n ->
       is_library_module n
       || n = "SSRState" || n = "SSRContext" || n = "SSR" || n = "Router" || n = "Hydration"
       || List.mem n env.mods
     | None -> false)
  | Pexp_ident { txt = Longident.Lident x; _ } ->
    List.mem x env.vals
    || (env.open_signal && (match x with "get" | "peek" | "set" | "update" -> true | _ -> false))
  | _ -> false

(* The context a bare signal-typed name occurs in. *)
type ctx =
  | Value (* evidently a value position: read it *)
  | SigArg (* evidently the signal itself: leave it *)
  | Unknown (* cannot tell: leave it *)

let local_fn (env : env) (f : expression) : fn_info option =
  match f.pexp_desc with
  | Pexp_ident { txt = Longident.Lident x; _ } -> List.assoc_opt x env.fns
  | Pexp_ident { txt = Longident.Ldot (Longident.Lident m, x); _ } ->
    List.assoc_opt (m ^ "." ^ x) env.fns
  | _ -> None

(* Pair a call's arguments with the callee's parameters: positional arguments
   in order, labelled ones by label. *)
let param_of_arg (info : fn_info) (args : (arg_label * expression) list) (i : int) : string option =
  let lbl, _ = List.nth args i in
  match lbl with
  | Labelled n | Optional n ->
    List.fold_left
      (fun acc (l, name) ->
        match l with
        | (Labelled m | Optional m) when m = n -> name
        | _ -> acc)
      None info.params
  | Nolabel ->
    let rec nth_positional k = function
      | [] -> None
      | (Nolabel, name) :: rest -> if k = 0 then name else nth_positional (k - 1) rest
      | _ :: rest -> nth_positional k rest
    in
    let position =
      List.length (List.filter (fun (l, _) -> l = Nolabel) (List.filteri (fun j _ -> j < i) args))
    in
    nth_positional position info.params

(* The context of each argument of `f(args)`. *)
let arg_ctxs (env : env) (f : expression) (args : (arg_label * expression) list) : ctx list =
  let all c = List.map (fun _ -> c) args in
  if is_signal_aware_callee env f then all SigArg
  else
    match f.pexp_desc with
    | Pexp_ident { txt = Longident.Lident op; _ } when is_operator_name op -> all Value
    | Pexp_ident { txt; _ } when (match first_component txt with Some m -> is_stdlib_module m | None -> false) ->
      all Value
    | _ ->
      (match local_fn env f with
       | Some info ->
         List.mapi
           (fun i _ ->
             match param_of_arg info args i with
             | Some p when List.mem p info.sig_params -> SigArg
             | Some p when List.mem p info.val_params -> Value
             | _ -> Unknown)
           args
       | None -> all Unknown)

(* The one walk behind both the rewrite and the evidence analysis: visit every
   bare occurrence of a signal-typed name with the context it occurs in, and
   let [on_sig] decide what to put there. [into_thunks] also enters `() => …`,
   which the evidence analysis wants (a parameter read inside a thunk is still
   a signal) and the rewrite does not. *)
let rec walk_sigs (into_thunks : bool) (on_sig : ctx -> Longident.t -> expression -> expression)
    (env : env) (e : expression) : expression =
  let walk = walk_sigs into_thunks on_sig in
  match is_sig_ident env e with
  | Some path -> on_sig Value path e
  | None ->
    (match e.pexp_desc with
     (* `(count: Signal.t<_>)`: the signal itself, by declaration *)
     | Pexp_constraint (x, t) when is_sig_ident env x <> None && sig_path_of_type env t <> None ->
       (match is_sig_ident env x with
        | Some path -> { e with pexp_desc = Pexp_constraint (on_sig SigArg path x, t) }
        | None -> e)
     | Pexp_fun (l, def, p, body) ->
       if is_unit_pat p && not into_thunks then e
       else
         { e with
           pexp_desc =
             Pexp_fun (l, Option.map (walk env) def, p, walk (bind_param env l def p) body) }
     | Pexp_construct (({ txt = Longident.Lident "Function$"; _ } as c), Some fn) ->
       { e with pexp_desc = Pexp_construct (c, Some (walk env fn)) }
     | Pexp_apply
         ( ({ pexp_desc = Pexp_ident { txt = Longident.Lident ("|." | "|>"); _ }; _ } as op),
           [ (l1, x); (l2, f) ] ) ->
       (* The pipe reaches the ppx as an operator application, `x |. f` with
          `f` a bare callee or a partial application: `x` is `f`'s first
          argument, so it gets the context `f(x, …)` would give it. *)
       let target, rest = match f.pexp_desc with Pexp_apply (g, a) -> (g, a) | _ -> (f, []) in
       let ctx = List.hd (arg_ctxs env target ((Nolabel, x) :: rest)) in
       let x' =
         match is_sig_ident env x with Some path -> on_sig ctx path x | None -> walk env x
       in
       { e with pexp_desc = Pexp_apply (op, [ (l1, x'); (l2, walk env f) ]) }
     | Pexp_apply (f, args) ->
       let ctxs = arg_ctxs env f args in
       let args' =
         List.map2
           (fun (l, a) ctx ->
             match is_sig_ident env a with
             | Some path -> (l, on_sig ctx path a)
             | None -> (l, walk env a))
           args ctxs
       in
       { e with pexp_desc = Pexp_apply (f, args') }
     | Pexp_let (r, vbs, body) ->
       (* the bound values are evaluated here, so they are walked too — except
          a plain alias of a signal, which keeps the name a signal in the body *)
       let vbs' =
         List.map
           (fun vb ->
             if is_sig_ident env vb.pvb_expr <> None then vb
             else { vb with pvb_expr = walk env vb.pvb_expr })
           vbs
       in
       { e with pexp_desc = Pexp_let (r, vbs', walk (collect_val_aliases env vbs) body) }
     | Pexp_match (s, cases) ->
       { e with pexp_desc = Pexp_match (walk env s, List.map (walk_case walk env s) cases) }
     | Pexp_try (s, cases) ->
       { e with pexp_desc = Pexp_try (walk env s, List.map (walk_case walk env s) cases) }
     | _ -> map_sub_exprs (walk env) e)

and walk_case walk (env : env) (scrutinee : expression) (c : case) : case =
  let env = case_env env scrutinee c in
  { c with pc_guard = Option.map (walk env) c.pc_guard; pc_rhs = walk env c.pc_rhs }

let read_through (loc : Location.t) (path : Longident.t) (e : expression) : expression =
  let get =
    { pexp_desc = Pexp_ident { txt = Longident.Ldot (path, "get"); loc };
      pexp_loc = loc;
      pexp_attributes = [] }
  in
  { pexp_desc = Pexp_apply (get, [ (Nolabel, e) ]); pexp_loc = loc; pexp_attributes = [] }

let deref (env : env) (e : expression) : expression =
  walk_sigs false
    (fun ctx path x -> match ctx with Value -> read_through x.pexp_loc path x | SigArg | Unknown -> x)
    env e

(* What a function's body says about its parameters — see `fn_info`. The
   parameters are entered as signal-typed names of a throwaway path, and every
   occurrence is classified by the context the walk hands back. *)
let fn_info_of (env : env) (e : expression) : fn_info option =
  let rec params acc x =
    match x.pexp_desc with
    | Pexp_construct ({ txt = Longident.Lident "Function$"; _ }, Some fn) -> params acc fn
    | Pexp_fun (l, _, p, body) -> params ((l, p) :: acc) body
    | _ -> (List.rev acc, x)
  in
  match params [] e with
  | [], _ -> None
  | ps, body ->
    let named = List.filter_map (fun (_, p) -> simple_binding p) ps in
    let probe_path = Longident.Lident "%param" in
    let sig_params = ref [] and val_params = ref [] in
    List.iter
      (fun (name, annotation) ->
        match annotation with
        | Some t when sig_path_of_type env t <> None -> sig_params := name :: !sig_params
        | Some t when is_value_type env t -> val_params := name :: !val_params
        | _ -> ())
      named;
    let env' =
      { env with
        sigs = List.map (fun (n, _) -> (n, probe_path)) named;
        opts = [];
        (* a parameter shadows an outer function of the same name *)
        fns = List.filter (fun (n, _) -> not (List.mem_assoc n named)) env.fns }
    in
    let note ctx _ (x : expression) =
      (match x.pexp_desc, ctx with
       | Pexp_ident { txt = Longident.Lident n; _ }, Value -> val_params := n :: !val_params
       | Pexp_ident { txt = Longident.Lident n; _ }, SigArg -> sig_params := n :: !sig_params
       | _ -> ());
      x
    in
    ignore (walk_sigs true note env' body);
    (* signal evidence wins a conflict: passing the signal on is the safe reading *)
    let sig_params = !sig_params in
    let val_params = List.filter (fun n -> not (List.mem n sig_params)) !val_params in
    Some
      { params = List.map (fun (l, p) -> (l, Option.map fst (simple_binding p))) ps;
        sig_params;
        val_params }

let () = fn_info_ref := fn_info_of

(* ---- `%signal`: read this signal, said out loud -------------------------
   Everything above works out *which* values are reactive. This is the way to
   simply say so:

     <div class={%theme}> {%propA} </div>

   `%name` is rewritten to `Signal.get(name)` (or `MaybeSignal.get(name)` when
   the ppx knows the name is a wrapper), and from there it is an ordinary
   visible read: the leaf is thunked, a marked scrutinee tracks its switch, a
   marked value inside a larger expression makes that expression reactive. No
   inference is involved, so the mark reaches what inference cannot — a signal
   from another module, one held in a record field, one behind a path:

     <p class={%Store.tone}> {%store.count} </p>

     {switch %user {
      | None => "Unauthorized"
      | Some(user) => `Welcome, ${user.name}`
      }}

   The spelling is ReScript's extension syntax, which is the character the
   language reserves for ppxes, and it is the only one that carries the name
   *inside* the mark: `@name` does not parse (an attribute needs a name and a
   target), `@@name` is the file-level form, and an attribute that does parse —
   `@live name` — puts the mark beside the name rather than on it. It also
   fails loudly on its own: an extension nobody expands is a ReScript error,
   where an unclaimed attribute is silently dropped.

   A mark is only ever a plain value path. Extensions that mean something to
   ReScript itself (`%raw`, `%todo`, …) and anything carrying a payload are
   left alone. *)

let reserved_extensions =
  [ "raw"; "todo"; "debugger"; "external"; "obj"; "re"; "graphql"; "relay"; "sql" ]

(* The segments of a dotted mark: `%Store.tone` -> ["Store"; "tone"]. *)
let split_path (s : string) : string list = String.split_on_char '.' s

let starts_lower (s : string) : bool =
  String.length s > 0 && (match s.[0] with 'a' .. 'z' | '_' -> true | _ -> false)

(* A mark names a value, so its last segment is lowercase; `%Store` alone, or
   an empty name, is not one. *)
let is_value_path (name : string) : bool =
  match List.rev (split_path name) with
  | last :: _ -> starts_lower last && not (List.mem name reserved_extensions)
  | [] -> false

let is_sigil (e : expression) : string option =
  match e.pexp_desc with
  | Pexp_extension ({ txt = name; _ }, PStr []) when is_value_path name -> Some name
  | _ -> None

(* Rebuild the expression a mark names. Leading capitalised segments are a
   module path (`Store.tone` is `Store`'s `tone`); once a lowercase segment
   starts, the rest are record fields (`store.count` reads the field, it does
   not look for a module named `store`). *)
let path_expression (loc : Location.t) (name : string) : expression =
  let at desc = { pexp_desc = desc; pexp_loc = loc; pexp_attributes = [] } in
  let rec modules acc = function
    | seg :: rest when not (starts_lower seg) ->
      modules (match acc with None -> Some (Longident.Lident seg) | Some p -> Some (Longident.Ldot (p, seg))) rest
    | rest -> (acc, rest)
  in
  match modules None (split_path name) with
  | prefix, first :: fields ->
    let base =
      at (Pexp_ident (mkloc (match prefix with None -> Longident.Lident first | Some p -> Longident.Ldot (p, first))))
    in
    List.fold_left (fun e field -> at (Pexp_field (e, mkloc (Longident.Lident field)))) base fields
  | Some path, [] -> at (Pexp_ident (mkloc path))
  | None, [] -> at (Pexp_ident (mkloc (Longident.Lident name)))

(* Where a marked value is read from: the module that named it when the ppx
   knows (`~label: MaybeSignal.t<string>` reads through `MaybeSignal`),
   `Signal` otherwise — which is what a mark on something the ppx cannot see
   means in practice. A wrong guess is a type error at the marked value. *)
let sigil_read (env : env) (loc : Location.t) (name : string) : expression =
  let target = path_expression loc name in
  let path = match is_sig_ident env target with Some p -> p | None -> Longident.Lident "Signal" in
  read_through loc path target

let rec rewrite_live (env : env) (e : expression) : expression =
  match is_sigil e with
  | Some name -> sigil_read env e.pexp_loc name
  | None ->
    (match e.pexp_desc with
     | Pexp_fun (l, def, p, body) ->
       { e with
         pexp_desc =
           Pexp_fun
             (l, Option.map (rewrite_live env) def, p, rewrite_live (bind_param env l def p) body) }
     | Pexp_let (r, vbs, body) ->
       let vbs' = List.map (fun vb -> { vb with pvb_expr = rewrite_live env vb.pvb_expr }) vbs in
       { e with pexp_desc = Pexp_let (r, vbs', rewrite_live (collect_val_aliases env vbs) body) }
     | Pexp_match (s, cases) ->
       let case c =
         let env = case_env env s c in
         { c with
           pc_guard = Option.map (rewrite_live env) c.pc_guard;
           pc_rhs = rewrite_live env c.pc_rhs }
       in
       { e with pexp_desc = Pexp_match (rewrite_live env s, List.map case cases) }
     | Pexp_letmodule (name, me, body) ->
       { e with pexp_desc = Pexp_letmodule (name, me, rewrite_live (collect_mod_alias env name me) body) }
     | Pexp_open (o, l, x) ->
       { e with pexp_desc = Pexp_open (o, l, rewrite_live (collect_open env l.Location.txt) x) }
     | _ -> map_sub_exprs (rewrite_live env) e)

(* Locations of every mark in a file, for the error a file that never opted in
   has to get. ReScript would reject the leftover extension by itself, but its
   message ("uninterpreted extension") names neither this ppx nor the reason,
   and the reason is the whole point: nothing here expands the mark. *)
let rec find_live (e : expression) : Location.t list =
  (if is_sigil e <> None then [ e.pexp_loc ] else []) @ List.concat_map find_live (sub_exprs e)

let rec find_live_structure (s : structure) : Location.t list =
  List.concat_map
    (fun si ->
      match si.pstr_desc with
      | Pstr_value (_, vbs) -> List.concat_map (fun vb -> find_live vb.pvb_expr) vbs
      | Pstr_eval (e, _) -> find_live e
      | Pstr_module mb -> find_live_module mb.pmb_expr
      | Pstr_recmodule mbs -> List.concat_map (fun mb -> find_live_module mb.pmb_expr) mbs
      | Pstr_include incl -> find_live_module incl.pincl_mod
      | _ -> [])
    s

and find_live_module (me : module_expr) : Location.t list =
  match me.pmod_desc with
  | Pmod_structure s -> find_live_structure s
  | Pmod_constraint (m, _) -> find_live_module m
  | Pmod_functor (_, _, b) -> find_live_module b
  | _ -> []

(* Control flow in node position: only the parts that *select* a branch are
   value position — the condition, the scrutinee and the `when` guards. The
   branch bodies are nodes and are decomposed on their own. *)
let deref_condition (env : env) (e : expression) : expression =
  match e.pexp_desc with
  | Pexp_ifthenelse (c, t, eo) -> { e with pexp_desc = Pexp_ifthenelse (deref env c, t, eo) }
  | Pexp_match (s, cases) ->
    let guard cs = { cs with pc_guard = Option.map (deref (case_env env s cs)) cs.pc_guard } in
    { e with pexp_desc = Pexp_match (deref env s, List.map guard cases) }
  | _ -> e

(* A value-position leaf: read every signal-typed name, then thunk a visible
   read, probe an unresolvable call, and leave everything else exactly as
   written. *)
let leaf_value (env : env) (v : expression) : expression =
  let v = deref env v in
  if should_thunk env v then thunk v else if should_probe env v then wrap_probe v else v

(* ---- hyphenated attributes ----------------------------------------------
   ReScript parses `<div data-hidden={…} aria-busy="true">`, but no typed prop
   can carry a hyphenated name, so the JSX transform rejects it ("The field
   data-hidden does not belong to type XoteJSX.Elements.props"). On an intrinsic
   element the ppx moves such attributes into the `attrs` escape hatch, which
   takes any key. The value has already been through `leaf_value` (a
   signal-typed name reads, an eager read is thunked, an unresolvable call is
   probed), so `data-hidden={open_}` becomes `("data-hidden", () =>
   Signal.get(open_))` and renders the literal `"true"`/`"false"` the runtime
   stringifies it to. An optional one (`data-x=?{opt}`) is moved as is: the
   runtime removes the attribute for `None`.

   Relocated entries go *before* the user's own `attrs`, so an explicit entry
   for the same key still wins — `attrs` is documented as the override. All
   entries of `attrs` share one array type, so each relocated value is passed
   through `Obj.magic`: the runtime coercion (`RuntimeJsxProp.toAttrEntry`)
   accepts every shape a typed attribute does, and the value expression itself
   is still type-checked before the cast. *)
let is_hyphenated_arg = function
  | (Labelled n | Optional n), _ -> String.contains n '-'
  | _ -> false

(* Insert a labelled arg before `~children` and the trailing `()`, so the JSX
   apply keeps its `label… children unit` shape — the JSX transform reads the
   children off the end of the argument list. *)
let rec insert_arg (arg : arg_label * expression) = function
  | ((Nolabel, _) :: _ | (Labelled "children", _) :: _ | (Optional "children", _) :: _) as tl ->
    arg :: tl
  | hd :: tl -> hd :: insert_arg arg tl
  | [] -> [ arg ]

let option_get_or = Longident.Ldot (Longident.Lident "Option", "getOr")

let relocate_hyphenated (args : (arg_label * expression) list) : (arg_label * expression) list =
  match List.partition is_hyphenated_arg args with
  | [], _ -> args
  | moved, rest ->
    let entry (lbl, v) =
      let key = match lbl with Labelled n | Optional n -> n | Nolabel -> "" in
      mkexp (Pexp_tuple [ str_const key; apply (ident obj_magic) [ v ] ])
    in
    let entries = List.map entry moved in
    let extend = function
      | Labelled "attrs", ({ pexp_desc = Pexp_array xs; _ } as a) ->
        (Labelled "attrs", { a with pexp_desc = Pexp_array (entries @ xs) })
      | Labelled "attrs", a ->
        (Labelled "attrs", apply (ident array_concat) [ mkexp (Pexp_array entries); a ])
      | Optional "attrs", a ->
        (* `attrs=?{opt}`: an `option<array<_>>` — default the missing array *)
        ( Labelled "attrs",
          apply (ident array_concat)
            [ mkexp (Pexp_array entries); apply (ident option_get_or) [ a; mkexp (Pexp_array []) ] ] )
      | other -> other
    in
    let has_attrs (l, _) = l = Labelled "attrs" || l = Optional "attrs" in
    if List.exists has_attrs rest then List.map extend rest
    else insert_arg (Labelled "attrs", mkexp (Pexp_array entries)) rest

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
       are node position; a hyphenated attribute is routed into `attrs` *)
    { e with pexp_desc = Pexp_apply (f, relocate_hyphenated (List.map (element_arg env) args)) }
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
          reactive one.

          A signal-typed name in the condition/scrutinee/guard is a read
          (`{if open_ { … }}` with `open_: Signal.t<bool>`), so it is derefed
          first — after which the visible-read rule below tracks it. *)
       let e = deref_condition env e in
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
  (* The binding forms thread the environment so a name bound here — a lambda
     parameter, a case pattern, a local `let` — shadows a signal-typed name
     from outside (and a local `let count = Signal.make(…)` introduces one).
     Everything else is the plain structural walk. *)
  match e.pexp_desc with
  | Pexp_fun (l, def, p, body) ->
    { e with
      pexp_desc =
        Pexp_fun (l, Option.map (decompose_here env) def, p, decompose_here (bind_param env l def p) body) }
  | Pexp_match (x, cases) ->
    { e with pexp_desc = Pexp_match (decompose_here env x, List.map (decompose_case env x) cases) }
  | Pexp_try (x, cases) ->
    { e with pexp_desc = Pexp_try (decompose_here env x, List.map (decompose_case env x) cases) }
  | Pexp_let (r, vbs, body) ->
    let vbs' = List.map (fun vb -> { vb with pvb_expr = decompose_here env vb.pvb_expr }) vbs in
    { e with pexp_desc = Pexp_let (r, vbs', decompose_here (collect_val_aliases env vbs) body) }
  | _ -> map_sub_exprs (decompose_here env) e

(* A case's pattern shadows for its body; the guard is a boolean, never a
   node, and is left as written (see map_sub_exprs). *)
and decompose_case (env : env) (scrutinee : expression) (c : case) : case =
  { c with pc_rhs = decompose_here (case_env env scrutinee c) c.pc_rhs }

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
    (* a case pattern shadows for its body: `| Ready(count) => {count}` reads
       the payload, not a signal of the same name *)
    let branch cs = { cs with pc_rhs = fine_node (case_env env s cs) cs.pc_rhs } in
    { e with pexp_desc = Pexp_match (s, List.map branch cases) }
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
    (* the parameter shadows, and is a signal in the body if annotated so:
       `let item = (count: Signal.t<int>) => <li> {count} </li>` *)
    { e with pexp_desc = Pexp_fun (l, def, p, fine_callback (bind_param env l def p) body) }
  | _ -> fine_node env e

and value_arg (env : env) ((lbl, v) : arg_label * expression) : arg_label * expression =
  (* A value component already renders a bare signal through one owned
     computed; a thunk there would cost a second, unowned one
     (`MaybeSignal.ofUnknown` allocates it). So a bare signal-typed name is
     left to that path, and only a derived expression is rewritten. *)
  let value v = if is_sig_ident env v <> None then v else leaf_value env v in
  if is_children_label lbl then (lbl, map_children value v)
  else
    match lbl with
    | Labelled "value" -> (lbl, value v)
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
    | Pexp_fun (l, def, p, body) -> Pexp_fun (l, def, p, map_expr (bind_param env l def p) body)
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
      let case cs = { cs with pc_rhs = map_expr (case_env env x cs) cs.pc_rhs } in
      Pexp_match (map_expr env x, List.map case cases)
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
    (* a prop annotated `Signal.t`/`MaybeSignal.t` is a signal-typed name in
       the body: `~count: Signal.t<int>` makes `{count}` a reactive leaf *)
    { e with pexp_desc = Pexp_fun (l, def, p, decompose_component_body (bind_param env l def p) body) }
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
    (* The module's *own* top-level names, classified by what they are bound
       to inside it. (Set-differencing against the outer env instead missed a
       `Store.count` whenever a top-level `count` of the same kind existed.) *)
    let own =
      List.concat_map
        (fun si ->
          match si.pstr_desc with
          | Pstr_value (_, vbs) -> List.filter_map (fun vb -> Option.map fst (simple_binding vb.pvb_pat)) vbs
          | _ -> [])
        s
    in
    let qualify n = name ^ "." ^ n in
    let funcs = List.filter (fun n -> List.mem n inner.funcs || List.mem n inner.vals) own in
    let sigs = List.filter_map (fun n -> Option.map (fun p -> (qualify n, p)) (List.assoc_opt n inner.sigs)) own in
    let fns = List.filter_map (fun n -> Option.map (fun i -> (qualify n, i)) (List.assoc_opt n inner.fns)) own in
    { env with
      qfuncs = List.map qualify funcs @ env.qfuncs;
      qsigs = sigs @ env.qsigs;
      fns = fns @ env.fns }
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

let rec live_structure (env : env) (s : structure) : structure =
  let _, rev =
    List.fold_left
      (fun (env, acc) si -> (update_env_si env si, live_si env si :: acc))
      (env, []) s
  in
  List.rev rev

and live_si (env : env) si =
  match si.pstr_desc with
  | Pstr_value (r, vbs) ->
    let vb v = { v with pvb_expr = rewrite_live env v.pvb_expr } in
    { si with pstr_desc = Pstr_value (r, List.map vb vbs) }
  | Pstr_eval (e, attrs) -> { si with pstr_desc = Pstr_eval (rewrite_live env e, attrs) }
  | Pstr_module mb -> { si with pstr_desc = Pstr_module { mb with pmb_expr = live_mod env mb.pmb_expr } }
  | Pstr_recmodule mbs ->
    { si with
      pstr_desc = Pstr_recmodule (List.map (fun mb -> { mb with pmb_expr = live_mod env mb.pmb_expr }) mbs) }
  | Pstr_include incl ->
    { si with pstr_desc = Pstr_include { incl with pincl_mod = live_mod env incl.pincl_mod } }
  | _ -> si

and live_mod (env : env) me =
  match me.pmod_desc with
  | Pmod_structure s -> { me with pmod_desc = Pmod_structure (live_structure env s) }
  | Pmod_constraint (m, mt) -> { me with pmod_desc = Pmod_constraint (live_mod env m, mt) }
  | Pmod_functor (n, mt, b) -> { me with pmod_desc = Pmod_functor (n, mt, live_mod env b) }
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
     (* A `%` mark only means anything in a file this ppx rewrites. *)
     if not !fine_grain_helpers then
       (match find_live_structure structure with
        | [] -> ()
        | sites ->
          prerr_endline
            ("xote ppx: a % signal mark at " ^ String.concat ", " (List.map site_of sites)
             ^ " but " ^ name
             ^ " has no @xote.component, so nothing here expands it. Annotate a "
             ^ "component in this file, or write the read out (Signal.get(...)).");
          exit 2);
     let structure = if !fine_grain_helpers then live_structure empty_env structure else structure in
     output_value oc (map_structure empty_env structure)
   else output_value oc payload);
  close_out oc

