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

public class Span: NSObject {
    
    var id : UInt64
    var traceid : UInt64
    var parentid : UInt64
    
    var name : String
    var beginTime : UInt64!
    var endTime : UInt64!
    var duration: UInt64!
    var children = [Span]()
    
    init(_ name: String) {
        self.name = name
        self.id = Util.calculateUniqueId()
        self.traceid = self.id
        self.parentid = self.id
        self.beginTime = Constants.getTimestamp()
    }
    
    init(_ name : String, _ rootid : UInt64, _ parentid : UInt64) {
        self.name = name
        self.id = Util.calculateUniqueId()
        self.traceid = rootid
        self.parentid = parentid
        self.beginTime = Constants.getTimestamp();
    }
    
    // NOTE: this functions needs to be overiden
    func close(_ filename: String, _ line: Int, _ function: String, _ metricsController: IntervalMetricsController, _ asyncController: AsynchronousMetricsController) {
        self.endTime = Constants.getTimestamp()
        self.duration = endTime - beginTime
    }
}
