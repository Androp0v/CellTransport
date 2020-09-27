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
    
    private var graphWidth: CGFloat = 0
    private var graphHeight: CGFloat = 0
    private var graphOrigin: CGPoint = CGPoint(x: 0.0, y: 0.0)
        
    let bins: Int = 1000
    
    var histogramArray = [Float](repeating: 0.0, count: 1000)
    var histogramArrayMTAttached = [Float](repeating: 0.0, count: 1000)
    
    public var returnableArray: [Float] = []
    
    func getHistogramData() -> [Float]{
        return returnableArray
    }
        
    func clearHistogram(){
        histogramArray = [Float](repeating: 0.0, count: bins)
        histogramArrayMTAttached = [Float](repeating: 0.0, count: bins)
    }
    
    func drawChart(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int, attachState: UnsafeMutablePointer<Int32>, autoMerge: Bool) {
                    
        if !autoMerge{
            clearHistogram()
        }
        
        DispatchQueue.main.sync {
            self.graphWidth = self.frame.width
            self.graphHeight = self.frame.height
            self.graphOrigin = self.bounds.origin
        }
        
        let (path,pathMTAttached) = histogramPath(cellRadius: cellRadius, distances: distances, nBodies: nBodies, attachState: attachState, width: self.graphWidth, height: self.graphHeight, coordinateOrigin: self.graphOrigin)
        
        
        DispatchQueue.main.sync {
            self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            
            let lineLayer = CAShapeLayer()
            lineLayer.path = path.cgPath
            lineLayer.strokeColor = UIColor.white.cgColor
            lineLayer.fillColor = UIColor.clear.cgColor
            self.layer.addSublayer(lineLayer)
            
            let lineLayerMTAttached = CAShapeLayer()
            lineLayerMTAttached.path = pathMTAttached.cgPath
            lineLayerMTAttached.strokeColor = UIColor.systemGreen.cgColor
            lineLayerMTAttached.fillColor = UIColor.clear.cgColor
            self.layer.addSublayer(lineLayerMTAttached)
            
            self.returnableArray = self.histogramArray
        }
    }
    
    func histogramPath(cellRadius: Float, distances: UnsafeMutablePointer<Float>, nBodies: Int, attachState: UnsafeMutablePointer<Int32>, width: CGFloat, height: CGFloat, coordinateOrigin: CGPoint) -> (UIBezierPath,UIBezierPath) {
        
        let path = UIBezierPath()
        let pathMTAttached = UIBezierPath()
 
        histogramWithAttachState(cellRadius: cellRadius, distances: distances, nDistances: nBodies, attachState: attachState, bins: bins, histogramArray: &histogramArray, histogramArrayMTAttached: &histogramArrayMTAttached)
        
        let baseLineHeight: CGFloat = 8.0
        let topMargin: CGFloat = 8.0
        let totalHistogramMax: CGFloat = CGFloat(histogramArray.max()!)
        
        let binDrawWidth: CGFloat = CGFloat(width)/CGFloat(bins)
        let binDrawHeight: CGFloat = (height - topMargin - baseLineHeight)/totalHistogramMax
        let binDrawHeightMTAttached: CGFloat = (height - topMargin - baseLineHeight)/totalHistogramMax
        
        var newPosition = CGPoint(x: coordinateOrigin.x, y: height - baseLineHeight - CGFloat(histogramArray[0])*binDrawHeight)
        var newPositionMTAttached = CGPoint(x: coordinateOrigin.x, y: height - baseLineHeight - CGFloat(histogramArrayMTAttached[0])*binDrawHeightMTAttached)
        
        path.move(to: newPosition)
        pathMTAttached.move(to: newPositionMTAttached)
        
        for i in 0..<(bins - 1){
            newPosition = CGPoint(x: newPosition.x + binDrawWidth, y: newPosition.y)
            path.addLine(to: newPosition)
            newPosition = CGPoint(x: newPosition.x, y: height - baseLineHeight - CGFloat(histogramArray[i + 1])*binDrawHeight)
            path.addLine(to: newPosition)
        }
        for i in 0..<(bins - 1){
            newPositionMTAttached = CGPoint(x: newPositionMTAttached.x + binDrawWidth, y: newPositionMTAttached.y)
            pathMTAttached.addLine(to: newPositionMTAttached)
            newPositionMTAttached = CGPoint(x: newPositionMTAttached.x, y: height - baseLineHeight - CGFloat(histogramArrayMTAttached[i + 1])*binDrawHeightMTAttached)
            pathMTAttached.addLine(to: newPositionMTAttached)
        }
        
        newPosition = CGPoint(x: newPosition.x + binDrawWidth, y: newPosition.y)
        path.addLine(to: newPosition)
        
        newPositionMTAttached = CGPoint(x: newPositionMTAttached.x + binDrawWidth, y: newPositionMTAttached.y)
        pathMTAttached.addLine(to: newPositionMTAttached)
                
        return (path,pathMTAttached)
    }

}
