module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = simple_question(str name, tuple[str, str] declaration)
  | computed_question(str name, tuple[str, str, str] definition)
  ; 
  

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | lit(str literal)
  | gt(AExpr lhs, AExpr rhs)
  | plus(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | string()
  | integer()
;
