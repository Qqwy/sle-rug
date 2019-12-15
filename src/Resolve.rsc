module Resolve

import AST;
import Syntax; // Used for testing
import CST2AST; // Used for testing


/*
 * Name resolution for QL
 */ 


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

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  return { <x.src, x.name> | /ref(AId x) := f }; 
}

Def defs(AForm f) {
  return { <s.name, s.src> | /simple_question(_, AId s, _) := f } + { <s.name, s.src> | /computed_question(_, AId s, _, _) := f }; 
}



value parseResolve(str input)
	= resolve(parse2ast(#start[Form], input));


test bool resolveEmptyForm()
	 = <{}, {}, {}> := parseResolve("form empty {}");

test bool resolveSingleQuestion()
	 = <{}, {<"my_question", _>}, {}> := parseResolve("form single { \"question?\" my_question : boolean}");

test bool resolvesSimpleUse()
	= <{<_, "foo">}, {<"foo",_>, <"bar",_>}, {<_,_>}> := parseResolve("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = foo + 2
	}
	");
	
test bool resolveCycle()
	 = <{<_, "paradox">}, {<"paradox", _>}, {<_, _>}> := parseResolve("form single { \"this statement is false\" paradox : boolean = !paradox}");
