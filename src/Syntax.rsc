module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = SimpleQuestion
  | ComputedQuestion
  | Block
  | Conditional; 
  
syntax SimpleQuestion
 = Str Declaration;

syntax ComputedQuestion
 = Str Definition;
 
syntax Block
 = "{" Question* "}";
 
syntax Conditional
 = IfThenElse
 | IfThen;
 
syntax IfThenElse
 = "if" Condition Block "else" Block;


syntax IfThen
 = "if" Condition Block;

syntax Condition
 = "(" Expr ")";
 
 
syntax Definition
 = Declaration "=" Expr;

syntax Declaration
 = Id ":" Type;

// TODO Marten: Refactor (Split up) this one?
// TODO Marten: Maybe we _want_ various equality operators to have same precedence
// and have ambiguity become a parse error (since they should not be used as `a < b < c`)?

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  > Literal
  > "(" Expr ")" 
  > "!" Expr
  > left Expr "\>" Expr
  | left Expr "\<" Expr
  | left Expr "\<=" Expr
  | left Expr "\>=" Expr
  | left Expr "==" Expr
  | left Expr "!=" Expr
  > left Expr "*" Expr
  | left Expr "/" Expr
  > left Expr "+" Expr
  | left Expr "-" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;

syntax Type
  = "boolean"
  | "integer"
  | "string"
  ;  
  
syntax Literal
 = Str
 | Int
 | Bool
 ;

lexical Str = "\"" ("\\\""|![\"])*  "\"";

lexical Int 
  = "-"?[0-9]+;

lexical Bool = "true" | "false";



