module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

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
  > non-assoc (
    Expr "\>" Expr
  | Expr "\<" Expr
  | Expr "\<=" Expr
  | Expr "\>=" Expr
  | Expr "==" Expr
  | Expr "!=" Expr
  )
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

syntax OurId
  = id: Id;

test bool acceptsSimplePlus(int lhs, int rhs) 
	= (Expr)`<Expr lhs> + <Expr rhs>` := parse(#Expr, "<lhs> + <rhs>");

test bool acceptsSimpleMul(int lhs, int rhs, int mul) 
	= (Expr)`<Expr lhs> + <Expr rhs> * <Expr mul>` := parse(#Expr, "<lhs> + <rhs> * <mul>");

test bool acceptsSimpleQuestion(str name) 
	= (Question) q := parse(#Question, "\"foo\" var : integer");


// Will succeed iff `test_function` raises a ParseError.
bool tryParseFail(void () test_function) {
	try {
		test_function();
	}
	catch ParseError(_): return true;
	return false;
}


test bool rejectUnexistentType()
	= tryParseFail((){
		parse(#Question, "\"foo\" var : unexistenttype");		
	});
	
test bool rejectNonAssocOperators()
	= tryParseFail((){
		parse(#Expr, "1 \< 3 \<= 4");
	});
	
test bool rejectEmptyFileWithoutForm()
	= tryParseFail((){parse(#start[Form], "");});
