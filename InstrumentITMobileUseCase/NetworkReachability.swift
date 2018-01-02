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
import Foundation
import SystemConfiguration
import CoreTelephony


class NetworkReachability {
    
    private static var defaultRoute : SCNetworkReachability!
    init() {
        var za = sockaddr_in()
        bzero(&za, MemoryLayout.size(ofValue: za))
        za.sin_len =  UInt8(MemoryLayout.size(ofValue: za))
        za.sin_family = sa_family_t(AF_INET)
        
        NetworkReachability.defaultRoute = withUnsafePointer(to: &za) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1, {address in
                SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, address)
            })
        }
    }
    
    static func getConnectionInformation() -> (String, String) {
        var flags : SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if !SCNetworkReachabilityGetFlags(NetworkReachability.defaultRoute, &flags) {
            return ("", "")
        }
        
        if flags == SCNetworkReachabilityFlags.isWWAN {
            let networkInfo = CTTelephonyNetworkInfo()
            var carrierName : String = ""
            if let c = networkInfo.subscriberCellularProvider?.carrierName {
                carrierName = c
            }
            let carrierType = networkInfo.currentRadioAccessTechnology
            switch carrierType{
            case CTRadioAccessTechnologyGPRS?,CTRadioAccessTechnologyEdge?,CTRadioAccessTechnologyCDMA1x?:
                return ("2G", carrierName)
            case CTRadioAccessTechnologyWCDMA?,CTRadioAccessTechnologyHSDPA?,CTRadioAccessTechnologyHSUPA?,CTRadioAccessTechnologyCDMAEVDORev0?,CTRadioAccessTechnologyCDMAEVDORevA?,CTRadioAccessTechnologyCDMAEVDORevB?,CTRadioAccessTechnologyeHRPD?:
                return ("3G", carrierName)
            case CTRadioAccessTechnologyLTE?:
                return ("4G", carrierName)
            default:
                return ("", carrierName)
            }
        } else if flags == SCNetworkReachabilityFlags.reachable {
            return ("WLAN", "")
        }
        return ("", "")
    }
}
