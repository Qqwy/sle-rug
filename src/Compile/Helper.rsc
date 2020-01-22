module Compile::Helper
/* 
 * This module contains functions that are used by multiple compiler modules.
 */
 
import AST;

// We prepend all normal questions by `question_` and all conditionals by `condition_`
// to make sure we'll never have name clashes.
str questionFieldName(AId label)
	= "\"<unescapedQuestionFieldName(label)>\"";
	
str unescapedQuestionFieldName(AId label)
	= "question_<label.name>";
	
// We prepend all normal questions by `question_` and all conditionals by `condition_`
// to make sure we'll never have name clashes.
str conditionFieldName(AExpr condition)
	= "\'<unescapedConditionFieldName(condition)>\'";

str unescapedConditionFieldName(AExpr condition)
	= "condition_<condition.src.offset>";