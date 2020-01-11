main();
// TODO rather than defining on window, hide ql_questions scope by wrapping in anonymous function?
function main() {
    window.ql_questions = {foo: 0, bar: false, foo_c: 0};

    window.addEventListener('load', setup);
}

function setup() {
    console.log('All assets are loaded');
    let fields = document.querySelectorAll("[data-ql-question] > input");
    for (var i = 0; i < fields.length; ++i) {
        let field = fields[i];
        console.log(field);
        field.addEventListener("change", triggerFormChange);
    }
    render(window.ql_questions);
}

function triggerFormChange(event) {
    let field = event.target;
    let val = fieldValue(field);
    let question_name = field.name;
    window.ql_questions[question_name] = val;
    updateFormUntilFixpointReached(window.ql_questions);
    render(window.ql_questions);
}

// Iterative calling of `update` until no more changes are made.
// This is sound assuming that there are no cycles within the QL form.
function updateFormUntilFixpointReached(ql_questions) {
    console.log(ql_questions);
    while(true) {
        let prev = deepClone(ql_questions);
        let next = update(ql_questions);
        console.log(next);
        if (dictsAreEquivalent(next, prev)) { return; }
    }
}

function fieldValue(field) {
    switch(field.type) {
    case "checkbox": return field.checked;
    case "number": return +field.value;
    case "text": return field.value;
    default: throw("Unhandled type:"+field.type);
    };
}

// The easiest way to deep-clone an object in JavaScript.
// Not the most performant, but the one with the most browser support.
function deepClone(object) {
    return JSON.parse(JSON.stringify(object));
}

// Checks equivalent between two 'typeless' JS objects.
// Does not handle deeply nested structures.
function dictsAreEquivalent(a, b) {
    // Create arrays of property names
    var aProps = Object.getOwnPropertyNames(a);
    var bProps = Object.getOwnPropertyNames(b);

    // If number of properties is different,
    // objects are not equivalent
    if (aProps.length != bProps.length) {
        return false;
    }

    for (var i = 0; i < aProps.length; i++) {
        var propName = aProps[i];

        // If values of same property are not equal,
        // objects are not equivalent
        if (a[propName] !== b[propName]) {
            return false;
        }
    }

    // If we made it this far, objects
    // are considered equivalent
    return true;
}


// Updates all computed questions (and if-statements).
function update(ql_questions) {
    // To be filled by the compiler
    // if(ql_questions["bar"]) {

    // }

    ql_questions["foo_c"] = ql_questions["foo"];
    ql_questions["bar_c"] = !ql_questions["bar"];

    return ql_questions;
}

function render(ql_questions) {
    for(prop in ql_questions) {
        console.log(prop);
        let value = ql_questions[prop];
        alterVisibilityofConditionalBlocks(prop, value);
        alterContentsOfComputedQuestions(prop, value);
    }
}

function alterVisibilityofConditionalBlocks(prop, value){
    let affected_fields = document.querySelectorAll("[data-ql-question-visible-when=" + prop + "]");
    affected_fields.forEach(function(field) {
        console.log(field);

        if(value) {
            field.className = "visible";
        }else {
            field.className = "hidden";
        }
    });
}

function alterContentsOfComputedQuestions(prop, value) {
    let affected_fields = document.querySelectorAll("[name=" + prop + "]");

    affected_fields.forEach(function(field) {
        field.value = value;
    });
}
