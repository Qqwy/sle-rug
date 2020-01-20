module Test::Transform

import Transform;
import IO;
import Syntax;
import CST2AST;
import Resolve;
import ParseTree;
import Set;

import Test::Helper;

start[Form] testRenaming(str input, loc useOrDef, str newName) {
	cst = parse(#start[Form], input);
	ast = cst2ast(cst);
	refGraph = resolve(ast);
	println(refGraph);
	set[loc] defs = refGraph.defs["bought"];
	<myloc, _> = takeFirstFrom(defs);
	println(myloc);
	
	return rename(cst, myloc, newName, refGraph);
}

test bool simpleExampleRenaming() {
	res = testRenaming(readFile(|project://QL/examples/simple_example.myql|), |unknown:///|(280,6,<8,36>,<8,42>), "superman");
	println(res);
	return res == parse(#start[Form], readFile(|project://QL/examples/simple_example_renamed.myql|));
}
