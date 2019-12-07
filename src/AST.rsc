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
  = simple_question(str name, tuple[str, AType] declaration)
  | computed_question(str name, tuple[str, AType, AExpr] definition)
  | block(list[AQuestion] questions)
  | conditional(AConditional c)
  ; 


data AConditional(loc src = |tmp:///|)
  = \if(AExpr condition, list[AQuestion] questions)
  | ifelse(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | lit(str literal)
  | not(AExpr expr)
  | mult(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | plus(AExpr lhs, AExpr rhs)
  | minus(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | gte(AExpr lhs, AExpr rhs)
  | lte(AExpr lhs, AExpr rhs)
  | equal(AExpr lhs, AExpr rhs)
  | not_equal(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = boolean()
  | string()
  | integer()
;
