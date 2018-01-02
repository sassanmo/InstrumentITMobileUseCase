/*
 Copyright (c) 2017 Oliver Roehrdanz
 Copyright (c) 2017 Matteo Sassano
 Copyright (c) 2017 Christopher Voelker
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
 */

import UIKit

public class UseCase: Span {
    
    // Usecase attributes
    
    // Code based properties of a usecase
    var startFilename : String!
    var startLine : Int!
    var startfunction : String!
    var endFilename : String!
    var endLine : Int!
    var endfunction : String!
    
    // Start and end point attributes
    var beginPower, endPower : Float!
    var beginCpu, endCpu : Float!
    var beginMemory, endMemory : Float!
    
    
    /// UseCase constructor
    /// - parameter name: UseCase Name
    override init(_ name : String) {
        super.init(name)
    }
    
    /// UseCase constructor
    /// - parameter name: UseCase Name
    override init(_ name : String, _ rootid : UInt64, _ parentid : UInt64) {
        super.init(name, rootid, parentid)
    }
    
    /// Sets the beginning time of the usecase
    func setBeginTime(time : UInt64){
        self.beginTime = time
    }
    
    /// Opens a usecase
    /// Sets begin measurements of the usecase
    func openUseCase(_ filename: String, _ line: Int, _ function: String, _ metricsController: IntervalMetricsController){
        self.startFilename = filename
        self.startLine = line
        self.startfunction = function
        self.beginPower = BatteryLevel.getBatteryLevel()
        self.beginCpu = metricsController.getCpuUsage()
        self.beginMemory = metricsController.getMemoryLoad()
        let log = "****UseCase \(self.name) started.\r\(Date()) \(filename)(\(line)) \(function):\r"
        //print(log)
    }
    
    override func close(_ filename: String, _ line: Int, _ function: String, _ metricsController: IntervalMetricsController, _ asyncController: AsynchronousMetricsController) {
        super.close(filename, line, function, metricsController, asyncController)
        self.closeUseCase(filename, line, function, metricsController)
    }
    
    /// Opens a usecase
    /// Sets end measurements of the usecase
    func closeUseCase(_ filename: String, _ line: Int, _ function: String, _ metricsController: IntervalMetricsController){
        self.endFilename = filename
        self.endLine = line
        self.endfunction = function
        self.endPower = BatteryLevel.getBatteryLevel()
        self.endCpu = metricsController.getCpuUsage()
        self.endMemory = metricsController.getMemoryLoad()
        var log = ""
        log = "****UseCase \(self.name) ended in \(self.duration) seconds.\r\(Date()) \(filename)(\(line)) \(function):\r"
        //print(log)
    }
    
    /// Returns a "PeriodicMeasurement" from the starting point of the usecase
    /// PeriodicMeasurement returned as a NSMutableDictionary (good way for working with JSON)
    func getStartMeasurement() -> NSMutableDictionary {
        let measurement = NSMutableDictionary()
        measurement["type"] = "PeriodicMeasurement"
        measurement["timestamp"] = beginTime
        measurement["power"] = beginPower
        measurement["cpu"] = beginCpu
        measurement["memory"] = beginMemory
        return measurement
    }
    
    /// Returns a "PeriodicMeasurement" from the ending point of the usecase
    /// PeriodicMeasurement returned as a NSMutableDictionary (good way for working with JSON)
    func getEndMeasurement() -> NSMutableDictionary {
        let measurement = NSMutableDictionary()
        measurement["type"] = "PeriodicMeasurement"
        measurement["timestamp"] = endTime
        measurement["power"] = endPower
        measurement["cpu"] = endCpu
        measurement["memory"] = endMemory
        return measurement
    }
    
    /// Prints a usecase
    func printUseCase() {
        let usecasestring = "Usecase: \(self.name) \n ID: \(self.id) \n traceID: \(self.traceid) \n parentID: \(self.parentid) \n"
        //print(usecasestring)
    }

}
