//
//  GraphViewController.swift
//  NewCalculator
//
//  Created by Jack Huang on 15/2/12.
//  Copyright (c) 2015年 Jack's app for practice. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDelegate {
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.delegate = self
            graphView.setNeedsDisplay()
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "scale:"))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: "move:"))
            
            brain.program = program!
            let description = CalculatorBrain.descriptionOfProgram(program!)
            self.title = (description as NSString).length > 0 ? "y = \(description)" : "y = 0"
        }
    }
    
    var program: PropertyList?
    lazy var brain = CalculatorBrain()
    
    func graphView(GraphView, getValueFromX x: Float) -> Float {
        brain.variableValues["m"] = Double(x)
        return Float(brain.evaluate() ?? 0)
    }
    
    
}

// Convert Coordinate
// What is the Model ?
// Convert point to pixel
// Set .Redraw


