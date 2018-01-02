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

import Foundation
import SystemConfiguration.CaptiveNetwork

public class SSIDSniffer  {

    class func getSSID() -> String? {
        /* Note: 
            CNCopySupportedInterfaces returns nil while running on the emulator 
         */
        let interfaces = CNCopySupportedInterfaces()
        if(interfaces == nil) {
            return "NO SSID"
        }
        
        let interfaceArray = interfaces as! [String]
        if interfaceArray.count < 1 {
            return "NO SSID"
        }
        
        let interfaceName = interfaceArray[0] as String
        let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interfaceName as CFString)
        if(unsafeInterfaceData == nil) {
            return "NO SSID"
        }
        
        let interfaceData = unsafeInterfaceData as! Dictionary<String, AnyObject>
        return interfaceData["SSID"] as? String
    }
}
