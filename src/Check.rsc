module Check

import AST;
import Resolve;
import Message; // see standard library
import IO; //todo: remove

import CST2AST; // For testing
import Syntax; // For testing
import ParseTree; // For testing


data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  return 
    { <label.src, name, label.name, atype2type(qtype)> | q: /simple_question(str name, AId label, AType qtype) := f } 
  + { <label.src, name, label.name, atype2type(qtype)> | q: /computed_question(str name, AId label, AType qtype, _) := f } ;
  ;
}

Type atype2type(AType atype) {
	switch(atype) {
		case integer(): return tint();
		case boolean(): return tbool();
		case string(): return tstr();
		default: throw "Unhandled type: <atype>";
	}
}


set[Message] check(AForm f, TEnv tenv, UseDef useDef)
	= check(f.questions, tenv, useDef);


set[Message] check(list[AQuestion] questions, TEnv tenv, UseDef useDef)
	= { *check(q, tenv, useDef) | q <- questions };


// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
/*set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  if (simple_question(_, AId variable, AType qtype) := q || 
  	  computed_question(_, AId variable, AType qtype, _) := q)
  	return {\type != atype2type(qtype) ? error("Redeclaration of <variable.name>", def) : 
  	warning("Duplicate label of <variable.name>", def) | str x := variable.name,  
  	<loc def, _, x, Type \type> <- tenv, def != variable.src};
  
  if (block(list[AQuestion] questions) := q ||
  	conditional(\if(condition, list[AQuestion] questions)) := q)
  	return { *check(qt, tenv, useDef) | qt <- questions } + check(condition, tenv, useDef);
  
  if (conditional(ifelse(condition, list[AQuestion] q1, list[AQuestion] q2)) := q)
  	return { *check(qt, tenv, useDef) | qt <- q1 + q2 } + check(condition, tenv, useDef);
  
  return {};
}*/


set[Message] check(simple_question(str label, AId variable, AType qtype), TEnv tenv, UseDef useDef) 
	= preventRedeclaration(variable, qtype, tenv)
	+ warnIfDuplicateLabel(variable, label, tenv);

// TODO check expression
set[Message] check(computed_question(str label, AId variable, AType qtype, AExpr expr), TEnv tenv, UseDef useDef)
	= preventRedeclaration(variable, qtype, tenv) 
	+ warnIfDuplicateLabel(variable, label, tenv)
	+ check(expr, tenv, useDef);

set[Message] check(block(list[AQuestion] questions), TEnv tenv, UseDef useDef)
	= check(questions, tenv, useDef);

set[Message] check(conditional(\if(condition, list[AQuestion] questions)))
	= check(condition, tenv, useDef)
	+ check(questions, tenv, useDef);

set[Message] check(conditional(\ifelse(condition, list[AQuestion] thenQuestions, list[AQuestion] elseQuestions)))
	= check(condition, tenv, useDef)
	+ check(thenQuestions, tenv, useDef)
	+ check(elseQuestions, tenv, useDef);

// TODO maybe extract common definition lookup?
set[Message] preventRedeclaration(AId variable, AType qtype, TEnv tenv)
	= {
	error("Redeclaration of <variable.name>", variable.src) 
	| <loc def, _, x, Type \type> <- tenv
	, def != variable.src 
	, x == variable.name
	, \type != atype2type(qtype)
	};

