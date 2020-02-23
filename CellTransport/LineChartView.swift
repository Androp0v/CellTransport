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

class LineChart: UIView{
       
    private let gradientLayer: CAGradientLayer = CAGradientLayer()
    private let gridLayer: CALayer = CALayer()
    private var dataPoints: [CGPoint]?
    
    private var isBusy = false
    
    let bins: Int = 1000
    
    private var histogramArray = [Float](repeating: 0.0, count: 1000)
    
    func clearHistogram(){
        histogramArray = [Float](repeating: 0.0, count: bins)
    }
    
    func drawChart(cellRadius: Float, distances: UnsafeMutablePointer<Float>) {
        
        if !isBusy{
            isBusy = true
            
            clearHistogram()
            
            let path = histogramPath(cellRadius: cellRadius, distances: distances)
            
            DispatchQueue.main.async {
                self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                let lineLayer = CAShapeLayer()
                lineLayer.path = path.cgPath
                lineLayer.strokeColor = UIColor.white.cgColor
                lineLayer.fillColor = UIColor.clear.cgColor
                self.layer.addSublayer(lineLayer)
            }
            isBusy = false
        }
    }
    
    func histogramPath(cellRadius: Float, distances: UnsafeMutablePointer<Float>) -> UIBezierPath {
        
        let path = UIBezierPath()
        let coordinateOrigin = self.bounds.origin
        let width = CGFloat(self.frame.width)
        let height = CGFloat(self.frame.height)
        
        histogram(cellRadius: cellRadius, distances: distances, bins: bins, histogramArray: &histogramArray)
        
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
    
    func randomPath() -> UIBezierPath {
        let path = UIBezierPath()
        let coordinateOrigin = self.bounds.origin
        let width = CGFloat(self.frame.width)
        let height = CGFloat(self.frame.height)
                
        path.move(to: coordinateOrigin)
        
        for _ in 0...500{
            path.addLine(to: CGPoint(x: Double.random(in: Double(coordinateOrigin.x)...Double(coordinateOrigin.x + width)), y: Double.random(in: Double(coordinateOrigin.y)...Double(coordinateOrigin.y + height))))
        }
        
        return path
    }
    
    override func layoutSubviews() {
        
        //drawChart(positions: UnsafeMutablePointer<simd_float3>())
    }
}
