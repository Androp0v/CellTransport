//
//  IOFunctions.swift
//  CellTransport
//
//  Created by Raúl Montón Pinillos on 05/03/2020.
//  Copyright © 2020 Raúl Montón Pinillos. All rights reserved.
//

import Foundation

func exportHistogramToFile(histogram: [Float], folderURL: URL, filename: String){
        
    var exportURL = folderURL
    exportURL.appendPathComponent(filename + String(".txt"))
    
    //Convert array of floats to array of Strings
    let numberFormat = NumberFormatter()
    numberFormat.numberStyle = .scientific
    let histogramStringArray = histogram.map{numberFormat.string(from: NSNumber(value: $0))!}
    
    //Merge into a single string, separated by \n
    let histogramString = histogramStringArray.joined(separator: "\n")
    
    //Write to file (atomically!)
    do{
        try histogramString.write(to: exportURL, atomically: true, encoding: .utf8)
    } catch let IOError {
        print(IOError)
    }
    
}
