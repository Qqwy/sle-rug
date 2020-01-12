module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List;

import Syntax; // For tests only.
import ParseTree; // For tests only.
import CST2AST; // For tests only.
import Check; // For tests only.

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
try {
  writeFile(f.src[extension="js"].top, form2js(f));
  //html = toString(htmlCompile(f));
  writeFile(f.src[extension="css"].top, form2css(f));
  writeFile(f.src[extension="html"].top, "\<!DOCTYPE html\>" + lang::html5::DOM::toString(htmlCompile(f, f.src)));
  
  } catch err: {
  	println(err);
  };
}

HTML5Node htmlCompile(AForm f, loc filename) {
	str cssloc = filename[extension="css"].file;
	str jsloc = filename[extension="js"].file;
	HTML5Node res = 
	html(
		head(
			link(\rel("stylesheet"), href(cssloc))
		), 
		body(
			form(
				name(f.name), 
				action("#"), 
				htmlCompile(f.questions)
			),
			script(src(jsloc))
		)
	);
	//println(res);
	return res;
}


HTML5Node htmlCompile(list[AQuestion] questions)
  = div([htmlCompile(question)  | question <- questions]);

// TODO: Disambugate between different types of questions here.
HTML5Node htmlCompile(AQuestion question)
  = div(
  	html5attr("data-ql-question", "todoquestionname"),
  	label(\for("todoquestionname"), "todoquestiontext"),
	input(\type("text"))
  	);


str form2js(AForm f) {
  return "var test = 42; 
  		 'var window.ql_questions = <form2jsInitialValues(f)>;";
}

str form2jsInitialValues(AForm f) {
	question_values = form2jsInitialQuestions(f);
	conditional_values = form2jsInitialConditionals(f);
	str combined = intercalate(",\n", question_values + conditional_values);
	return"{\n<combined>\n}";
}

list[str] form2jsInitialQuestions(AForm f) {
	map[AId name, AType \type] env = 
	  (label: qtype | /simple_question(_, AId label, AType qtype)      := f)
	+ (label: qtype | /computed_question(_, AId label, AType qtype, _) := f)
	;
	println(env);
	inits = ["\"question_<val.name>\" : <jsDefaultValue(env[val])>" | val <- env];
	return inits;
}

// Transforms all conditionals into string keys representing that conditional.
// Not beautiful (it would be nicer if we'd use a pretty printer), but it works.
list[str] form2jsInitialConditionals(AForm f) {
	map[AExpr condition, AType \type] env = 
	  (condition: boolean() | /\if(AExpr condition, _)      := f)
	+ (condition: boolean() | /ifelse(AExpr condition, _, _) := f)
	;

	inits = ["\"condition(<val>)\" : <jsDefaultValue(env[val])>" | val <- env];
	return inits;
}

//str jsQuestionBeginState(list[AQuestion] questions)
//	= "{\n<intercalate(", \n", [ jsQuestionBeginState(question) | question <- questions])>\n}";


  //= simple_question(str name, AId variable, AType qtype)
  //| computed_question(str name, AId variable, AType qtype, AExpr definition)
  //| block(list[AQuestion] questions)
  //| conditional(AConditional c)
str jsQuestionBeginState(simple_question(name, variable, qtype))
	= "sq_<variable.name>: <jsDefaultValue(qtype)>";

str jsQuestionBeginState(computed_question(name, variable, qtype, _))
	= "cq_<variable.name>: <jsDefaultValue(qtype)>";

str jsQuestionBeginState(computed_question(name, variable, qtype, _))
	= "cq_<variable.name>: <jsDefaultValue(qtype)>";

str jsQuestionBeginState(AQuestion question)
	= "todo: \"todo\"";


str jsDefaultValue(boolean()) = "false";
str jsDefaultValue(integer()) = "0";
str jsDefaultValue(string()) = "\"\"";



str form2css(AForm f) {
return "
	input {
	    margin: 1em;
	}
	
	label {
	    margin-top: 1.5em;
	}
	
	
	.hidden {
	    display: none;
	}";
}

str jsPreamble() {
	return "";
}

// Compiles a QL form from an input string,
// and writes the output to temporary files.
void compileFromString(str inputForm) {
	t = parse(#start[Form], inputForm);
	if (start[Form] pt := t) {
		
        AForm ast = cst2ast(pt);
        ast.src = |tmp:///test.myql|;
        //println(ast.src);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        if (msgs == {}) {
          return compile(ast);
        }
        throw msgs;
      }
  throw {error("Not a form", t@\loc)};
}

// This test succeeds as long as no exceptions occur during compilation.
test bool simpleCompileTest() {
	str form = "form a {
		\"foo\" foo : integer
		if(foo \> 20) {
			\"bar\" bar : integer = foo + 33
		}
	}
	";
	compileFromString(form);
	return true;
}