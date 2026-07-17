(* Vendored OCaml 4.06 AST (ReScript 12's ppx parsetree is Caml1999M022 = 4.06).
   Types are copied verbatim from ocaml/ocaml@4.06 so Marshal round-trips exactly. *)
module Location = struct
  type t = { loc_start : Lexing.position; loc_end : Lexing.position; loc_ghost : bool }
  type 'a loc = { txt : 'a; loc : t }
end
module Longident = struct
  type t = Lident of string | Ldot of t * string | Lapply of t * t
end
module Asttypes = struct
(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Xavier Leroy, projet Cristal, INRIA Rocquencourt           *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Auxiliary AST types used by parsetree and typedtree. *)

type constant =
    Const_int of int
  | Const_char of char
  | Const_string of string * string option
  | Const_float of string
  | Const_int32 of int32
  | Const_int64 of int64
  | Const_nativeint of nativeint

type rec_flag = Nonrecursive | Recursive

type direction_flag = Upto | Downto

(* Order matters, used in polymorphic comparison *)
type private_flag = Private | Public

type mutable_flag = Immutable | Mutable

type virtual_flag = Virtual | Concrete

type override_flag = Override | Fresh

type closed_flag = Closed | Open

type label = string

type arg_label =
    Nolabel
  | Labelled of string (*  label:T -> ... *)
  | Optional of string (* ?label:T -> ... *)

type 'a loc = 'a Location.loc = {
  txt : 'a;
  loc : Location.t;
}


type variance =
  | Covariant
  | Contravariant
  | Invariant
end
module Parsetree = struct
(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*             Xavier Leroy, projet Cristal, INRIA Rocquencourt           *)
(*                                                                        *)
(*   Copyright 1996 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Abstract syntax tree produced by parsing *)

open Asttypes

type constant =
    Pconst_integer of string * char option
  (* 3 3l 3L 3n

     Suffixes [g-z][G-Z] are accepted by the parser.
     Suffixes except 'l', 'L' and 'n' are rejected by the typechecker
  *)
  | Pconst_char of char
  (* 'c' *)
  | Pconst_string of string * string option
  (* "constant"
     {delim|other constant|delim}
  *)
  | Pconst_float of string * char option
  (* 3.4 2e5 1.4e-4

     Suffixes [g-z][G-Z] are accepted by the parser.
     Suffixes are rejected by the typechecker.
  *)

(** {1 Extension points} *)

type attribute = string loc * payload
       (* [@id ARG]
          [@@id ARG]

          Metadata containers passed around within the AST.
          The compiler ignores unknown attributes.
       *)

and extension = string loc * payload
      (* [%id ARG]
         [%%id ARG]

         Sub-language placeholder -- rejected by the typechecker.
      *)

and attributes = attribute list

and payload =
  | PStr of structure
  | PSig of signature (* : SIG *)
  | PTyp of core_type  (* : T *)
  | PPat of pattern * expression option  (* ? P  or  ? P when E *)

(** {1 Core language} *)

(* Type expressions *)

