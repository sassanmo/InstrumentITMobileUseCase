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

class IntervalMetricsController {
    
    var networkReachability : NetworkReachability!
    var nativeDiagnosticInfo : native_diagnostic_info_t
    
    var networktypeList : [String]
    var cpuList : [Float]
    var memoryList : [Float]
    var diskList : [Double]
    var powerList : [Float]
    var timestampList : [UInt64]
    
    var timer : Timer
    
    let MAX_SPACE : Int = 100
    
    /// Default timer time intervall 5 seconds
    var fireTimeIntervall : Float = 5
    
    init() {
        timer = Timer()
        networkReachability = NetworkReachability()
        
        nativeDiagnosticInfo = native_diagnostic_info_t()
        
        networktypeList = [String]()
        cpuList = [Float]()
        memoryList = [Float]()
        diskList = [Double]()
        powerList = [Float]()
        timestampList = [UInt64]()
        self.reinitializeTimer()
    }
    
    func changeTimerIntervall(seconds: Float) {
        self.fireTimeIntervall = seconds
    }
    
    func getCpuUsage() -> Float {
        if getCPULoad(&nativeDiagnosticInfo.cpuusage) == 0 {
            return nativeDiagnosticInfo.cpuusage
        } else {
            return -1.0;
        }
    }
    
    func getResidentalMemorySize() -> UInt64 {
        getMemoryUsage(&nativeDiagnosticInfo.memory.memory_info)
        return nativeDiagnosticInfo.memory.memory_info.rss
    }
    
    func getVirtualMemorySize() -> UInt64 {
        getMemoryUsage(&nativeDiagnosticInfo.memory.memory_info)
        return nativeDiagnosticInfo.memory.memory_info.vs
    }
    
    func getMemoryLoad() -> Float {
        return 1.0 - (Float(getFreeMemory()) / Float(ProcessInfo.processInfo.physicalMemory))
    }
    
    func getMemorySize() -> UInt64 {
        return UInt64(getResidentMemory())
    }
    
    func getFreeMem() -> Int64 {
        return getFreeMemory()
    }
    
    func getDataInSpecificIntervall() {
        self.getAllMetrics()
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.fireTimeIntervall), target: self, selector: #selector(self.getAllMetrics), userInfo: nil, repeats: true);
    }
    
    func reinitializeTimer() {
        DispatchQueue.main.async(execute: {
            self.timer.invalidate()
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(self.fireTimeIntervall), target: self, selector: #selector(self.getAllMetrics), userInfo: nil, repeats: true);
            
        })
    }
    
    func invalidateTimer() {
        self.timer.invalidate()
    }
    
    @objc func getAllMetrics() {
        let cpupercentage = getCpuUsage()
        let memory = getMemoryLoad()
        let disk = DiskMetric.getUsedDiskPercentage()
        let power = BatteryLevel.getBatteryLevel()
        let timestamp = Constants.getTimestamp()
      
        if (cpuList.count >= MAX_SPACE) {
            self.cpuList.remove(at: 0)
            self.memoryList.remove(at: 0)
            self.diskList.remove(at: 0)
            self.powerList.remove(at: 0)
            self.timestampList.remove(at: 0)
        }
        
        self.cpuList.append(cpupercentage)
        self.memoryList.append(memory)
        self.diskList.append(disk)
        self.powerList.append(power)
        self.timestampList.append(timestamp)

        if NetworkReachability.getConnectionInformation().0 == "WLAN" {
            Agent.getInstance().spansDispatch()
        }
    }
}
