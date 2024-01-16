module Transform

import Syntax;
import Resolve;
import AST;

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
    return visit(f) {
        case form(name, questions): {
            return form(name, flattenQuestions(questions, trueExpr()));
        }
    };
}

list[AQuestion] flattenQuestions(list[AQuestion] questions, AExpr parentCondition) {
    list[AQuestion] flattenedQuestions = [];
    for (AQuestion q <- questions) {
        switch(q) {
            case question(AExpr cond, list[AQuestion] nestedQuestions): {
                AExpr combinedCondition = combineConditions(parentCondition, cond);
                flattenedQuestions += flattenQuestions(nestedQuestions, combinedCondition);
            }
            case question(AExpr cond, list[AQuestion] ifQuestions, list[AQuestion] elseQuestions): {
                flattenedQuestions += flattenQuestions(ifQuestions, combineConditions(parentCondition, cond));
                flattenedQuestions += flattenQuestions(elseQuestions, parentCondition);
            }
            default: {
                list[AQuestion] questionAux = [q];
                flattenedQuestions += question(parentCondition, questionAux);
            }
        }
    }
    return flattenedQuestions;
}

AExpr combineConditions(AExpr cond1, AExpr cond2) {
    if (isTrueExpr(cond1)) {
        return cond2;
    } else if (isTrueExpr(cond2)) {
        return cond1;
    } else {
        return ref(cond1, "&&", cond2);
    }
}

AExpr trueExpr() {
    return ref(true);
}


bool isTrueExpr(AExpr expr) {
    bool result = false;
    visit(expr) {
        case ref(bool b): result = b;
        default: result = false;
    };

    return result;
}


/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   return f; 
} 
 
 
 

