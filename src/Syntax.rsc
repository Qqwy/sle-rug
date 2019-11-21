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
 = Str Expr*;

syntax ComputedQuestion
 = Str;
 
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

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Literal
  | "!" Expr
  | left Expr "+" Expr
  | left Expr "*" Expr
  | left Expr "-" Expr
  | left Expr "/" Expr
  | left Expr "&&" Expr
  | left Expr "||" Expr
  ;

// What should this one be?
syntax Type
  = ;  
  
syntax Literal
 = Str
 | Int
 | Bool;

lexical Str = "\"" ("\\\""|![\"])*  "\"";

lexical Int 
  = "-"?[0-9]+;

lexical Bool = "true" | "false";



