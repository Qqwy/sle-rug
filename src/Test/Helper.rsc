module Test::Helper

import Syntax;
import AST;
import CST2AST;
import ParseTree;

/* Parses a string to the CST and then immediately to the AST. */
&AST <: node parse2ast(type[&T<:Tree] begin, str input)
	= cst2ast(parse(begin, input));