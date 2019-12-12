module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
//  Form f = sf.top; // remove layout before and after form
//  return form("", [], src=f@\loc); 
	return cst2ast(sf.top);
}

AForm cst2ast((Form)`form <Id name> { <Question* questions> }`) {
  return form("<name>", [cst2ast(question) | question <- questions]); 
}


AQuestion cst2ast(Question question) {
  switch (question) {
  	case (Question)`<SimpleQuestion q>`: return cst2ast(q);
  	case (Question)`<ComputedQuestion q>`: return cst2ast(q);
  	case (Question)`<Block b>`: return block(cst2ast(b));
  	case (Question)`<Conditional c>`: return conditional(cst2ast(c));

    default: throw "Unhandled question type: <question>";
  }
}

AQuestion cst2ast(c: (SimpleQuestion)`<Str name> <Id id> : <Type ftype>`) {
	return simple_question("<name>", <"<id>",cst2ast(ftype)>, src = c@\loc);
}


AQuestion cst2ast(c : (ComputedQuestion)`<Str name> <Id id> : <Type ftype> = <Expr expr>`) {
	return computed_question("<name>", <"<id>",cst2ast(ftype), cst2ast(expr)>, src = c@\loc);
}


list[AQuestion] cst2ast((Block)`{<Question *questions>}`) {
	return [cst2ast(question) | question <- questions];
}

AConditional cst2ast(Conditional c) {
	switch(c) {
		case (Conditional)`if <Condition cond><Block ifblock> else <Block elseblock>`: return ifelse(cst2ast(cond), cst2ast(ifblock), cst2ast(elseblock), src = c@\loc);
		case (Conditional)`if <Condition cond><Block ifblock>`: return \if(cst2ast(cond), cst2ast(ifblock), src = c@\loc);
	
	    default: throw "Unhandled conditional: <c>";
	}
}

AExpr cst2ast((Condition)`(<Expr e>)`) {
	return cst2ast(e);
}

// TODO WM: Maybe refactor to separate function heads?
//          Especially the `src=l@\loc` stuff seems repetitive.
AExpr cst2ast(Expr e) {
  switch (e) {
	case (Expr)`(<Expr expr>)`: return cst2ast(expr, src=e@\loc);
    case (Expr)`<Id x>`: return ref(cst2ast(x), src=x@\loc);
    case (Expr)`<Literal literal>`: return lit("<literal>", src=literal@\loc);
    case (Expr)`!<Expr expr>`: return not(cst2ast(expr), src=e@\loc);
    case (Expr)`<Expr lhs>*<Expr rhs>`: return mult(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>/<Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>+<Expr rhs>`: return plus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>-<Expr rhs>`: return minus(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>&&<Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>||<Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\><Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<<Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\<=<Expr rhs>`: return lte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>\>=<Expr rhs>`: return gte(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>==<Expr rhs>`: return equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs>!=<Expr rhs>`: return not_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    
    
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`boolean`: return boolean(src = t@\loc);
    case (Type)`string`: return string(src = t@\loc);
    case (Type)`integer`: return integer(src = t@\loc);
    default: throw "Unhandled type: <t>";
  };
}

AId cst2ast(Id x) {
	return id("<x>", src=x@\loc);
}


// -- AST Unit tests:
test bool simpleParsingExamples() {
	assert ref(id(_)) := cst2ast(parse(#Expr, "myvariable"));
	assert plus(lit(_), lit(_)) := cst2ast(parse(#Expr, "2 + 3"));
	assert mult(lit(_), lit(_)) := cst2ast(parse(#Expr, "2 * 3"));
	assert plus(lit(_), mult(lit(_), lit(_))) := cst2ast(parse(#Expr, "1 + 2 * 3"));
	assert plus(mult(lit(_), lit(_)), lit(_)) := cst2ast(parse(#Expr, "1 * 2 + 3"));
	assert simple_question(_, <_, _>) := cst2ast(parse(#Question, "\"foo\" val : integer"));
	assert computed_question(_, <_, _, _>) := cst2ast(parse(#Question, "\"foo\" val : integer = 42"));
	assert block(_) := cst2ast(parse(#Question, "{}"));
	assert block([block([])]) := cst2ast(parse(#Question, "{{}}"));
	assert \if(_, _) := cst2ast(parse(#Conditional, "if (1) {\"bar\" bar : integer = 33}"));
	assert \ifelse(_, _, _) := cst2ast(parse(#Conditional, "if (1) {} else {\"bar\" bar : integer = 33}"));
	assert form(_, _) := cst2ast(parse(#Form, "form foo { \"x\" x : integer = 33}"));
	return true;
}