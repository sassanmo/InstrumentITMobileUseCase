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
import CoreLocation

class DataSerializer {
    
    var metricsJsonData : String!
    var spans : [UInt64 : [[String : Any]]]
    
    init() {
        spans = [UInt64 : [[String : Any]]]()
    }
    
    func serializeSpan(_ span : Span) {
        if let uc = span as? UseCase {
            self.serializeUsecaseSpan(uc)
        } else if let rc = span as? RemoteCall {
            self.serializeRemoteCallSpan(rc)
        }
    }
    
    func serializeUsecaseSpan(_ usecase: UseCase) {
        var span: [String : Any] = [String : Any]()
        var tags: [String : Any] = [String : Any]()
        var spanContext: [String : Any] = [String : Any]()
        span["operationName"] = usecase.name
        span["startTimeMicros"] = usecase.beginTime
        span["duration"] = usecase.duration
        tags["span.kind"] = "client"
        tags["ext.propagation.type"] = "IOS"
        span["tags"] = tags
        spanContext["id"] = usecase.id
        spanContext["traceId"] = usecase.traceid
        spanContext["parentId"] = usecase.parentid
        span["spanContext"] = spanContext
        if spans[usecase.traceid] == nil {
            spans[usecase.traceid] = [[String : Any]]()
        }
        spans[usecase.traceid]?.append(span)
    }
    
    func serializeRemoteCallSpan(_ remotecall: RemoteCall) {
        var span: [String : Any] = [String : Any]()
        var tags: [String : Any] = [String : Any]()
        var spanContext: [String : Any] = [String : Any]()
        span["operationName"] = remotecall.name
        span["startTimeMicros"] = remotecall.beginTime
        span["duration"] = remotecall.duration
        tags["http.url"] = remotecall.url
        tags["http.request.networkConnection"] = remotecall.beginConnection
        tags["http.request.latitude"] = remotecall.beginLatitude
        tags["http.request.longitude"] = remotecall.beginLongitude
        tags["http.request.ssid"] = remotecall.beginSSID
        tags["http.request.networkProvider"] = remotecall.beginProvider
        tags["http.request.responseCode"] = remotecall.responseCode
        tags["http.request.timeout"] = remotecall.timeout
        tags["http.response.networkConnection"] = remotecall.endConnection
        tags["http.response.latitude"] = remotecall.endLatitude
        tags["http.response.longitude"] = remotecall.endLongitude
        tags["http.response.ssid"] = remotecall.endSSID
        tags["http.response.networkProvider"] = remotecall.endProvider
        tags["http.response.timeout"] = remotecall.timeout
        tags["ext.propagation.type"] = "HTTP"
        tags["span.kind"] = "client"
        span["tags"] = tags
        spanContext["id"] = remotecall.id
        spanContext["traceId"] = remotecall.traceid
        spanContext["parentId"] = remotecall.parentid
        span["spanContext"] = spanContext
        if spans[remotecall.traceid] == nil {
            spans[remotecall.traceid] = [[String : Any]]()
        }
        spans[remotecall.traceid]?.append(span)
    }
    
    
    func getJsonObject(_ metricsController : IntervalMetricsController, deviceID : UInt64, rootId: UInt64) -> String? {
        var timestampList = metricsController.timestampList
        var cpuList = metricsController.cpuList
        var powerList = metricsController.powerList
        var memoryList = metricsController.memoryList
        var diskList = metricsController.diskList
        
        var measurements = [NSMutableDictionary]()
        
        for (i, _) in timestampList.enumerated() {
                let measurement = NSMutableDictionary()
                measurement["type"] = "MobilePeriodicMeasurement"
                measurement["timestamp"] = timestampList[i]
                if i < cpuList.count {
                    measurement["cpuUsage"] = cpuList[i]
                }
                if i < powerList.count {
                    measurement["batteryPower"] = powerList[i]
                }
                if i < memoryList.count {
                    measurement["memoryUsage"] = memoryList[i]
                }
                if i < diskList.count {
                    measurement["storageUsage"] = diskList[i]
                }
                measurements.append(measurement)
        }
        
        var jsonObject = [String : Any]()
        jsonObject["deviceID"] = deviceID
        jsonObject["spans"] = spans[rootId]
        jsonObject["measurements"] = measurements

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
            let jsonString : String = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            print(jsonString)
            spans[rootId] = []
            return jsonString
        } catch {
            print(error)
        }
        return nil
    }
}