and core_type =
    {
     ptyp_desc: core_type_desc;
     ptyp_loc: Location.t;
     ptyp_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and core_type_desc =
  | Ptyp_any
        (*  _ *)
  | Ptyp_var of string
        (* 'a *)
  | Ptyp_arrow of arg_label * core_type * core_type
        (* T1 -> T2       Simple
           ~l:T1 -> T2    Labelled
           ?l:T1 -> T2    Optional
         *)
  | Ptyp_tuple of core_type list
        (* T1 * ... * Tn

           Invariant: n >= 2
        *)
  | Ptyp_constr of Longident.t loc * core_type list
        (* tconstr
           T tconstr
           (T1, ..., Tn) tconstr
         *)
  | Ptyp_object of object_field list * closed_flag
        (* < l1:T1; ...; ln:Tn >     (flag = Closed)
           < l1:T1; ...; ln:Tn; .. > (flag = Open)
         *)
  | Ptyp_class of Longident.t loc * core_type list
        (* #tconstr
           T #tconstr
           (T1, ..., Tn) #tconstr
         *)
  | Ptyp_alias of core_type * string
        (* T as 'a *)
  | Ptyp_variant of row_field list * closed_flag * label list option
        (* [ `A|`B ]         (flag = Closed; labels = None)
           [> `A|`B ]        (flag = Open;   labels = None)
           [< `A|`B ]        (flag = Closed; labels = Some [])
           [< `A|`B > `X `Y ](flag = Closed; labels = Some ["X";"Y"])
         *)
  | Ptyp_poly of string loc list * core_type
        (* 'a1 ... 'an. T

           Can only appear in the following context:

           - As the core_type of a Ppat_constraint node corresponding
             to a constraint on a let-binding: let x : 'a1 ... 'an. T
             = e ...

           - Under Cfk_virtual for methods (not values).

           - As the core_type of a Pctf_method node.

           - As the core_type of a Pexp_poly node.

           - As the pld_type field of a label_declaration.

           - As a core_type of a Ptyp_object node.
         *)

  | Ptyp_package of package_type
        (* (module S) *)
  | Ptyp_extension of extension
        (* [%id] *)

and package_type = Longident.t loc * (Longident.t loc * core_type) list
      (*
        (module S)
        (module S with type t1 = T1 and ... and tn = Tn)
       *)

and row_field =
  | Rtag of label loc * attributes * bool * core_type list
        (* [`A]                   ( true,  [] )
           [`A of T]              ( false, [T] )
           [`A of T1 & .. & Tn]   ( false, [T1;...Tn] )
           [`A of & T1 & .. & Tn] ( true,  [T1;...Tn] )

          - The 2nd field is true if the tag contains a
            constant (empty) constructor.
          - '&' occurs when several types are used for the same constructor
            (see 4.2 in the manual)

          - TODO: switch to a record representation, and keep location
        *)
  | Rinherit of core_type
        (* [ T ] *)

and object_field =
  | Otag of label loc * attributes * core_type
  | Oinherit of core_type

(* Patterns *)

and pattern =
    {
     ppat_desc: pattern_desc;
     ppat_loc: Location.t;
     ppat_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and pattern_desc =
  | Ppat_any
        (* _ *)
  | Ppat_var of string loc
        (* x *)
  | Ppat_alias of pattern * string loc
        (* P as 'a *)
  | Ppat_constant of constant
        (* 1, 'a', "true", 1.0, 1l, 1L, 1n *)
  | Ppat_interval of constant * constant
        (* 'a'..'z'

           Other forms of interval are recognized by the parser
           but rejected by the type-checker. *)
  | Ppat_tuple of pattern list
        (* (P1, ..., Pn)

           Invariant: n >= 2
        *)
  | Ppat_construct of Longident.t loc * pattern option
        (* C                None
           C P              Some P
           C (P1, ..., Pn)  Some (Ppat_tuple [P1; ...; Pn])
         *)
  | Ppat_variant of label * pattern option
        (* `A             (None)
           `A P           (Some P)
         *)
  | Ppat_record of (Longident.t loc * pattern) list * closed_flag
        (* { l1=P1; ...; ln=Pn }     (flag = Closed)
           { l1=P1; ...; ln=Pn; _}   (flag = Open)

           Invariant: n > 0
         *)
  | Ppat_array of pattern list
        (* [| P1; ...; Pn |] *)
  | Ppat_or of pattern * pattern
        (* P1 | P2 *)
  | Ppat_constraint of pattern * core_type
        (* (P : T) *)
  | Ppat_type of Longident.t loc
        (* #tconst *)
  | Ppat_lazy of pattern
        (* lazy P *)
  | Ppat_unpack of string loc
        (* (module P)
           Note: (module P : S) is represented as
           Ppat_constraint(Ppat_unpack, Ptyp_package)
         *)
  | Ppat_exception of pattern
        (* exception P *)
  | Ppat_extension of extension
        (* [%id] *)
  | Ppat_open of Longident.t loc * pattern
        (* M.(P) *)

(* Value expressions *)

and expression =
    {
     pexp_desc: expression_desc;
     pexp_loc: Location.t;
     pexp_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and expression_desc =
  | Pexp_ident of Longident.t loc
        (* x
           M.x
         *)
  | Pexp_constant of constant
        (* 1, 'a', "true", 1.0, 1l, 1L, 1n *)
  | Pexp_let of rec_flag * value_binding list * expression
        (* let P1 = E1 and ... and Pn = EN in E       (flag = Nonrecursive)
           let rec P1 = E1 and ... and Pn = EN in E   (flag = Recursive)
         *)
  | Pexp_function of case list
        (* function P1 -> E1 | ... | Pn -> En *)
  | Pexp_fun of arg_label * expression option * pattern * expression
        (* fun P -> E1                          (Simple, None)
           fun ~l:P -> E1                       (Labelled l, None)
           fun ?l:P -> E1                       (Optional l, None)
           fun ?l:(P = E0) -> E1                (Optional l, Some E0)

           Notes:
           - If E0 is provided, only Optional is allowed.
           - "fun P1 P2 .. Pn -> E1" is represented as nested Pexp_fun.
           - "let f P = E" is represented using Pexp_fun.
         *)
  | Pexp_apply of expression * (arg_label * expression) list
        (* E0 ~l1:E1 ... ~ln:En
           li can be empty (non labeled argument) or start with '?'
           (optional argument).

           Invariant: n > 0
         *)
  | Pexp_match of expression * case list
        (* match E0 with P1 -> E1 | ... | Pn -> En *)
  | Pexp_try of expression * case list
        (* try E0 with P1 -> E1 | ... | Pn -> En *)
  | Pexp_tuple of expression list
        (* (E1, ..., En)

           Invariant: n >= 2
        *)
  | Pexp_construct of Longident.t loc * expression option
        (* C                None
           C E              Some E
           C (E1, ..., En)  Some (Pexp_tuple[E1;...;En])
        *)
  | Pexp_variant of label * expression option
        (* `A             (None)
           `A E           (Some E)
         *)
  | Pexp_record of (Longident.t loc * expression) list * expression option
        (* { l1=P1; ...; ln=Pn }     (None)
           { E0 with l1=P1; ...; ln=Pn }   (Some E0)

           Invariant: n > 0
         *)
  | Pexp_field of expression * Longident.t loc
        (* E.l *)
  | Pexp_setfield of expression * Longident.t loc * expression
        (* E1.l <- E2 *)
  | Pexp_array of expression list
        (* [| E1; ...; En |] *)
  | Pexp_ifthenelse of expression * expression * expression option
        (* if E1 then E2 else E3 *)
  | Pexp_sequence of expression * expression
        (* E1; E2 *)
  | Pexp_while of expression * expression
        (* while E1 do E2 done *)
  | Pexp_for of
      pattern *  expression * expression * direction_flag * expression
        (* for i = E1 to E2 do E3 done      (flag = Upto)
           for i = E1 downto E2 do E3 done  (flag = Downto)
         *)
  | Pexp_constraint of expression * core_type
        (* (E : T) *)
  | Pexp_coerce of expression * core_type option * core_type
        (* (E :> T)        (None, T)
           (E : T0 :> T)   (Some T0, T)
         *)
  | Pexp_send of expression * label loc
        (*  E # m *)
  | Pexp_new of Longident.t loc
        (* new M.c *)
  | Pexp_setinstvar of label loc * expression
        (* x <- 2 *)
  | Pexp_override of (label loc * expression) list
        (* {< x1 = E1; ...; Xn = En >} *)
  | Pexp_letmodule of string loc * module_expr * expression
        (* let module M = ME in E *)
  | Pexp_letexception of extension_constructor * expression
        (* let exception C in E *)
  | Pexp_assert of expression
        (* assert E
           Note: "assert false" is treated in a special way by the
           type-checker. *)
  | Pexp_lazy of expression
        (* lazy E *)
  | Pexp_poly of expression * core_type option
        (* Used for method bodies.

           Can only be used as the expression under Cfk_concrete
           for methods (not values). *)
  | Pexp_object of class_structure
        (* object ... end *)
  | Pexp_newtype of string loc * expression
        (* fun (type t) -> E *)
  | Pexp_pack of module_expr
        (* (module ME)

           (module ME : S) is represented as
           Pexp_constraint(Pexp_pack, Ptyp_package S) *)
  | Pexp_open of override_flag * Longident.t loc * expression
        (* M.(E)
           let open M in E
           let! open M in E *)
  | Pexp_extension of extension
        (* [%id] *)
  | Pexp_unreachable
        (* . *)

and case =   (* (P -> E) or (P when E0 -> E) *)
    {
     pc_lhs: pattern;
     pc_guard: expression option;
     pc_rhs: expression;
    }

(* Value descriptions *)

and value_description =
    {
     pval_name: string loc;
     pval_type: core_type;
     pval_prim: string list;
     pval_attributes: attributes;  (* ... [@@id1] [@@id2] *)
     pval_loc: Location.t;
    }

(*
  val x: T                            (prim = [])
  external x: T = "s1" ... "sn"       (prim = ["s1";..."sn"])
*)

(* Type declarations *)

and type_declaration =
    {
     ptype_name: string loc;
     ptype_params: (core_type * variance) list;
           (* ('a1,...'an) t; None represents  _*)
     ptype_cstrs: (core_type * core_type * Location.t) list;
           (* ... constraint T1=T1'  ... constraint Tn=Tn' *)
     ptype_kind: type_kind;
     ptype_private: private_flag;   (* = private ... *)
     ptype_manifest: core_type option;  (* = T *)
     ptype_attributes: attributes;   (* ... [@@id1] [@@id2] *)
     ptype_loc: Location.t;
    }

(*
  type t                     (abstract, no manifest)
  type t = T0                (abstract, manifest=T0)
  type t = C of T | ...      (variant,  no manifest)
  type t = T0 = C of T | ... (variant,  manifest=T0)
  type t = {l: T; ...}       (record,   no manifest)
  type t = T0 = {l : T; ...} (record,   manifest=T0)
  type t = ..                (open,     no manifest)
*)

and type_kind =
  | Ptype_abstract
  | Ptype_variant of constructor_declaration list
        (* Invariant: non-empty list *)
  | Ptype_record of label_declaration list
        (* Invariant: non-empty list *)
  | Ptype_open

and label_declaration =
    {
     pld_name: string loc;
     pld_mutable: mutable_flag;
     pld_type: core_type;
     pld_loc: Location.t;
     pld_attributes: attributes; (* l : T [@id1] [@id2] *)
    }

(*  { ...; l: T; ... }            (mutable=Immutable)
    { ...; mutable l: T; ... }    (mutable=Mutable)

    Note: T can be a Ptyp_poly.
*)

and constructor_declaration =
    {
     pcd_name: string loc;
     pcd_args: constructor_arguments;
     pcd_res: core_type option;
     pcd_loc: Location.t;
     pcd_attributes: attributes; (* C of ... [@id1] [@id2] *)
    }

and constructor_arguments =
  | Pcstr_tuple of core_type list
  | Pcstr_record of label_declaration list

(*
  | C of T1 * ... * Tn     (res = None,    args = Pcstr_tuple [])
  | C: T0                  (res = Some T0, args = [])
  | C: T1 * ... * Tn -> T0 (res = Some T0, args = Pcstr_tuple)
  | C of {...}             (res = None,    args = Pcstr_record)
  | C: {...} -> T0         (res = Some T0, args = Pcstr_record)
  | C of {...} as t        (res = None,    args = Pcstr_record)
*)

and type_extension =
    {
     ptyext_path: Longident.t loc;
     ptyext_params: (core_type * variance) list;
     ptyext_constructors: extension_constructor list;
     ptyext_private: private_flag;
     ptyext_attributes: attributes;   (* ... [@@id1] [@@id2] *)
    }
(*
  type t += ...
*)

and extension_constructor =
    {
     pext_name: string loc;
     pext_kind : extension_constructor_kind;
     pext_loc : Location.t;
     pext_attributes: attributes; (* C of ... [@id1] [@id2] *)
    }

and extension_constructor_kind =
    Pext_decl of constructor_arguments * core_type option
      (*
         | C of T1 * ... * Tn     ([T1; ...; Tn], None)
         | C: T0                  ([], Some T0)
         | C: T1 * ... * Tn -> T0 ([T1; ...; Tn], Some T0)
       *)
  | Pext_rebind of Longident.t loc
      (*
         | C = D
       *)

(** {1 Class language} *)

(* Type expressions for the class language *)

and class_type =
    {
     pcty_desc: class_type_desc;
     pcty_loc: Location.t;
     pcty_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and class_type_desc =
  | Pcty_constr of Longident.t loc * core_type list
        (* c
           ['a1, ..., 'an] c *)
  | Pcty_signature of class_signature
        (* object ... end *)
  | Pcty_arrow of arg_label * core_type * class_type
        (* T -> CT       Simple
           ~l:T -> CT    Labelled l
           ?l:T -> CT    Optional l
         *)
  | Pcty_extension of extension
        (* [%id] *)
  | Pcty_open of override_flag * Longident.t loc * class_type
        (* let open M in CT *)

and class_signature =
    {
     pcsig_self: core_type;
     pcsig_fields: class_type_field list;
    }
(* object('selfpat) ... end
   object ... end             (self = Ptyp_any)
 *)

and class_type_field =
    {
     pctf_desc: class_type_field_desc;
     pctf_loc: Location.t;
     pctf_attributes: attributes; (* ... [@@id1] [@@id2] *)
    }

and class_type_field_desc =
  | Pctf_inherit of class_type
        (* inherit CT *)
  | Pctf_val of (label loc * mutable_flag * virtual_flag * core_type)
        (* val x: T *)
  | Pctf_method  of (label loc * private_flag * virtual_flag * core_type)
        (* method x: T

           Note: T can be a Ptyp_poly.
         *)
  | Pctf_constraint  of (core_type * core_type)
        (* constraint T1 = T2 *)
  | Pctf_attribute of attribute
        (* [@@@id] *)
  | Pctf_extension of extension
        (* [%%id] *)

and 'a class_infos =
    {
     pci_virt: virtual_flag;
     pci_params: (core_type * variance) list;
     pci_name: string loc;
     pci_expr: 'a;
     pci_loc: Location.t;
     pci_attributes: attributes;  (* ... [@@id1] [@@id2] *)
    }
(* class c = ...
   class ['a1,...,'an] c = ...
   class virtual c = ...

   Also used for "class type" declaration.
*)

and class_description = class_type class_infos

and class_type_declaration = class_type class_infos

(* Value expressions for the class language *)

and class_expr =
    {
     pcl_desc: class_expr_desc;
     pcl_loc: Location.t;
     pcl_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and class_expr_desc =
  | Pcl_constr of Longident.t loc * core_type list
        (* c
           ['a1, ..., 'an] c *)
  | Pcl_structure of class_structure
        (* object ... end *)
  | Pcl_fun of arg_label * expression option * pattern * class_expr
        (* fun P -> CE                          (Simple, None)
           fun ~l:P -> CE                       (Labelled l, None)
           fun ?l:P -> CE                       (Optional l, None)
           fun ?l:(P = E0) -> CE                (Optional l, Some E0)
         *)
  | Pcl_apply of class_expr * (arg_label * expression) list
        (* CE ~l1:E1 ... ~ln:En
           li can be empty (non labeled argument) or start with '?'
           (optional argument).

           Invariant: n > 0
         *)
  | Pcl_let of rec_flag * value_binding list * class_expr
        (* let P1 = E1 and ... and Pn = EN in CE      (flag = Nonrecursive)
           let rec P1 = E1 and ... and Pn = EN in CE  (flag = Recursive)
         *)
  | Pcl_constraint of class_expr * class_type
        (* (CE : CT) *)
  | Pcl_extension of extension
  (* [%id] *)
  | Pcl_open of override_flag * Longident.t loc * class_expr
  (* let open M in CE *)


and class_structure =
    {
     pcstr_self: pattern;
     pcstr_fields: class_field list;
    }
(* object(selfpat) ... end
   object ... end           (self = Ppat_any)
 *)

and class_field =
    {
     pcf_desc: class_field_desc;
     pcf_loc: Location.t;
     pcf_attributes: attributes; (* ... [@@id1] [@@id2] *)
    }

and class_field_desc =
  | Pcf_inherit of override_flag * class_expr * string loc option
        (* inherit CE
           inherit CE as x
           inherit! CE
           inherit! CE as x
         *)
  | Pcf_val of (label loc * mutable_flag * class_field_kind)
        (* val x = E
           val virtual x: T
         *)
  | Pcf_method of (label loc * private_flag * class_field_kind)
        (* method x = E            (E can be a Pexp_poly)
           method virtual x: T     (T can be a Ptyp_poly)
         *)
  | Pcf_constraint of (core_type * core_type)
        (* constraint T1 = T2 *)
  | Pcf_initializer of expression
        (* initializer E *)
  | Pcf_attribute of attribute
        (* [@@@id] *)
  | Pcf_extension of extension
        (* [%%id] *)

and class_field_kind =
  | Cfk_virtual of core_type
  | Cfk_concrete of override_flag * expression

and class_declaration = class_expr class_infos

(** {1 Module language} *)

(* Type expressions for the module language *)

and module_type =
    {
     pmty_desc: module_type_desc;
     pmty_loc: Location.t;
     pmty_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and module_type_desc =
  | Pmty_ident of Longident.t loc
        (* S *)
  | Pmty_signature of signature
        (* sig ... end *)
  | Pmty_functor of string loc * module_type option * module_type
        (* functor(X : MT1) -> MT2 *)
  | Pmty_with of module_type * with_constraint list
        (* MT with ... *)
  | Pmty_typeof of module_expr
        (* module type of ME *)
  | Pmty_extension of extension
        (* [%id] *)
  | Pmty_alias of Longident.t loc
        (* (module M) *)

and signature = signature_item list

and signature_item =
    {
     psig_desc: signature_item_desc;
     psig_loc: Location.t;
    }

and signature_item_desc =
  | Psig_value of value_description
        (*
          val x: T
          external x: T = "s1" ... "sn"
         *)
  | Psig_type of rec_flag * type_declaration list
        (* type t1 = ... and ... and tn = ... *)
  | Psig_typext of type_extension
        (* type t1 += ... *)
  | Psig_exception of extension_constructor
        (* exception C of T *)
  | Psig_module of module_declaration
        (* module X : MT *)
  | Psig_recmodule of module_declaration list
        (* module rec X1 : MT1 and ... and Xn : MTn *)
  | Psig_modtype of module_type_declaration
        (* module type S = MT
           module type S *)
  | Psig_open of open_description
        (* open X *)
  | Psig_include of include_description
        (* include MT *)
  | Psig_class of class_description list
        (* class c1 : ... and ... and cn : ... *)
  | Psig_class_type of class_type_declaration list
        (* class type ct1 = ... and ... and ctn = ... *)
  | Psig_attribute of attribute
        (* [@@@id] *)
  | Psig_extension of extension * attributes
        (* [%%id] *)

and module_declaration =
    {
     pmd_name: string loc;
     pmd_type: module_type;
     pmd_attributes: attributes; (* ... [@@id1] [@@id2] *)
     pmd_loc: Location.t;
    }
(* S : MT *)

and module_type_declaration =
    {
     pmtd_name: string loc;
     pmtd_type: module_type option;
     pmtd_attributes: attributes; (* ... [@@id1] [@@id2] *)
     pmtd_loc: Location.t;
    }
(* S = MT
   S       (abstract module type declaration, pmtd_type = None)
*)

and open_description =
    {
     popen_lid: Longident.t loc;
     popen_override: override_flag;
     popen_loc: Location.t;
     popen_attributes: attributes;
    }
(* open! X - popen_override = Override (silences the 'used identifier
                              shadowing' warning)
   open  X - popen_override = Fresh
 *)

and 'a include_infos =
    {
     pincl_mod: 'a;
     pincl_loc: Location.t;
     pincl_attributes: attributes;
    }

and include_description = module_type include_infos
(* include MT *)

and include_declaration = module_expr include_infos
(* include ME *)

and with_constraint =
  | Pwith_type of Longident.t loc * type_declaration
        (* with type X.t = ...

           Note: the last component of the longident must match
           the name of the type_declaration. *)
  | Pwith_module of Longident.t loc * Longident.t loc
        (* with module X.Y = Z *)
  | Pwith_typesubst of Longident.t loc * type_declaration
        (* with type X.t := ..., same format as [Pwith_type] *)
  | Pwith_modsubst of Longident.t loc * Longident.t loc
        (* with module X.Y := Z *)

(* Value expressions for the module language *)

and module_expr =
    {
     pmod_desc: module_expr_desc;
     pmod_loc: Location.t;
     pmod_attributes: attributes; (* ... [@id1] [@id2] *)
    }

and module_expr_desc =
  | Pmod_ident of Longident.t loc
        (* X *)
  | Pmod_structure of structure
        (* struct ... end *)
  | Pmod_functor of string loc * module_type option * module_expr
        (* functor(X : MT1) -> ME *)
  | Pmod_apply of module_expr * module_expr
        (* ME1(ME2) *)
  | Pmod_constraint of module_expr * module_type
        (* (ME : MT) *)
  | Pmod_unpack of expression
        (* (val E) *)
  | Pmod_extension of extension
        (* [%id] *)

and structure = structure_item list

and structure_item =
    {
     pstr_desc: structure_item_desc;
     pstr_loc: Location.t;
    }

and structure_item_desc =
  | Pstr_eval of expression * attributes
        (* E *)
  | Pstr_value of rec_flag * value_binding list
        (* let P1 = E1 and ... and Pn = EN       (flag = Nonrecursive)
           let rec P1 = E1 and ... and Pn = EN   (flag = Recursive)
         *)
  | Pstr_primitive of value_description
        (*  val x: T
            external x: T = "s1" ... "sn" *)
  | Pstr_type of rec_flag * type_declaration list
        (* type t1 = ... and ... and tn = ... *)
  | Pstr_typext of type_extension
        (* type t1 += ... *)
  | Pstr_exception of extension_constructor
        (* exception C of T
           exception C = M.X *)
  | Pstr_module of module_binding
        (* module X = ME *)
  | Pstr_recmodule of module_binding list
        (* module rec X1 = ME1 and ... and Xn = MEn *)
  | Pstr_modtype of module_type_declaration
        (* module type S = MT *)
  | Pstr_open of open_description
        (* open X *)
  | Pstr_class of class_declaration list
        (* class c1 = ... and ... and cn = ... *)
  | Pstr_class_type of class_type_declaration list
        (* class type ct1 = ... and ... and ctn = ... *)
  | Pstr_include of include_declaration
        (* include ME *)
  | Pstr_attribute of attribute
        (* [@@@id] *)
  | Pstr_extension of extension * attributes
        (* [%%id] *)

and value_binding =
  {
    pvb_pat: pattern;
    pvb_expr: expression;
    pvb_attributes: attributes;
    pvb_loc: Location.t;
  }

and module_binding =
    {
     pmb_name: string loc;
     pmb_expr: module_expr;
     pmb_attributes: attributes;
     pmb_loc: Location.t;
    }
(* X = ME *)

(** {1 Toplevel} *)

(* Toplevel phrases *)

type toplevel_phrase =
  | Ptop_def of structure
  | Ptop_dir of string * directive_argument
     (* #use, #load ... *)

and directive_argument =
  | Pdir_none
  | Pdir_string of string
  | Pdir_int of string * char option
  | Pdir_ident of Longident.t
  | Pdir_bool of bool
end


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

(* ---- signal-read detection ----------------------------------------------
   A read is any occurrence of `Signal.get` (applied or not). Beyond the
   literal `Signal.get` / `X.Signal.get`, an alias environment threaded through
   the traversal also recognises indirect reads:
     - a value alias:  `let g = Signal.get` then `g(sig)`
     - a module alias: `module S = Signal` then `S.get(sig)`
     - an open:        `open Signal` then a bare `get(sig)`
   The environment is scoped by the traversal (aliases visible only after their
   binding); shadowing an alias with a non-alias removes it. *)
type env = { vals : string list; mods : string list; open_signal : bool }
let empty_env = { vals = []; mods = []; open_signal = false }

let is_signal_get (env : env) (e : expression) : bool =
  match e.pexp_desc with
  | Pexp_ident { txt = Longident.Ldot (m, "get"); _ } ->
    (match m with
     | Longident.Lident "Signal" -> true
     | Longident.Ldot (_, "Signal") -> true
     | Longident.Lident name -> List.mem name env.mods
     | _ -> false)
  | Pexp_ident { txt = Longident.Lident name; _ } ->
    List.mem name env.vals || (env.open_signal && name = "get")
  | _ -> false

let sub_exprs (e : expression) : expression list =
  match e.pexp_desc with
  | Pexp_apply (f, args) -> f :: List.map snd args
  | Pexp_ifthenelse (c, t, eo) -> c :: t :: (match eo with Some x -> [ x ] | None -> [])
  | Pexp_match (x, cases) | Pexp_try (x, cases) -> x :: List.map (fun c -> c.pc_rhs) cases
  | Pexp_construct (_, Some x) -> [ x ]
  | Pexp_tuple xs | Pexp_array xs -> xs
  | Pexp_field (x, _) -> [ x ]
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

let rec reads_signal (env : env) (e : expression) : bool =
  is_signal_get env e || List.exists (reads_signal env) (sub_exprs e)

(* ---- alias collectors --------------------------------------------------- *)
(* `let g = Signal.get` (or an already-known alias) binds `g` as a read;
   `let g = <not a read>` shadows away any previous alias named `g`. *)
let collect_val_aliases (env : env) (vbs : value_binding list) : env =
  List.fold_left
    (fun env vb ->
      match vb.pvb_pat.ppat_desc with
      | Ppat_var { txt = name; _ } ->
        if is_signal_get env vb.pvb_expr then { env with vals = name :: env.vals }
        else { env with vals = List.filter (fun n -> n <> name) env.vals }
      | _ -> env)
    env vbs

let is_signal_module (me : module_expr) : bool =
  match me.pmod_desc with
  | Pmod_ident { txt = Longident.Lident "Signal"; _ } -> true
  | Pmod_ident { txt = Longident.Ldot (_, "Signal"); _ } -> true
  | _ -> false

let collect_mod_alias (env : env) (name : string Location.loc) (me : module_expr) : env =
  if is_signal_module me then { env with mods = name.Location.txt :: env.mods } else env

let is_signal_lid = function
  | Longident.Lident "Signal" -> true
  | Longident.Ldot (_, "Signal") -> true
  | _ -> false

let collect_open (env : env) (lid : Longident.t) : env =
  if is_signal_lid lid then { env with open_signal = true } else env

(* ---- JSX shape helpers -------------------------------------------------- *)
let has_jsx (e : expression) : bool =
  List.exists (fun ((n : string Location.loc), _) -> n.Location.txt = "JSX") e.pexp_attributes

let jsx_parts (e : expression) =
  match e.pexp_desc with
  | Pexp_apply (f, args) when has_jsx e -> Some (f, args)
  | _ -> None

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

let is_children_label = function
  | Labelled "children" | Optional "children" -> true
  | _ -> false

(* ---- decomposition ------------------------------------------------------ *)
let rec fine_node (env : env) (e : expression) : expression =
  match jsx_parts e with
  | Some (f, args) when is_value_component f ->
    { e with pexp_desc = Pexp_apply (f, List.map (value_arg env) args) }
  | Some (f, args) ->
    (* element or user component: attrs are value position, children nodes *)
    { e with pexp_desc = Pexp_apply (f, List.map (element_arg env) args) }
  | None ->
    (* not a JSX element: a bare child expression in node position. A signal
       read here means the *node structure* varies, which needs View.tracked.
       But first recurse fine-grained into each branch body: that turns the
       branches' leaves into thunks, so when the tracked scope runs a branch to
       build its nodes the thunks are not invoked — the scope ends up tracking
       only the condition/scrutinee (the eager reads), while a leaf inside a
       branch keeps its own reactive scope. Net effect: changing a signal that
       only a branch leaf reads updates just that leaf and does NOT re-run the
       switch or rebuild the branch. *)
    if reads_signal env e then wrap_tracked (decompose_branches env e) else e

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
         computed attribute; leave plain JSX/static values untouched. *)
      if reads_signal env v && jsx_parts v = None then (lbl, thunk v) else (lbl, v)
    | Nolabel -> (lbl, v)

and value_arg (env : env) ((lbl, v) : arg_label * expression) : arg_label * expression =
  if is_children_label lbl then (lbl, map_children (value_leaf env) v)
  else
    match lbl with
    | Labelled "value" -> (lbl, if reads_signal env v then thunk v else v)
    | _ -> (lbl, v)

(* child of a value component (View.Text ...): value position -> thunk. *)
and value_leaf (env : env) (v : expression) : expression =
  if reads_signal env v && jsx_parts v = None then thunk v else v

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
(* `@xote.component` is the single annotation: it derives props exactly like
   `@jsx.component` (which we emit for the JSX transform to expand) *and*
   fine-grained-decomposes the returned JSX. One attribute replaces
   `@jsx.component` and makes the whole component tracked. *)
let is_xote_component ((name, _) : attribute) = name.Location.txt = "xote.component"
let strip_xote_component = List.filter (fun a -> not (is_xote_component a))
let jsx_component_attr : attribute = (mkloc "jsx.component", PStr [])

let rec map_expr (env : env) (e : expression) : expression = map_children_expr env e

and map_children_expr (env : env) (e : expression) : expression =
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
  | Pexp_let (r, vbs, body) ->
    let vbs' = List.map (map_vb env) vbs in
    let env' = collect_val_aliases env vbs in
    { e with pexp_desc = Pexp_let (r, vbs', decompose_component_body env' body) }
  | Pexp_letmodule (name, me, body) ->
    let env' = collect_mod_alias env name me in
    { e with pexp_desc = Pexp_letmodule (name, me, decompose_component_body env' body) }
  | Pexp_open (o, l, x) ->
    let env' = collect_open env l.Location.txt in
    { e with pexp_desc = Pexp_open (o, l, decompose_component_body env' x) }
  | Pexp_sequence (a, b) ->
    { e with pexp_desc = Pexp_sequence (map_expr env a, decompose_component_body env b) }
  | Pexp_constraint (x, t) ->
    { e with pexp_desc = Pexp_constraint (decompose_component_body env x, t) }
  | _ -> fine_node env e

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
  | Pstr_module mb -> collect_mod_alias env mb.pmb_name mb.pmb_expr
  | Pstr_open od -> collect_open env od.popen_lid.Location.txt
  | _ -> env

and map_si (env : env) si =
  match si.pstr_desc with
  | Pstr_value (r, vbs) -> { si with pstr_desc = Pstr_value (r, List.map (map_vb env) vbs) }
  | Pstr_module mb -> { si with pstr_desc = Pstr_module (map_mb env mb) }
  | Pstr_eval (e, attrs) -> { si with pstr_desc = Pstr_eval (map_expr env e, attrs) }
  | _ -> si

and map_mb (env : env) mb = { mb with pmb_expr = map_mod env mb.pmb_expr }
and map_mod (env : env) me =
  match me.pmod_desc with
  | Pmod_structure s -> { me with pmod_desc = Pmod_structure (map_structure env s) }
  | _ -> me

(* ---- ReScript -ppx binary protocol: `ppx <infile> <outfile>` ------------ *)
let impl_magic = "Caml1999M022"
let () =
  let n = Array.length Sys.argv in
  let infile = Sys.argv.(n - 2) and outfile = Sys.argv.(n - 1) in
  let ic = open_in_bin infile in
  let magic = really_input_string ic (String.length impl_magic) in
  let name : string = input_value ic in
  let payload : Obj.t = input_value ic in
  close_in ic;
  let oc = open_out_bin outfile in
  output_string oc magic;
  output_value oc name;
  (if magic = impl_magic then output_value oc (map_structure empty_env (Obj.magic payload : structure))
   else output_value oc payload);
  close_out oc
