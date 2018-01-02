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
import UIKit

struct Constants {
    static let INVALID = "INVALID".data(using: .utf8)
    static var HOST : String = "http://141.58.46.160:8183"
    static let submitResultUrl : String = "/rest/mobile/newinvocation"
    static var spanServicetUrl : String = "http://141.58.46.160:8182"
    static let UNKNOWN : String = "unknown"
    
    static func getTimestamp() -> UInt64 {
        return UInt64(NSDate().timeIntervalSince1970 * 1000000.0)
    }
    
    static func decimalToHex(decimal: UInt64) -> String {
        return String(decimal, radix: 16)
    }
    
    static func alert(windowTitle : String, message : String, confirmButtonName : String) -> UIAlertController {
        let alert = UIAlertController(title: windowTitle, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: confirmButtonName, style: UIAlertActionStyle.default, handler: nil))
        return alert;
    }
    
    static func addLabel(text : String, x : CGFloat, y : CGFloat, width : CGFloat, height : CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: x, y: y, width: width, height: height))
        label.text = text
        return label
    }
}
