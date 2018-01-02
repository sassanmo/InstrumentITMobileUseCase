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

class RestManager {

    /**
     Prepares a Post Request to the given URL (Path) by adding
     the body passed to this function. After receiving the response it is returned
     - parameters:
        - path: The path to address the request to
        - body: The Body for the POST request
        - completion: The callback which is called upon reception of the response
    */
    func makeHTTPPostRequest(path: String, body : String, completion: @escaping (String, Int, Bool)->()) -> Void {
        print("starting post request")
        let request = NSMutableURLRequest(url: URL(string: path)!)
        
        // Set the method to POST
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        
        // Set the POST body for the request
        let validatedJSON = validateJSON(json:body);
        if (validatedJSON != Constants.INVALID) {
            
            request.httpBody = validatedJSON;
            print("Request was successfully setup")
            performRequest(request: request, completion: completion);
        } else {
            print("JSON data is invalid, post Request aborted!");
            completion(String(), -1, false);
        }
    }
    
    /**
      Prepares a GET Request to the given URL (Path) by adding
      the parameters passed to this function as well as a '?' to the url.
      After receiving the response it is returned
     
     - parameters:
        - path: The path to address the request to
        - parameter: Optional parameters for the request (empty if non to add)
        - completion: The callback which is called upon reception of the response
     */
    func makeHTTPGetRequest(path: String, parameter:String, completion: @escaping (String, Int, Bool)->()) -> Void {
        print("starting get request")
        var url = path
        if !parameter.isEmpty {
            url.append("?"+parameter)
        }
        print(url)
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        // Set the method to GET
        request.httpMethod = "GET"
        performRequest(request: request, completion: completion);
    }
    
    /**
     Prepares a GET Request to the given URL (Path) by adding
     the parameters passed to this function as well as a '?' to the url.
     After receiving the response it is returned
     
     - parameters:
     - path: The path to address the request to
     - parameter: Optional parameters for the request (empty if non to add)
     - completion: The callback which is called upon reception of the response
     */
    func makeHTTPGetRequest(request: NSMutableURLRequest, completion: @escaping (String, Int, Bool)->()) -> Void {
        // Set the method to GET
        request.httpMethod = "GET"
        performRequest(request: request, completion: completion);
    }
    
    func getImage(request: NSMutableURLRequest, completion: @escaping (Data, Int)->()) -> Void {
        request.httpMethod = "GET"
        let session = URLSession.shared;
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            do{
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        if let receivedData = data {
                            completion(receivedData, httpResponse.statusCode)
                        }
                    } else {
                        completion(Data(), httpResponse.statusCode);
                    }
                }
            } catch {
                print(error)
                completion(error as! Data, 0);
            }
        })
        task.resume()
    }
    
    /**
     
    Performs an asynchroneous HTTP Request using the given URL Request parameter.
     
    - parameters:
        - request: The request to perform
        - completion: The callback which is called upon reception of the response
    */
    private func performRequest (request : NSMutableURLRequest, completion: @escaping (String, Int, Bool)->()) -> Void {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = request.timeoutInterval
        config.timeoutIntervalForResource = request.timeoutInterval
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            
            do {
                if(error == nil) {
                    if let httpResponse = response as? HTTPURLResponse {
                        if (httpResponse.statusCode == 200) {
                            if let receivedData = data {
                                let json = try JSONSerialization.jsonObject(with: receivedData, options:[])
                                let data1 = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted);
                                //print(data1[0])
                                completion(String(data: data1, encoding: String.Encoding.utf8)!, httpResponse.statusCode, false)
                            } else {
                                completion("unexpected Response from server", 0, false);
                            }
                        } else {
                            print(String(format: "%@%i", "The Server responded with Code: ", httpResponse.statusCode));
                            completion(String(format: "%@%i", "The Server responded with Code: ", httpResponse.statusCode), httpResponse.statusCode, false);
                        }
                    }
                } else {
                    let nserror = error as! NSError
                    if nserror.code == NSURLErrorTimedOut {
                        completion("Request timed out", -1, true)
                    }
                }
            } catch {
                let nserror = error as NSError
                if nserror.code == NSURLErrorTimedOut {
                    completion("Request timed out", -1, true)
                } else {
                    completion(error.localizedDescription, -1, false);
                }
            }
        })
        task.resume()
    }
    
    /**
    Validates a passed JSON and returns it as Data object if the validation passed.
    Otherwise an error String (formatted as JSON) is returned
     
     - parameters:
        - json: The json to validate
     */
    private func validateJSON(json: String) -> Data {
        do {
            let jsonData = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!)
            if (JSONSerialization.isValidJSONObject(jsonData)) {
                return try JSONSerialization.data(withJSONObject: jsonData);
            }
        } catch {
            print("The following inputstring caused an exception:");
            print(json);
        }
        print("invalid json");
        return Constants.INVALID!;
    }
    
    public func createRequestWithUrl(url : URL) -> NSMutableURLRequest{
        return NSMutableURLRequest(url: url)
    }
    
    public func createRequestWithUrlPath(path : String) -> NSMutableURLRequest{
        return NSMutableURLRequest(url: URL(string: path)!)
    }
    
}
