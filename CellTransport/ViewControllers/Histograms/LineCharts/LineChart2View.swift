//
//  LineChart2View.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 17/08/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import UIKit
import simd
import SceneKit

class LineChart2: UIView {
       
    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let gridLayer: CALayer = CALayer()
    private var dataPoints: [CGPoint]?
    
    private var graphWidth: CGFloat = 0
    private var graphHeight: CGFloat = 0
    private var graphOrigin: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
    let bins: Int = 2000
    let correlationTime: Float = 240.0 // s
    var timeOfLastGraph: Float = 0.0 // s
    
    var histogramArray = [Float](repeating: 0.0, count: 2000)
    public var returnableArray: [Float] = []
    
    func getHistogramData() -> [[Float]] {
        return [returnableArray]
    }
        
    func clearHistogram() {
        histogramArray = [Float](repeating: 0.0, count: bins)
        timeOfLastGraph = 0
    }
        
    func drawChart(times: UnsafeMutablePointer<Float>, nBodies: Int, autoMerge: Bool) {
                    
        if !autoMerge {
            clearHistogram()
        }

        // Compute merged histogram only if a greater timestep than correlation time has elapsed
        if autoMerge {
            guard Parameters.time - timeOfLastGraph > correlationTime else { return }
            timeOfLastGraph = Parameters.time
        }
        
        DispatchQueue.main.sync {
            self.graphWidth = self.frame.width
            self.graphHeight = self.frame.height
            self.graphOrigin = self.bounds.origin
        }
        
        let path = histogramPathTimes(times: times,
                                      nBodies: nBodies,
                                      width: self.graphWidth,
                                      height: self.graphHeight,
                                      coordinateOrigin: self.graphOrigin)
        
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
    
    func histogramPathTimes(times: UnsafeMutablePointer<Float>, nBodies: Int, width: CGFloat, height: CGFloat, coordinateOrigin: CGPoint) -> UIBezierPath {
        
        let path = UIBezierPath()
        
        histogramTimes(times: times, nbodies: nBodies, bins: bins, histogramArray: &histogramArray)
        
        let baseLineHeight: CGFloat = 8.0
        let topMargin: CGFloat = 8.0
        
        let binDrawWidth: CGFloat = CGFloat(width)/CGFloat(bins)
        let binDrawHeight: CGFloat = (height - topMargin - baseLineHeight)/CGFloat(histogramArray.max()!)
        
        var newPosition = CGPoint(x: coordinateOrigin.x, y: height - baseLineHeight - CGFloat(histogramArray[0])*binDrawHeight)
        
        path.move(to: newPosition)
        
        for i in 0..<(bins - 1) {
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
