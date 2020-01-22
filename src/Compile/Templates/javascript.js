// You will notice that the whole file is wrapped in an anonymous function.
// This ensures that we do not leak any information nor variables to the outer scope.
(function(){
    var ql_questions = {};
    main();
    // TODO rather than defining on window, hide ql_questions scope by wrapping in anonymous function?
    function main() {
        initQuestions();

        window.addEventListener('load', setup);
    }

    function setup() {
        let fields = document.querySelectorAll("[data-ql-question] > input");
        for (var i = 0; i < fields.length; ++i) {
            let field = fields[i];
            field.addEventListener("input", triggerFormChange);
        }
        // Properly initialize all conditionals:
        update(ql_questions);
        // Show/hide blocks of fields:
        render(ql_questions);
    }

    function triggerFormChange(event) {
        let field = event.target;
        let val = fieldValue(field);
        let question_name = field.name;
        ql_questions[question_name] = val;
        updateFormUntilFixpointReached(ql_questions);
        render(ql_questions);
    }

    // Iterative calling of `update` until no more changes are made.
    // This is sound assuming that there are no cycles within the QL form.
    function updateFormUntilFixpointReached(ql_questions) {
        while(true) {
            let prev = deepClone(ql_questions);
            let next = update(ql_questions);
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

    function render(ql_questions) {
        console.log(ql_questions);
        for(prop in ql_questions) {
            let value = ql_questions[prop];
            alterVisibilityofConditionalBlocks(prop, value);
            alterContentsOfComputedQuestions(prop, value);
        }
    }

    function alterVisibilityofConditionalBlocks(prop, value){
        console.log("Showing/hiding", prop, value);
        let affected_fields = document.querySelectorAll("[data-ql-if='" + prop + "']");
        console.log(affected_fields);
        affected_fields.forEach(function(field) {
            console.log("Showing/hiding", field);

            if(value) {
                field.className = "visible";
            }else {
                field.className = "hidden";
            }
        });
        let affected_fields2 = document.querySelectorAll("[data-ql-else='" + prop + "']");
        console.log(affected_fields2);
        affected_fields2.forEach(function(field) {
            console.log("Showing/hiding", field);

            if(value) {
                field.className = "hidden";
            }else {
                field.className = "visible";
            }
        });

    }

    function alterContentsOfComputedQuestions(prop, value) {
        let affected_fields = document.querySelectorAll("[name='" + prop + "']");

        affected_fields.forEach(function(field) {
            switch(field.type) {
            case "checkbox": field.checked = value; break;
            default: field.value = value; break;
            }
        });
    }

    // To be filled in by the compilation code:
    // initQuestions(), which sets up the `ql_questions` variable
    "{{initialEnv}}"

    // update(ql_questions), which recalculates all computed questions and conditionals based on the current values.
    "{{update}}"
})();
