module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library
import List;

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
	println("beforebefore");
	println(f.questions);
	println("before");
	println(lang::html5::DOM::toString(htmlCompile(f.questions)));
	println("after");
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
	println(res);
	println("afterafter");
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
  		 'var window.ql_questions = <jsQuestionBeginState(f.questions)>;";
}

str jsQuestionBeginState(list[AQuestion] questions)
	= "{\n<intercalate(", \n", [ jsQuestionBeginState(question) | question <- questions])>\n}";

str jsQuestionBeginState(AQuestion question)
	= "a: 1";

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