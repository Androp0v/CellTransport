//
//  LineChart4View.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 17/08/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import UIKit
import simd
import SceneKit

class LineChart4: UIView{
       
    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let gridLayer: CALayer = CALayer()
    private var dataPoints: [CGPoint]?
    
    private var graphWidth: CGFloat = 0
    private var graphHeight: CGFloat = 0
    private var graphOrigin: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
    let bins: Int = 1000
    
    var histogramArray = [Float](repeating: 0.0, count: 1000)
    public var returnableArray: [Float] = []
    
    func getHistogramData() -> [[Float]]{
        return [returnableArray]
    }
        
    func clearHistogram(){
        histogramArray = [Float](repeating: 0.0, count: bins)
    }
        
    func drawChart(cellRadius: Float, counts: [Int], autoMerge: Bool) {
                    
        if !autoMerge{
            clearHistogram()
        }
    
        DispatchQueue.main.sync {
            self.graphWidth = self.frame.width
            self.graphHeight = self.frame.height
            self.graphOrigin = self.bounds.origin
        }
        
        let path = histogramPath(cellRadius: cellRadius, counts: counts, width: self.graphWidth, height: self.graphHeight, coordinateOrigin: self.graphOrigin)
        
        DispatchQueue.main.sync {
            self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = UIColor.white.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            self.layer.addSublayer(lineLayer)
            self.returnableArray = self.histogramArray
        }
                    
    }
    
    func histogramPath(cellRadius: Float, counts: [Int], width: CGFloat, height: CGFloat, coordinateOrigin: CGPoint) -> UIBezierPath {
        
        let path = UIBezierPath()
        
        histogramArray = [Float](repeating: 0.0, count: parameters.maxNSegments)
        
        histogramLengths(lengths: counts, histogramArray: &histogramArray)
                
        let baseLineHeight: CGFloat = 8.0
        let topMargin: CGFloat = 8.0
        
        let binDrawWidth: CGFloat = CGFloat(width)/CGFloat(parameters.maxNSegments)
        let binDrawHeight: CGFloat = (height - topMargin - baseLineHeight)/CGFloat(histogramArray.max()!)
        
        var newPosition = CGPoint(x: coordinateOrigin.x, y: height - baseLineHeight - CGFloat(histogramArray[0])*binDrawHeight)
        
        path.move(to: newPosition)
        
        for i in 0..<(parameters.maxNSegments - 1){
            newPosition = CGPoint(x: newPosition.x + binDrawWidth, y: newPosition.y)
            path.addLine(to: newPosition)
            newPosition = CGPoint(x: newPosition.x, y: height - baseLineHeight - CGFloat(histogramArray[i + 1])*binDrawHeight)
            path.addLine(to: newPosition)
        }
        newPosition = CGPoint(x: newPosition.x + binDrawWidth, y: newPosition.y)
        path.addLine(to: newPosition)
                
        return path
    }
    
    
}
