module Test::Helper

import Syntax;
import AST;
import CST2AST; // cst2ast
import Resolve; // resolve
import Check;   // collect, check
import Compile; // compile

import ParseTree;

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

/* Compiles a QL form from an input string,
 * and writes the output to temporary files.
 * Allows you to pass in a source location manually, 
 * which allows us to use small strings as well as files.
 * Do note that we _always_ compile, even when `check` would return warnings or errors.
 */
void compileFromString(str inputForm, loc src) {
	t = parse(#start[Form], inputForm);
	if (start[Form] pt := t) {
		
        AForm ast = cst2ast(pt);
        ast.src = src;
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        set[Message] errors = {E | E <- msgs, error(_) := E || error(_, _) := E};
        if (errors == {}) {
	        return compile(ast);
        }
      }
  throw {error("Not a form", t@\loc)};
}