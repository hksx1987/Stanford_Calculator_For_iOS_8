//
//  ViewController.swift
//  NewCalculator
//
//  Created by Jack Huang on 15/2/7.
//  Copyright (c) 2015年 Jack's app for practice. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    
    var brain = CalculatorBrain()
    
    var isMiddleOfTyping = false
    var isDotTyped = false
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
        set {
            displayResult = brain.evaluateAndReportErrors()
            isMiddleOfTyping = false
        }
    }
    var displayResult: String {
        set {
            display.text = newValue
            if display.text == "0.0" { display.text = "0" }
            isMiddleOfTyping = false
        }
        get { return display.text! }
    }
    
    @IBAction func appendDigit(sender: UIButton) {
        if isMiddleOfTyping {
            display.text = display.text! + sender.currentTitle!
        } else {
            display.text = sender.currentTitle!
            isMiddleOfTyping = true
            if displayValue == 0 {
                isMiddleOfTyping = false
            }
        }
    }
    
    // Assignment for adding a dot button
    @IBAction func appendDot() {
        if !isDotTyped {
            if isMiddleOfTyping {
                display.text = display.text! + "."
            } else {
                display.text = "0."
                isMiddleOfTyping = true
            }
            isDotTyped = true
        }
    }
    
    // Assignment for adding a Pi button
    @IBAction func appendPi() {
        let pi = M_PI
        displayValue = brain.pushConstant("π", value: pi)
        isMiddleOfTyping = false
        isDotTyped = true
    }
    
    @IBAction func operate(sender: UIButton) {
        if isMiddleOfTyping { enter() }
        displayValue = brain.performOperation(sender.currentTitle!)
        display.text = brain.description + " = " + display.text!
    }
    
    @IBAction func enter() {
        if display.text!.hasPrefix("-") {
            display.text = dropFirst(display.text!)
            enter()
            // this is not an minus operation, it's '+/-'
            displayValue = brain.performOperation("-")
        } else {
            displayValue = brain.pushOperand(displayValue ?? 0)
        }
        isMiddleOfTyping = false
        isDotTyped = false
        display.text = brain.description + " = " + display.text!
    }
    
    // Assignment for adding a delete button
    // I do realize that countElements() and dropLast() would make it a lot easier.
    @IBAction func back() {
        let text = display.text! as NSString
        if text.length > 0 {
            display.text = text.substringToIndex(text.length-1)
        } else {
            displayValue = brain.undo()
            display.text = brain.description + " = " + display.text!
        }
    }
    
    // Assignment for changing a sign ( +/- )
    // Treat '+/-' as a unary operation
    @IBAction func changeSign() {
        if isMiddleOfTyping {
            if display.text!.hasPrefix("-") {
                display.text = dropFirst(display.text!)
            } else {
                display.text = "-" + display.text!
            }
        } else {
            displayValue = brain.performOperation("-")
        }
    }
    
    // Assignment for adding a cleaning button
    @IBAction func clean() {
        brain.clean()
        isMiddleOfTyping = false
        isDotTyped = false
        display.text = "\(0)"
    }
    
    // Assignment for push variable as operand to calculator brain
    @IBAction func appendVariable() {
        displayValue = brain.pushOperand("m")
        isMiddleOfTyping = false
    }
    
    // Assignment for set value for given variable
    // then also perform calculation (Notice that I made evaluate() function public so I can perform calculation when I need to)
    @IBAction func setVariableValue() {
        brain.variableValues["m"] = displayValue
        displayValue = brain.evaluate()
        isMiddleOfTyping = false
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is GraphViewController {
            let gvc = segue.destinationViewController as GraphViewController
            gvc.program = brain.program
        }
    }
}





































