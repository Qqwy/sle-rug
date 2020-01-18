module Test::Compile

import Test::Helper;
import Compile;

import IO; // readFile


// This test succeeds as long as no exceptions occur during compilation.
test bool simpleCompileTest() {
	str form = "form a {
		\"foo\" foo : integer
		if(foo \> 20) {
			\"bar\" bar : integer = foo + 33
		}
	}
	";
	compileFromString(form, |tmp:///test.myql|);
	return true;
}

/*
 * Compile the example files in the test suite, to make sure we can indeed compile them without compile-time errors.
 */

test bool compileSimpleExample() {
	compileFromString(readFile(|project://QL/examples/simple_example.myql|), |project://QL/examples/simple_example.myql|);
	return true;
}

test bool compileTax() {
	compileFromString(readFile(|project://QL/examples/tax.myql|), |project://QL/examples/tax.myql|);
	return true;
}

test bool compileBinary() {
	compileFromString(readFile(|project://QL/examples/binary.myql|), |project://QL/examples/binary.myql|);
	return true;
}

test bool compileEmpty() {
	compileFromString(readFile(|project://QL/examples/empty.myql|), |project://QL/examples/empty.myql|);
	return true;
}