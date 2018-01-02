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

public class RemoteCall : Span {
    
    var url : String!
    var httpMethod : String!
    var responseCode : Int!
    var timeout : Bool!
    var beginLongitude : CLLocationDegrees!
    var beginLatitude : CLLocationDegrees!
    var beginConnection: String!
    var beginProvider: String!
    var beginSSID: String!
    var endLongitude : CLLocationDegrees!
    var endLatitude : CLLocationDegrees!
    var endConnection: String!
    var endProvider: String!
    var endSSID: String!
    var complete: Bool!
    
    
    init(_ name: String, _ url: String, _ httpMethod: String, _ metrics: AsynchronousMetricsController) {
        super.init(name)
        self.beginSSID = SSIDSniffer.getSSID()
        let connectionInformation = NetworkReachability.getConnectionInformation()
        self.beginConnection = connectionInformation.0
        self.beginProvider = connectionInformation.1
        self.beginLatitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().0
        self.beginLongitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().1
        self.url = url
        self.httpMethod = httpMethod
        self.timeout = false
    }
    
    init(_ name: String, _ rootid : UInt64, _ parentid : UInt64, _ url: String, _ httpMethod: String, _ metrics: AsynchronousMetricsController) {
        super.init(name, rootid, parentid)
        self.beginSSID = SSIDSniffer.getSSID()
        let connectionInformation = NetworkReachability.getConnectionInformation()
        self.beginConnection = connectionInformation.0
        self.beginProvider = connectionInformation.1
        self.beginLatitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().0
        self.beginLongitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().1
        self.url = url
        self.httpMethod = httpMethod
        self.timeout = false
    }
    
    func endRemoteCall(metrics: AsynchronousMetricsController, responseCode: Int, timeout: Bool){
        self.endSSID = SSIDSniffer.getSSID()
        self.timeout = timeout
        let connectionInformation = NetworkReachability.getConnectionInformation()
        self.endConnection = connectionInformation.0
        self.endProvider = connectionInformation.1
        self.endLatitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().0
        self.endLongitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().1
        self.responseCode = responseCode
        self.complete = true;
    }
    
    override func close(_ filename: String, _ line: Int, _ function: String, _ metricsController: IntervalMetricsController, _ asyncController: AsynchronousMetricsController) {
        super.close(filename, line, function, metricsController, asyncController)
        if self.complete != true {
            self.forceEndRemoteCall(metrics: asyncController)
        }
    }
    
    func forceEndRemoteCall(metrics: AsynchronousMetricsController){
        self.endTime = Constants.getTimestamp()
        self.endSSID = SSIDSniffer.getSSID()
        self.timeout = false
        let connectionInformation = NetworkReachability.getConnectionInformation()
        self.endConnection = connectionInformation.0
        self.endProvider = connectionInformation.1
        self.endLatitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().0
        self.endLongitude = metrics.locationHandler.getUsersCurrentLatitudeAndLongitude().1
        self.duration = endTime - beginTime
        self.responseCode = 0
        self.name = self.name + " (FORCE ENDED) "
        self.complete = false
    }
    
    func getRemoteCallMeasurement() -> NSMutableDictionary {
        let remotecallDictionary = NSMutableDictionary()
        remotecallDictionary["requestMeasurement"] = getRequestMeasurement()
        remotecallDictionary["responseMeasurement"] = getResponseMeasurement()
        return remotecallDictionary
    }
    
    private func getRequestMeasurement() -> NSMutableDictionary {
        let measurement = NSMutableDictionary()
        measurement["type"] = "RemoteCallMeasurement"
        measurement["timestamp"] = beginTime
        measurement["remoteCallID"] = id
        measurement["networkConnection"] = beginConnection
        measurement["networkProvider"] = beginProvider
        measurement["longitude"] = beginLongitude
        measurement["latitude"] = beginLatitude
        measurement["ssid"] = beginSSID
        measurement["url"] = url
        measurement["httpMethod"] = httpMethod
        return measurement
    }
    
    private func getResponseMeasurement() -> NSMutableDictionary {
        let measurement = NSMutableDictionary()
        measurement["type"] = "RemoteCallMeasurement"
        measurement["timestamp"] = endTime
        measurement["remoteCallID"] = id
        measurement["networkConnection"] = endConnection
        measurement["networkProvider"] = endProvider
        measurement["responseCode"] = responseCode
        measurement["timeout"] = timeout
        measurement["longitude"] = endLongitude
        measurement["latitude"] = endLatitude
        measurement["ssid"] = endSSID
        return measurement
    }

}
