//
//  LineChartView.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 14/02/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation
import UIKit
import simd
import SceneKit

class LineChart1: UIView{
       
    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let gridLayer: CALayer = CALayer()
    private var dataPoints: [CGPoint]?
        
    let bins: Int = 1000
    
    var histogramArray = [Float](repeating: 0.0, count: 1000)
    public var returnableArray: [Float] = []
    
    func getHistogramData() -> [Float]{
        return returnableArray
    }
        
    func clearHistogram(){
        histogramArray = [Float](repeating: 0.0, count: bins)
    }
    
    func drawChart(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int, autoMerge: Bool) {
                    
        if !autoMerge{
            clearHistogram()
        }
        
        let path = histogramPath(cellRadius: cellRadius, distances: distances, nBodies: nBodies)
        
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
    
    func histogramPath(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int) -> UIBezierPath {
        
        let path = UIBezierPath()
        let coordinateOrigin = self.bounds.origin
        let width = CGFloat(self.frame.width)
        let height = CGFloat(self.frame.height)
        
        histogram(cellRadius: cellRadius, distances: distances, nDistances: nBodies, bins: bins, histogramArray: &histogramArray)
        
        let baseLineHeight: CGFloat = 8.0
        let topMargin: CGFloat = 8.0
        
        let binDrawWidth: CGFloat = CGFloat(width)/CGFloat(bins)
        let binDrawHeight: CGFloat = (height - topMargin - baseLineHeight)/CGFloat(histogramArray.max()!)
        
        var newPosition = CGPoint(x: coordinateOrigin.x, y: height - baseLineHeight - CGFloat(histogramArray[0])*binDrawHeight)
        
        path.move(to: newPosition)
        
        for i in 0..<(bins - 1){
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
