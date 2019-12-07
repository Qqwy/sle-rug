module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = form: "form" Id "{" Question* "}"; 

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
  = ref: Id \ "true" \ "false" // true/false are reserved keywords.
  > lit: Literal
  > "(" Expr ")" 
  > "!" Expr
  > left (
    Expr "*" Expr
  | Expr "/" Expr
  )
  > left ( 
    Expr "+" Expr
  | Expr "-" Expr
  )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > non-assoc (
    Expr "\>" Expr
  | Expr "\<" Expr
  | Expr "\<=" Expr
  | Expr "\>=" Expr
  | Expr "==" Expr
  | Expr "!=" Expr
  )
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

syntax OurId
  = id: Id;



// -- Syntax Unit tests: 
test bool acceptsSimpleValidSyntax() {
	parse(#Expr, "1 + 2");
	parse(#Expr, "1 + 2 * 3");
	parse(#Question, "\"foo\" var : integer");
	return true;
}

test bool rejectsSimpleInvalidSyntax() {
	try {
		parse(#Question, "\"foo\" var : unexistenttype");
		parse(#Expr, "1 \< 3 \<= 4"); // non-assoc operators
		
	}
	catch ParseError(_): return true;
	return false;
}

