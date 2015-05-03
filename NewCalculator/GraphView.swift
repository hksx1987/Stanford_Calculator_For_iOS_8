//
//  GraphView.swift
//  NewCalculator
//
//  Created by Jack Huang on 15/2/12.
//  Copyright (c) 2015年 Jack's app for practice. All rights reserved.
//

import UIKit

protocol GraphViewDelegate : class {
    func graphView(graphView: GraphView, getValueFromX x: Float) -> Float
}

class GraphView: UIView {
    
    weak var delegate: GraphViewDelegate?
    lazy var axesDrawer = AxesDrawer()
    
    private var centerPoint: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    private var scale: CGFloat = 50.0 { // points per unit
        didSet {
            if oldValue > 100 { scale = 100 }
            if oldValue < 10 { scale = 10 }
        }
    }
    private var shouldMoveToPoint = true
    
    private struct FormulaPoint {
        var x: Float
        var y: Float
    }
    override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                shouldMoveToPoint = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func drawRect(rect: CGRect) {
        
        // Draw a coordinate
        axesDrawer.drawAxesInRect(rect, origin: convertPoint(center, fromView: superview), pointsPerUnit: scale)
        
        // Draw a math path
        let path = UIBezierPath()
        
        if let p = getDrawingPointForHorizontalPosition(0.0) {
            if canDrawPoint(p) {
                startPath(path, atPoint: p)
            }
        }
        
        //Draw every pixel From screen left edage to screen right edage
        var x: CGFloat = 0.0
        while x <= bounds.size.width {
            if let p = getDrawingPointForHorizontalPosition(x) {
                if canDrawPoint(p) {
                    startPath(path, atPoint: p)
                    path.addLineToPoint(p)
                }
                // println(p)
            }
            // Increased by not each point, but each pixel
            x += CGFloat(1.0) / contentScaleFactor
        }
        
//        if let p = getDrawingPointForHorizontalPosition(0.0) {
//            path.moveToPoint(p)
//        }
//        
//        for var px: CGFloat = 0.0; px <= bounds.size.width; px += (1.0/contentScaleFactor) {
//            if let p = getDrawingPointForHorizontalPosition(px) {
//                path.addLineToPoint(p)
//            }
//        }
        
        UIColor.blueColor().set()
        path.lineWidth = 1.0
        path.stroke()
    }
    
    private func canDrawPoint(p: CGPoint) -> Bool {
        return (abs(p.y) < max(bounds.size.width, bounds.size.height) + 50)
    }
    
    private func startPath(path: UIBezierPath, atPoint p: CGPoint) {
        if shouldMoveToPoint {
            path.moveToPoint(p)
            shouldMoveToPoint = false
        }
    }
    
    // MARK: - Gesture
    
    func scale(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            //scale *= gesture.scale
            shouldMoveToPoint = true
            //self.setNeedsDisplay()
        default: break
        }
    }
    
    func move(gesture: UIPanGestureRecognizer) {
        /*
        switch gesture.state {
        case .Ended: fallthrough
        case .Changed:
            let transition = gesture.translationInView(self)
        default: break
        }*/
    }
    
    // MARK: - Coordinate Conversion
    
    private func convertedViewPointFromFormulaPoint(p: FormulaPoint) -> CGPoint {
        return CGPointMake(convertedViewXFromFormulaX(p.x), convertedViewYFromFormulaY(p.y))
    }

    private func convertedFormulaPointFromViewPoint(p: CGPoint) -> FormulaPoint {
        return FormulaPoint(x: convertedFormulaXFromViewX(p.x), y: convertedFormulaYFromViewY(p.y))
    }
    
    private func convertedFormulaXFromViewX(vx: CGFloat) -> Float {
        return Float((vx - centerPoint.x) / scale)
    }

    private func convertedFormulaYFromViewY(vy: CGFloat) -> Float {
        return Float((-vy + centerPoint.y) / scale)
    }

    private func convertedViewXFromFormulaX(fx: Float) -> CGFloat {
        return CGFloat(fx) * scale + centerPoint.x
    }

    private func convertedViewYFromFormulaY(fy: Float) -> CGFloat {
        return CGFloat(-fy) * scale + centerPoint.y
    }
    
    // e.g. for y = x, when xInView = 0, get (0, yInView)
    private func getDrawingPointForHorizontalPosition(x: CGFloat) -> CGPoint? {
        let formulaX = convertedFormulaXFromViewX(x)
        if let value = delegate?.graphView(self, getValueFromX: formulaX) {
            //println("formulaPoint(x: \(formulaX), y: \(value))")
            let y = convertedViewYFromFormulaY(value)
            return CGPointMake(x, y)
        }
        return nil
    }
    

    
    // debug
//    private func testX(x: Float) -> CGPoint {
//        let y = x*cos(x)
//        let vx = CGFloat(x)*scale+bounds.size.width/2
//        let vy = CGFloat(-y)*scale+bounds.size.height/2
//        println("\(vx), \(vy)")
//        return CGPointMake(vx, vy)
//    }
    
}






















