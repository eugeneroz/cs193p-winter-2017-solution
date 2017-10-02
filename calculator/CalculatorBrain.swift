//
//  CalculatorBrain.swift
//  calculator
//
//  Created by Eugene Rozenberg on 28/08/2017.
//  Copyright © 2017 Eugene Rozenberg. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    var variables = [String:Double]()
    private var internalProgram = [Element]()
    
    private enum Operation {
        case constant(Double)
        case unaryOperation((Double) -> Double, (String) -> String)
        case binaryOperation((Double, Double) -> Double, (String, String) -> String)
        case equals
        case reset
        case undo
    }
    
    private enum Element {
        case operation(String)
        case operand(Double)
        case variable(String)
    }
    
    struct PendingBinaryOperation {
        let firstOperand: (Double, String)
        let operation: (Double, Double) -> Double
        let description: (String, String) -> String
        
        func perform(with secondOperand: (Double, String)) -> (Double, String) {
            return (operation(firstOperand.0, secondOperand.0), description(firstOperand.1, secondOperand.1))
        }
    }
    
    private var operations: Dictionary<String, Operation> = [
        "C" : Operation.reset,
        "π" : Operation.constant(Double.pi),
        "√" : Operation.unaryOperation(sqrt, { "√(" + $0 + ")" }),
        "±" : Operation.unaryOperation({ -$0 }, { "-(" + $0 + ")" }),
        "cos" : Operation.unaryOperation(cos, { "cos(" + $0 + ")" }),
        "sin" : Operation.unaryOperation(sin, { "sin(" + $0 + ")" }),
        "tan" : Operation.unaryOperation(tan,{ "tan(" + $0 + ")" }),
        "x²": Operation.unaryOperation({ pow($0, 2) }, { "(" + $0 + ")²" }),
        "+" : Operation.binaryOperation({ $0 + $1 }, { $0 + "+" + $1 }),
        "-" : Operation.binaryOperation({ $0 - $1 }, { $0 + "-" + $1 }),
        "÷" : Operation.binaryOperation({ $0 / $1 }, { $0 + "÷" + $1 }),
        "*" : Operation.binaryOperation({ $0 * $1 }, { $0 + "*" + $1 }),
        "=" : Operation.equals,
        "←" : Operation.undo
    ]
    
    @available(iOS, deprecated: 1, message: "Not needed anymore")
    var result: Double? {
        get {
            return nil
        }
    }
    
    @available(iOS, deprecated: 1, message: "Not needed anymore")
    var description: String? {
        get {
            return nil
        }
    }
    
    mutating func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .reset:
                internalProgram.removeAll()
                variables.removeAll()
                break
            case .undo:
                if (internalProgram.count > 0) {
                    internalProgram.removeLast()
                }
                break
            default:
                internalProgram.append(Element.operation(symbol))
                break
            }
        } else {
            setOperand(variable: symbol)
        }
    }
    
    mutating func setOperand(_ operand: Double) {
        internalProgram.append(Element.operand(operand))
    }
    
    mutating func setOperand(variable named: String) {
        internalProgram.append(Element.variable(named))
    }
    
    func evaluate(using variables: Dictionary<String,Double>? = nil)
        -> (result: Double?, isPending: Bool, description: String) {
            var accumulator: (Double, String)?
            var pbo: PendingBinaryOperation?
            var resultIsPending: Bool {
                get {
                    return pbo != nil
                }
            }
            var description: String? {
                get {
                    if resultIsPending {
                        return pbo!.description(pbo!.firstOperand.1, accumulator?.1 ?? "")
                    } else {
                        return accumulator?.1
                    }
                }
            }
            
            func performPendingBinaryOperation() {
                if (pbo != nil && accumulator != nil) {
                    accumulator = pbo!.perform(with: accumulator!)
                    pbo = nil
                }
            }
            
            func performOperation(_ symbol: String) {
                if let operation = operations[symbol] {
                    switch operation {
                    case .constant(let value):
                        accumulator = (value, symbol)
                        break
                    case .unaryOperation(let function, let description):
                        accumulator = (function(accumulator!.0), description(accumulator!.1))
                        break
                    case .binaryOperation(let function, let descriptionFunction):
                        if (accumulator != nil) {
                            pbo = PendingBinaryOperation(firstOperand: accumulator!, operation: function, description: descriptionFunction)
                            accumulator = nil
                        }
                        break
                    case .equals:
                        performPendingBinaryOperation()
                        break
                    default:
                        break
                    }
                } else {
                    let value = variables?[symbol] ?? 0.0
                    setOperand(value)
                }
            }
            
            func setOperand(_ operand: Double) {
                accumulator = (operand, "\(operand)")
            }
            
            func setOperand(variable named: String) {
                if let value = variables?[named] {
                    setOperand(value)
                } else {
                    setOperand(0.0)
                }
                
            }
            
            if (internalProgram.isEmpty) {
                return (0, false, "")
            } else {
                for item in internalProgram {
                    switch (item) {
                    case .operand(let value):
                        setOperand(value)
                        break
                    case .variable(let value):
                        setOperand(variable: value)
                        break
                    case .operation(let value):
                        performPendingBinaryOperation()
                        performOperation(value)
                        break
                    }
                }
                
                return (accumulator?.0, resultIsPending, description ?? "")
            }
    }
}
