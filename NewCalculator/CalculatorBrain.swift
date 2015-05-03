//
//  CalculatorBrain.swift
//  NewCalculator
//
//  Created by Jack Huang on 15/2/7.
//  Copyright (c) 2015年 Jack's app for practice. All rights reserved.
//

import Foundation

typealias PropertyList = AnyObject

class CalculatorBrain {
    
    var program: PropertyList {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let symbolStack = newValue as? [String] {
                var newOpStack = [Op]()
                for symbol in symbolStack {
                    if let op = knownOps[symbol] {
                        newOpStack.append(op)
                    } else if let value = NSNumberFormatter().numberFromString(symbol)?.doubleValue {
                        newOpStack.append(.Operand(value, 0))
                    } else if let constantOp = knownCons[symbol] {
                        newOpStack.append(constantOp)
                    } else {
                        newOpStack.append(.Variable(symbol, 0, nil))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    // Precedence
    //  .All Op include 'Precedence: Int', which represent the precedence of each op, higher value means higher precedence.
    //  .Operand, unary operation, variable and constant have same precedence, e.g. '5' has precedence 0, which should never be added with parenthese.
    //  .Different binary operation has different precedence, e.g. '+' has precedence 1, '×' has precedence 2
    // Errror Msg
    //  .Check if Pass the error msg closure,
    private enum Op : Printable {
        
        case Operand(Double, Int) // value, precedence
        case UnaryOperation(String, Int, (Double -> String?)?, Double -> Double) // symbol, precedence, error reporter, unary function
        case BinaryOperation(String, Int, ((Double, Double) -> String?)?, (Double, Double) -> Double) // symbol, precedence, error reporter, binary function
        case Variable(String, Int, String?) // symbol, precedence, error reporter
        case Constant(String, Double, Int) // symbol, value, precedence
        
        var description: String {
            switch self {
            case .Operand(let operand, _): return "\(operand)"
            case .UnaryOperation(let symbol, _, _, _): return symbol
            case .BinaryOperation(let symbol, _, _, _): return symbol
            case .Variable(let symbol, _, _): return symbol
            case .Constant(let symbol, _, _): return symbol
            }
        }
    }
    
    private var opStack = [Op]()
    private var knownOps = [String:Op]()
    private var knownCons = [String:Op]()
    var variableValues = [String:Double]()
    
    // Public: description of the stack (read-only)
    var description: String {
        return (describeOpStack() as NSArray).componentsJoinedByString(", ")
    }
    
    // Public: Initializer
    init() {
        func learnOperation(operation: Op) {
            knownOps[operation.description] = operation
        }
        learnOperation(Op.BinaryOperation("×", 2, nil, *))
        learnOperation(Op.BinaryOperation("÷", 2, ({ op1, op2 in return op1 == 0 ? "❌ dividend" : nil })) { $1 / $0 })
        learnOperation(Op.BinaryOperation("+", 1, nil, +))
        learnOperation(Op.BinaryOperation("−", 1, nil) { $1 - $0 })
        learnOperation(Op.UnaryOperation("√", 0, ({ return $0 < 0 ? "❌ √(n>0)" : nil }), sqrt))
        learnOperation(Op.UnaryOperation("sin", 0, nil, sin))
        learnOperation(Op.UnaryOperation("cos", 0, nil, cos))
        learnOperation(Op.UnaryOperation("-", -1, nil) { 0 - $0 })
        
        knownCons["π"] = Op.Constant("π", M_PI, 0)
    }
    
    // Public: push operand into stack and return result
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand, 0))
        return evaluate()
    }
    
    // Public: push variable operand (e.g. 'm', not it's value) into stack
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol, 0, nil))
        return evaluate()
    }
    
    // Public: push constant (e.g. 'π') into stack
    func pushConstant(symbol: String, value: Double) -> Double? {
        opStack.append(Op.Constant(symbol, value, 0))
        return evaluate()
    }
    
    // Public: iterate through all known operations, if the symbol is known operation, then push it into stack and calculate
    func performOperation(symbol: String) -> Double? {
        if let op = knownOps[symbol] {
            opStack.append(op)
        } else {
            println("operation not exist")
        }
        return evaluate()
    }
    
