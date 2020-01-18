module Test::Resolve

import Test::Helper;

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
