module Test::Helper

import Syntax;
import AST;
import ParseTree;

import CST2AST;
import Resolve;

/* Parses a string to the CST and then immediately to the AST. */
&AST <: node parse2ast(type[&T<:Tree] begin, str input)
	= cst2ast(parse(begin, input));

/* Parses a string to the AST and immediately runs type resolution on it. */
value parseResolve(str input)
	= resolve(parse2ast(#start[Form], input));