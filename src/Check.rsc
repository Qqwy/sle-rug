module Check

import AST;
import Resolve;
import Message; // see standard library
import IO; //todo: remove


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


set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return { *check(q, tenv, useDef) | q <- f.questions };
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
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
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(str x, src = loc u):
      msgs += { error("Undeclared question", u) | useDef[u] == {} };
    case not(AExpr inner):
      msgs += { error("Non-boolean argument to `!`") | typeOf(inner, tenv, useDef) != tbool()};
    case plus(AExpr lhs, AExpr rhs):
    {
      	msgs += {error("Incompatible left-hand side argument to `+`") | typeOf(lhs, tenv, useDef) != tint()};
      	msgs += {error("Incompatible right-hand side argument to `+`") | typeOf(rhs, tenv, useDef) != tint()};
	}
    case minus(AExpr lhs, AExpr rhs):
    {
      	msgs += {error("Incompatible left-hand side argument to `-`") | typeOf(lhs, tenv, useDef) != tint()};
      	msgs += {error("Incompatible right-hand side argument to `-`") | typeOf(rhs, tenv, useDef) != tint()};
	}
    // etc.
  }
  
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(str x, src = loc u):  
      if (<u, loc d> <- useDef, <d, x, _, Type t> <- tenv) {
        return t;
      }
      // TODO disambugate between strings, booleans, ints
      // by adding different types for the different kinds of literals.
    case lit(str l): 	 	return tunknown();
	case not(_): 			return tbool();
	case mult(_, _): 		return tint();
	case div(_, _): 		return tint();
	case plus(_, _): 		return tint();
	case minus(_,_): 		return tint();
	case and(_,_): 			return tbool();
	case or(_,_): 			return tbool();
	case gt(_,_): 			return tbool();
	case lt(_,_): 			return tbool();
	case gte(_,_): 			return tbool();
	case lte(_,_): 			return tbool();
	case equal(_,_): 		return tbool();
	case not_equal(_,_):	return tbool();
	default: 				return tunknown(); 
  }
}

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
 
 

