module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import ValueIO; // for parsing simple integers, strings and booleans.
extend lang::std::Id;


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

AForm cst2ast(sf: (Form)`form <Id name> { <Question* questions> }`) {
  return form("<name>", [cst2ast(question) | question <- questions], src = sf@\loc); 
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

AQuestion cst2ast(c: (SimpleQuestion)`<Str name> <Id id> : <Type qtype>`)
	= simple_question(readTextValueString(#str, "<name>"), cst2ast(id), cst2ast(qtype), src = c@\loc);



AQuestion cst2ast(c : (ComputedQuestion)`<Str name> <Id id> : <Type ftype> = <Expr expr>`)
	= computed_question(readTextValueString(#str, "<name>"), cst2ast(id), cst2ast(ftype), cst2ast(expr), src = c@\loc);


list[AQuestion] cst2ast((Block)`{<Question *questions>}`)
	= [cst2ast(question) | question <- questions];


AConditional cst2ast(Conditional c) {
	switch(c) {
		case (Conditional)`if <Condition cond><Block ifblock> else <Block elseblock>`: return ifelse(cst2ast(cond), cst2ast(ifblock), cst2ast(elseblock), src = c@\loc);
		case (Conditional)`if <Condition cond><Block ifblock>`: return \if(cst2ast(cond), cst2ast(ifblock), src = c@\loc);
	
	    default: throw "Unhandled conditional: <c>";
	}
}

AExpr cst2ast((Condition)`(<Expr e>)`)
	= cst2ast(e);


// TODO WM: Maybe refactor to separate function heads?
//          Especially the `src=l@\loc` stuff seems repetitive.
AExpr cst2ast(Expr e) {
  switch (e) {
	case (Expr)`(<Expr expr>)`: return cst2ast(expr, src=e@\loc);
    case (Expr)`<Id x>`: return ref(cst2ast(x), src=x@\loc);
    case (Expr)`<Str literal>`: return lit(lit_string(readTextValueString(#str, "<literal>")), src=literal@\loc);
    case (Expr)`<Int literal>`: return lit(lit_integer(readTextValueString(#int, "<literal>")), src=literal@\loc);
    case (Expr)`<Bool literal>`: return lit(lit_boolean(readTextValueString(#bool, "<literal>")), src=literal@\loc);
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




// Tests: 
AId cst2ast(Id x) {
	return id("<x>", src=x@\loc);
}

&AST <: node parse2ast(type[&T<:Tree] begin, str input)
	= cst2ast(parse(begin, input));
	

test bool parsesVariable()
	= ref(AExpr::id("something")) := parse2ast(#Expr, "something");

test bool parsesPlus(int lhs, int rhs)
	= plus(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> + <rhs>");

test bool parsesMinus(int lhs, int rhs)
	= minus(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> - <rhs>");

test bool parsesMult(int lhs, int rhs)
	= mult(AExpr::lit(lit_integer(lhs)), AExpr::lit(lit_integer(rhs))) := parse2ast(#Expr, "<lhs> * <rhs>");

test bool parsesSimpleQuestion()
	= simple_question("foo", AExpr::id("val"), integer()) := parse2ast(#Question, "\"foo\" val : integer");

test bool parsesComputedQuestion(int val)
	= computed_question("foo", AExpr::id("varname"), integer(), AExpr::lit(lit_integer(val))) := parse2ast(#Question, "\"foo\" varname : integer = <val>");

test bool parsesEmptyBlock()
	= block(_) := parse2ast(#Question, "{}");

test bool parsesNestedBlock()
	= block([block([])]) := parse2ast(#Question, "{{}}");

test bool parsesIf()
	= \if(_, _) := parse2ast(#Conditional, "if (1) {\"bar\" bar : integer = 33}");

test bool parsesIfElse()
	= \ifelse(_, _, _) := parse2ast(#Conditional, "if (1) {} else {\"bar\" bar : integer = 33}");

test bool parsesForm()
	= form(_, _) := parse2ast(#Form, "form foo { \"x\" x : integer = 33}");
	