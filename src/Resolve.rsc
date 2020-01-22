module Resolve

/*
 * Performs name resolution for QL
 */ 
 
import AST;

// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) 
  = <us, ds, us o ds>
    when Use us := uses(f), 
         Def ds := defs(f);

Use uses(AForm f)
  = { <x.src, x.name> | /ref(AId x) := f }; 

Def defs(AForm f)
  = { <s.name, s.src> | /simple_question(_, AId s, _) := f } 
  + { <s.name, s.src> | /computed_question(_, AId s, _, _) := f }
  ;