//    // Public: add new unary operation to calculator, e.g. '√'
//    func learnNewUnaryOperation(symbol: String, operation: Double -> Double) {
//        knownOps[symbol] = Op.UnaryOperation(symbol, 0, nil, operation)
//    }
//    
//    // Public: add new binary operation to calculator, e.g. '+'
//    func learnNewBinaryOperation(symbol: String, precedence: Int, operation: (Double, Double) -> Double) {
//        knownOps[symbol] = Op.BinaryOperation(symbol, precedence, nil, operation)
//    }
    
    // Public: clean stack
    func clean() {
        opStack.removeAll(keepCapacity: false)
        variableValues.removeAll(keepCapacity: false)
    }
    
    // Public: undo the steps by removing top op from stack
    func undo() -> Double? {
        if !opStack.isEmpty {
            opStack.removeLast()
        }
        return evaluate()
    }
    
    func evaluate() -> Double? {
        let (result, remainingStack) = evaluate(opStack)
        //println("Result from \(opStack) is \(result) with remained \(remainingStack)")
        return result
    }
    
    // function evaluate() is getting the top op of the stack.
    // If the top op is an operand, then return the operand as result.
    // If the top op is an operation, then recursively try to get enough operands from stack to perform operation and return the result.
    // e.g. stack(array) = [5, 6, +, 4, ×] and the evaluation steps are:
    // 1. pop '×', '×' is an binary operation. It needs 2 operands, so keep evaluate()
    // 2. pop '4', '4' is the first operand for '×', and keep digging next operand
    // 3. pop '+', '+' is an binary operation. It needs another 2 operands, so keep evaluate()
    // 4. pop '6', '6' is the first operand for '+'
    // 5. pop '5', '5' is the second operand for '+', so return '6 + 5 = 11'
    // 6. '11' is the second operand for '×', so return '4 * 11 = 44'
    // So the final result is 44
    
    // Notice:
    // 1. Every time you should pass the latest remainingOps (after each evaluation) as parameter to recursively call.
    // 2. The ops parameter is just a copy of opStack, so the recursion is not affect the original opStack.
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand, _):
                return (operand, remainingOps)
            case .UnaryOperation(_, _, _, let unaryOperation):
                let evaluation = evaluate(remainingOps)
                if let operand = evaluation.result {
                    return (unaryOperation(operand), evaluation.remainingOps)
                }
            case .BinaryOperation(_, _, _, let binaryOperation):
                let evaluation1 = evaluate(remainingOps)
                if let operand1 = evaluation1.result {
                    let evaluation2 = evaluate(evaluation1.remainingOps)
                    if let operand2 = evaluation2.result {
                        return (binaryOperation(operand1, operand2), evaluation2.remainingOps)
                    }
                }
            case .Variable(let symbol, _, _):
                if let value = variableValues[symbol] {
                    return (value, remainingOps)
                }
            case .Constant(_, let value, _):
                return (value, remainingOps)
            }
        }
        return (nil, ops)
    }
    
    // Assignment for stack description (including multiple complete expression, e.g. √(3+5), cos(π) ).
    // .Get the remainingOps after each recursion. If the remainingOps is not empty, then pass the remainingOps as parameter to perform next recursion.
    // .Loop the step until the returned remainingOps is empty.
    // .Also collect each result as a single complete expression, finally it returns an array of separated complete descriptions.
    // .As required, the implementation of multiple complete expressions should be outside of the recursion function itself (Not mixed together).
    private func describeOpStack() -> [String] {
        var expressions = [String]()
        var (result, _,  remainingOps) = describeOpStack(opStack)
        if result != nil {
            expressions.append(result!)
        }
        while !remainingOps.isEmpty {
            (result, _,  remainingOps) = describeOpStack(remainingOps)
            if result != nil {
                expressions.insert(result!, atIndex: 0)
            }
        }
        //println(expressions)
        return expressions
    }
    
    // Assignment for stack description. Using precedence to determine whether should add parenthese.
    // Every time we encounter the binary operation (e.g. leftOp × rightOp), then we need to decide if we should add parenthese to leftOp or rightOp.
    // If leftOp is an operand (e.g. '3' precedence = 0), rightOp is an addition operation (e.g. '4+5' precedence = 1), and current binary op is multiply ('×', precedence = 2), then we should add parenthese to '4+5' and never add parenthese to '3'.
    // e.g. [3, 4, 5, +, ×] , output is 3×(4+5)
    
    // Personal opinions for adding parenthese:
    // 1. Adding parenthese to binary operation description which after binarySymbol, because it gets performed first. 
    //    This is for adding parenthese on same precedence level of operations
    //    e.g. The binary operation description as subtractor after binarySymbol is required to put parenthese on.
    //    e.g. [1, 2, 3, +, -] result is -4, and output should be '1-(2+3)', NOT '1-2+3'.
    //    I think is OK for something like [1, 2, 3, +, +] output '1+(2+3)', which give you the feedback of performing '2+3' first before '1'.
    //    And it's perfect for [1, 2, +, 3, +, 4, ×] output '(1+2+3)×4', which does not include any extra parenthsis on each addition operation.
    // 2. Adding parenthese for binary operation description which has lower precedence (Suggested by assignment paper)
    //    This is the reason for putting 'precedence' in each Op (enum)
    private func describeOpStack(ops: [Op]) -> (result: String?, currentPrecedence: Int, remainingOps: [Op]) {

        if !ops.isEmpty {
            var remainingOps = ops
            let topOp = remainingOps.removeLast()
            
            switch topOp {
            case .Operand(let operand, let precedence):
                var operandDesc = "\(operand)"
                if operandDesc.hasSuffix(".0") {
                    operandDesc = (operandDesc as NSString).substringToIndex((operandDesc as NSString).length-2)
                }
                return (operandDesc, precedence, remainingOps)
            
            case .UnaryOperation(let unarySymbol, let unaryOpPrecedence, _, _):
                let recursivedDescription = describeOpStack(remainingOps)
                var resultString = recursivedDescription.result ?? "?"
                let resultPrecedence = recursivedDescription.currentPrecedence
                
                // e.g. -5, and '+/-' is a unary operand, it needs to be parenthesed
                // It better needs a filter for preventing (---5) when user keep pushing signs into stack.
                // And you can argue that we can leave this fine because it shows exactly the history of operations
                if unaryOpPrecedence >= 0 {
                    resultString = "\(unarySymbol)(\(resultString))"
                } else {
                    resultString = unarySymbol + resultString // e.g. -5, not -(5)
                }
                return (resultString, unaryOpPrecedence, recursivedDescription.remainingOps)
            
            case .BinaryOperation(let binarySymbol, let binaryOpPrecedence, _, _):
                let recursivedDesc1 = describeOpStack(remainingOps)
                var resultString1 = recursivedDesc1.result ?? "?"
                let resultPrecedence1 = recursivedDesc1.currentPrecedence
                
                let recursivedDesc2 = describeOpStack(recursivedDesc1.remainingOps)
                var resultString2 = recursivedDesc2.result ?? "?"
                let resultPrecedence2 = recursivedDesc2.currentPrecedence

                if resultPrecedence1 != 0 {
                    resultString1 = addParentheseToExpression(resultString1) // Personal opinion 1
                }
                if binaryOpPrecedence > resultPrecedence2 && resultPrecedence2 != 0 {
                    resultString2 = addParentheseToExpression(resultString2) // Personal opinion 2
                }
                return (resultString2 + binarySymbol + resultString1, binaryOpPrecedence, recursivedDesc2.remainingOps)
                
            case .Variable(let symbol, let precedence, _): return (symbol, precedence, remainingOps)
            case .Constant(let symbol, _, let precedence): return (symbol, precedence, remainingOps)
            }
        }
        return (nil, 0, ops)
    }
    
    func addParentheseToExpression(exp: String) -> String {
        var modifiedExp = exp
        if !(exp.hasPrefix("(") && exp.hasSuffix(")")) {
            modifiedExp = "(" + exp + ")"
        }
        return modifiedExp
    }
    
    // Description of program
    class func descriptionOfProgram(program: PropertyList) -> String {
        let brain = CalculatorBrain()
        brain.program = program
        //println("log description: \(brain.program)")
        return brain.description
    }
    
    // Assignment for Error Reporting
    // I think it only reports the lateset error message for multiple errors.
    func evaluateAndReportErrors() -> String {
        let (result, errorMsg, remainingStack) = evaluateAndReportErrors(opStack)
        //println("Result from \(opStack) is \(result) with remained \(remainingStack) and error: \(errorMsg)")
        return errorMsg ?? (result != nil ? "\(result!)" : "?")
    }
    
    private func evaluateAndReportErrors(ops: [Op]) -> (result: Double?, errorMessage: String?, remainingOps: [Op]) {
        
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand, _):
                return (operand, nil, remainingOps)
            case .UnaryOperation(_, _, let errorTest, let unaryOperation):
                let evaluation = evaluate(remainingOps)
                if let operand = evaluation.result {
                    // error report e.g. √(-5)
                    let failureDescription = errorTest?(operand)
                    return (unaryOperation(operand), failureDescription, evaluation.remainingOps)
                }
            case .BinaryOperation(_, _, var errorTest, let binaryOperation):
                let evaluation1 = evaluate(remainingOps)
                if let operand1 = evaluation1.result {
                    let evaluation2 = evaluate(evaluation1.remainingOps)
                    if let operand2 = evaluation2.result {
                        // error report e.g. 2 / 0
                        let failureDescription = errorTest?(operand1, operand2)
                        return (binaryOperation(operand1, operand2), failureDescription, evaluation2.remainingOps)
                    } else { return (nil, "op2❓", evaluation2.remainingOps) } // error report
                } else { return (nil, "op1❓", evaluation1.remainingOps) } // error report
            case .Variable(let symbol, _, var failureDescription):
                if let value = variableValues[symbol] {
                    return (value, nil, remainingOps)
                } else {
                    return (nil, "(\(symbol)=❓)", remainingOps) // error report
                }
            case .Constant(_, let value, _):
                return (value, nil, remainingOps)
            }
        }
        return (nil, nil, ops)
    }
    
    
}





