set[Message] warnIfDuplicateLabel(AId variable, str label, TEnv tenv)
	= { 
	warning("Duplicate label of <variable.name>", def)
	| <loc def, _, x, Type \type> <- tenv 
	,def != variable.src 
	, x == variable.name
	};

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(str x), src = loc u):		return requireQuestionDefined(x, u, tenv, useDef);
    case lit(_): 							return {};
    case not(AExpr inner):					return checkUnaryOp(inner, tbool(), tenv, useDef);
    case plus(AExpr lhs, AExpr rhs):	 	return checkBinaryOp(lhs, rhs, tint(), tenv, useDef);
    case minus(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(), tenv, useDef);
    case mult(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(), tenv, useDef);
    case div(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tint(), tenv, useDef);
    case and(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case or(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case gt(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case lt(AExpr lhs, AExpr rhs): 			return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case gte(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case lte(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case equal(AExpr lhs, AExpr rhs): 		return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    case not_equal(AExpr lhs, AExpr rhs): 	return checkBinaryOp(lhs, rhs, tbool(), tenv, useDef);
    
    default: 								assert false : "Unhandled expression <e> in semantic checking algorithm.";
  }
}

set[Message] requireQuestionDefined(str name, loc u, TEnv tenv, UseDef useDef)
	= { error("Reference to undefined question with name `<name>`", u) | useDef[u] == {} };

set[Message] checkUnaryOp(AExpr inner, Type required_type, TEnv tenv, UseDef useDef)
	= requireArgumentType(inner, required_type, tenv, useDef)
	+ check(inner, tenv, useDef);

set[Message] checkBinaryOp(AExpr lhs, AExpr rhs, Type required_type, TEnv tenv, UseDef useDef)
	= requireBinOpTypes(lhs, rhs, required_type, tenv, useDef)
	+ check(lhs, tenv, useDef)
	+ check(rhs, tenv, useDef);

set[Message] requireBinOpTypes(AExpr lhs, AExpr rhs, Type required_type, TEnv tenv, UseDef useDef) 
	= requireArgumentType(lhs, required_type, tenv, useDef)
	+ requireArgumentType(rhs, required_type, tenv, useDef);


set[Message] requireArgumentType(AExpr expr, Type required_type, TEnv tenv, UseDef useDef)
	= {error("Incompatible argument type (expected `<print_type(required_type)>` but got `<print_type(real_type)>`)", expr.src) | real_type :=  typeOf(expr, tenv, useDef), real_type != required_type};

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(str x), src = loc u):   return lookupReferenceType(x, u, tenv, useDef);
    case lit(ALit l): 					return typeOf(l);
	case not(_): 						return tbool();
	case mult(_, _): 					return tint();
	case div(_, _): 					return tint();
	case plus(_, _): 					return tint();
	case minus(_,_): 					return tint();
	case and(_,_): 						return tbool();
	case or(_,_): 						return tbool();
	case gt(_,_): 						return tbool();
	case lt(_,_): 						return tbool();
	case gte(_,_): 						return tbool();
	case lte(_,_): 						return tbool();
	case equal(_,_): 					return tbool();
	case not_equal(_,_):				return tbool();
	
	default: 							return tunknown(); 
  }
}

Type lookupReferenceType(str x, loc u, TEnv tenv, UseDef useDef) {
  if (<u, loc d> <- useDef, <d, _, x, Type t> <- tenv) {
    return t;
  } else {
  	return tunknown();
  }
}

Type typeOf(lit_integer(_)) = tint();
Type typeOf(lit_boolean(_)) = tbool();
Type typeOf(lit_string(_)) 	= tstr();

str print_type(tint()) = "integer";
str print_type(tbool()) = "boolean";
str print_type(tstr()) = "string";
str print_type(tunknown()) = "unknown";

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */

// To use on individual expressions and other snippets.
// Will not call 'resolve' or 'collect' so reference-based checks
//  cannot be tested this way.
set[Message] parseCheck(type[&T<:Tree] begin, str input) {
	ast = parse2ast(begin, input);
	return check(ast, {}, {});
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
	return check(ast, collect(ast), resolve(ast).useDef);
}
 
test bool allowsPlusIntExpr()
 	 = {} := parseCheck(#Expr, "1 + 2");

test bool rejectIntNotExpr()
 	 = {error("Incompatible argument type (expected `boolean` but got `integer`)", _)} := parseCheck(#Expr, "!42");

 
test bool rejectPlusBoolExpr()
 	 = {error("Incompatible argument type (expected `integer` but got `boolean`)", _)} := parseCheck(#Expr, "1 + true");


test bool rejectPlusBothBoolExpr()
 	 = 
 	 { error("Incompatible argument type (expected `integer` but got `boolean`)", _)
 	 , error("Incompatible argument type (expected `integer` but got `boolean`)", _)
 	 } 
 	 := parseCheck(#Expr, "false + true");

test bool rejectUndefinedQuestionReference()
	= {error(_, _)} := parseCheck(#Expr, "myvariable");

test bool allowDefinedQuestionReference()
	= {} := parseResolveCollectCheck("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = foo + 2
	}
	");

test bool rejectUndefinedQuestionReference()
	= 
	{ error("Reference to undefined question with name `baz`",_)
  	, error("Incompatible argument type (expected `integer` but got `unknown`)",_)
  	}
	:= parseResolveCollectCheck("
	form a {
		\"foo\" foo : integer
		\"bar\" bar : integer = baz + 2
	}
	");

test bool rejectQuestionReferenceOfDifferentType()
	= 
	{error("Incompatible argument type (expected `integer` but got `boolean`)", _)
	} 
	:= parseResolveCollectCheck("
	form a {
		\"foo\" mybool : boolean
		\"bar\" bar : integer = mybool + 2
	}
	");
