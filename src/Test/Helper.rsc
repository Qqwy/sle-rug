module Test::Helper

import Syntax;
import AST;
import ParseTree;

import CST2AST; // cst2ast
import Resolve; // resolve
import Check;   // collect, check

/* Parses a string to the CST and then immediately to the AST. */
&AST <: node parse2ast(type[&T<:Tree] begin, str input)
	= cst2ast(parse(begin, input));

/* Parses a string to the AST and immediately runs type resolution on it. */
value parseResolve(str input)
	= resolve(parse2ast(#start[Form], input));
	

/* To use on individual expressions and other snippets.
 * Will not call 'resolve' or 'collect' so reference-based checks
 * cannot be tested this way.
 */
set[Message] parseCheck(type[&T<:Tree] begin, str input) {
	ast = parse2ast(begin, input);
	return check(ast, <{}, {}>);
}

// To use on a whole form
set[Message] parseResolveCollectCheck(str input) {
	ast = parse2ast(#start[Form], input);
	// println(ast);
	RefGraph resolved = resolve(ast);
	// println(resolved);
	UseDef useDef = resolved.useDef;
	// println(useDef);
	TEnv collected = collect(ast);
	// println(collected);
	return check(ast, <collect(ast), resolve(ast).useDef>);
}