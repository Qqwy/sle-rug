module Transform

import Syntax;
import Resolve;
import AST;
import ParseTree;
import CST2AST;
import IO;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  return form(f.name + "_Flattened", flattenQuestions(f.questions, lit(lit_boolean(true))));
}

list[AQuestion] flattenQuestions(list[AQuestion] questions, AExpr conj) {
	return [*flattenQuestion(q, conj) | q <- questions];
}

list[AQuestion] flattenQuestion(conditional(AConditional c), AExpr conj) {
	return flattenConditional(c, conj);
}

list[AQuestion] flattenQuestion(block(list[AQuestion] questions), AExpr conj) {
	return [block(flattenQuestions(questions, conj))];
}

list[AQuestion] flattenQuestion(AQuestion question, AExpr conj) {
	return [conditional(\if(conj, [question]))];
}

list[AQuestion] flattenConditional(\if(AExpr condition, list[AQuestion] questions), AExpr conj) {
	return flattenQuestions(questions, and(conj, condition));
}

list[AQuestion] flattenConditional(ifelse(AExpr condition, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions), AExpr conj) {
	return flattenQuestions(ifQuestions, and(conj, condition)) + 
		   flattenQuestions(elseQuestions, and(conj, not(condition)));
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName, RefGraph refGraph) {
   return visit(f) {
    case (Declaration)`<Id name> : <Type qtype>` => (Declaration)`<Id newName> : <Type qtype>`
    when 
    <nameId, useOrDef> <- refGraph.defs,
    name == nameId

   	case (Expr)`<Id name>` => (Expr)`<Id newName>` 
   	when

       <nameId, loc def> <- refGraph.defs,
       <useOrDef, def> <- refs.useDef,
   	   name == nameId
   }; 
 } 

start[Form] testRenaming(str input, loc useOrDef, str newName) {
	cst = parse(#start[Form], input);
	ast = cst2ast(cst);
	refGraph = resolve(ast);
	println(refGraph);
	
	return rename(cst, useOrDef, newName, refGraph);
}

test bool renamingWorks() {
	str input = "form foo { \"x\" x : integer = 33}";
	res = testRenaming(input, |unknown:///|(15,1,<1,15>,<1,16>), "y");
	println(res);
	return true;
}