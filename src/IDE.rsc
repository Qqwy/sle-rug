module IDE

/*
 * Registers the QL language to Eclipse,
 * so that the checker is run on edit, 
 * and the compiler is run on file-save.
 */

import AST;
import Check;
import Compile;
import CST2AST;
import Resolve;
import Syntax;

import IO;
import Message;
import ParseTree;
import util::IDE;

private str MyQL ="MyQL";

anno rel[loc, loc] Tree@hyperlinks;

void main() {
  registerLanguage(MyQL, "myql", Tree(str src, loc l) {
    return parse(#start[Form], src, l);
  });
  
  contribs = {
    annotator(Tree(Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        return t[@messages=msgs][@hyperlinks=useDef];
      }
      return t[@messages={error("Not a form", t@\loc)}];
    }),
    
    builder(set[Message] (Tree t) {
      if (start[Form] pt := t) {
        AForm ast = cst2ast(pt);
        UseDef useDef = resolve(ast).useDef;
        set[Message] msgs = check(ast, <collect(ast), useDef>);
        set[Message] errors = {E | E <- msgs, error(_) := E || error(_, _) := E};
        if (errors == {}) {
          compile(ast);
        }
        return msgs;
      }
      return {error("Not a form", t@\loc)};
    })
  };
  
  registerContributions(MyQL, contribs);
}
