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

/// The Agent allows to open usecase- or remotecall spans and to close them.
/// It makes sure to retrive all important data which are needed to make a precice diagnose of a certain usecase
/// In addition it looks that the gathered information will be sent to the CMR or in other cases stored on disk
public class Agent {
    
    /// Collects device Infromation in a specific time interval
 var intervalMetricsConrtoller : IntervalMetricsController!
    
    /// Collects device Infromation asynchronously
    var asyncMetricsConrtoller : AsynchronousMetricsController!
    
    /// Serializes gathered information and converts them to a convetional data format
    var dataSerializer : DataSerializer!
    
    /// Restmanager handles HTTP requests
    var restManager : RestManager!
    
    /// Agent singleton
    static var agent : Agent!
    
    /// Agent/Device id
    var id : UInt64!
    
    /// Storage for usecase output in JSON format
    var usecaseOutputStorage : [String]!
    
    /// Storage for usecase output in JSON format
    var usecaseOutputStorageBuffer : [String]!
    
    /// Storage controller for saving usecases on disk
    var storageController: DataStorage!
    
    /// Running Span Dictionary, Threadsafe,
    /// Mapping root usecase name with own subspans
    var spanDictionary = [String: [Span]!]()
	var spanIDDictionary = [UInt64: [Span]!]()
    
    var spanNameForRootID = [String: Span]()
    var spanMap = [UInt64 : Span]()
    var lastChild = [Span: Span]()
    
    var dispatchAllowed: Bool = true
    
    /// Agent Constructor, initializes the agent and ist submodules
    private init() {
        storageController = DataStorage()
        intervalMetricsConrtoller = IntervalMetricsController()
        asyncMetricsConrtoller = AsynchronousMetricsController()
        dataSerializer = DataSerializer()
        usecaseOutputStorage = loadUsecasesFromStorage()
        usecaseOutputStorageBuffer = usecaseOutputStorage
        loadAgentId()
        restManager = RestManager()
        Agent.agent = self
        loadConstantsFromStorage()
    }
    
    /// Checks if an agent insance exists and returns it.
    /// If not returns an new Agent instance
    ///
    /// - returns: agent instance
    public static func getInstance() -> Agent {
        if agent == nil {
            return Agent()
        } else {
            return agent
        }
    }
    
    /// Get all the children by breath first search
    ///
    /// - parameters:
    ///     - span: the span object
    /// - returns: list of children span objects
    private func getChildren(span : Span) -> [Span] {
        var children = [Span]()
        children.append(span)
        var ctr = 0
        while ctr < children.count {
            let s : Span = children[ctr]
            children.append(contentsOf: s.children)
            ctr += 1
        }
        return children
    }
    
    
    /// Get the span object for the name
    ///
    /// - parameters:
    ///     - name: the name of the span
    /// - returns: the span object if available
    func getRootSpanForString(name: String) -> Span? {
        return self.spanNameForRootID[name]
    }
    
    /// Get the span object as part of the root
    ///
    /// - parameters:
    ///     - root: the span object
    ///     - parent: the name of the parent
    /// - returns: the span object if available
    func getSpanInRoot(root : Span, parent: String) -> Span? {
        for s in self.getChildren(span: root) {
            if s.name == parent {
                return s
            }
        }
        return nil
    }
    
    /// Check whether a root use case with the given name does already exist
    ///
    /// - parameters:
    ///     - root: name of the root use case
    /// - returns: true iff the root use case does exist
    private func doesSpanStackForRootStringExist(root: String) -> Bool {
        return self.spanDictionary[root] != nil
    }
    
    /// Check whether a root use case with the given name does already exist
    ///
    /// - parameters:
    ///     - root: name of the root use case
    /// - returns: true iff the root use case does exist
    private func doesSpanStackForRootExist(root: UInt64) -> Bool {
        return self.spanIDDictionary[root] != nil
    }
    
    
    /// Start the timer
    ///
    private func startTimer() {
        if(!self.intervalMetricsConrtoller.timer.isValid) {
            self.intervalMetricsConrtoller.getDataInSpecificIntervall()
        }
    }
    
    
    /// Start a new remote call
    ///
    /// - parameters:
    ///     - name: the name of the remote call
    ///     - root: the name of the root 
    ///     - url: the url to use
    ///     - httpMethod: the http method to use 
    ///     - request: the request to use
    /// - returns: iff the root exists the remote call object will be returned 
    ///         otherwise nil will be returned
    public func startRemotecall(name: String, root: String, url: String, httpMethod: String, request: inout NSMutableURLRequest) -> RemoteCall? {
        if let rootspan : Span = self.spanNameForRootID[root] {
            return self.startRemotecall(name: name, parent: rootspan, url: url, httpMethod: httpMethod, request: &request)
        } else {
            print("ROOT WITH NAME '\(root)' NOT FOUND, CREATED NEW ROOT")
            return nil
        }
    }
    
    
    /// Start a new remote call with a timeout
    ///
    /// - parameters:
    ///     - name: the name of the remote call
    ///     - root: the parent span
    ///     - url: the url to use
    ///     - httpMethod: the http method to use
    ///     - timeout: the time interval until a timeout
    ///     - request: the request to use
    /// - returns: the remote call object
    public func startRemotecall(name: String, parent: Span, url: String, httpMethod: String, timeout: TimeInterval, request: inout NSMutableURLRequest) -> RemoteCall {
        request.timeoutInterval = timeout
        return startRemotecall(name: name, parent: parent, url: url, httpMethod: httpMethod, request: &request)
    }
    
    /// Start a new remote call call with the given name in the tree of the given root
    /// and insert after the last previously inserted span. If the response 
    /// exeeds the given timeout abort
    ///
    /// - parameters:
    ///     - name: the name of the remote call
    ///     - root: the span object
    ///     - url: the url to call
    ///     - httpMethod: the httpMethod to use
    ///     - request: the request to use
    func startRemotecallAppendLast(name: String, root: Span, url: String, httpMethod: String, timeout: TimeInterval, request: inout NSMutableURLRequest) -> RemoteCall {
        request.timeoutInterval = timeout
        return self.startRemotecall(name: name, parent: self.lastChild[root]!, url: url, httpMethod: httpMethod, request: &request)
    }
    
    /// Start a new remote call call with the given name in the tree of the given root
    /// and insert after the last previously inserted span.
    ///
    /// - parameters:
    ///     - name: the name of the remote call 
    ///     - root: the span object 
    ///     - url: the url to call
    ///     - httpMethod: the httpMethod to use
    ///     - request: the request to use
    public func startRemotecallAppendLast(name: String, root: Span, url: String, httpMethod: String, request: inout NSMutableURLRequest) -> RemoteCall {
        return self.startRemotecall(name: name, parent: self.lastChild[root]!, url: url, httpMethod: httpMethod, request: &request)
    }
    
    /// Start a new remote call
    ///
    /// - parameters:
    ///     - name: the name of the remote call
    ///     - root: the parent span
    ///     - url: the url to use
    ///     - httpMethod: the http method to use
    ///     - request: the request to use
    /// - returns: the remote call object
    public func startRemotecall(name: String, parent: Span, url: String, httpMethod: String, request: inout NSMutableURLRequest) -> RemoteCall {
        let remotecall : RemoteCall = RemoteCall(name, parent.traceid, parent.id, url, httpMethod, self.asyncMetricsConrtoller)
        self.addHeaderAttributes(request: request, id: remotecall.id, rootid: remotecall.traceid)
        parent.children.append(remotecall)
        
        self.spanMap[remotecall.id] = remotecall
        self.lastChild[self.spanMap[parent.traceid]!] = remotecall
        
        return remotecall
    }
    
    
    
    
    /// Start a new root use case with the given name
    ///
    /// - parameters:
    ///     - name: name of the use case
    /// - returns: the use case object
    public func startUseCase(name: String) -> UseCase {
        return self.startUseCase(parentSpan: nil, name: name)
    }
    
    /// Start a new use case with an optional given parent. If the parent is
    /// not given a new root use case will be created
    ///
    /// - parameters:
    ///     - parentSpan: the parent span object of the use case to create
    ///     - name: the name of the use case
    /// - returns: the created use case object
    public func startUseCase(parentSpan: Span?, name: String, filename: String = #file, line: Int = #line, funcname: String = #function) -> UseCase {
        if let parent : Span = parentSpan {
            // create the child use case
            let usecase : UseCase = UseCase(name, parent.traceid, parent.id)
            usecase.openUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
            parent.children.append(usecase)
            
            self.spanMap[usecase.id] = usecase
            self.spanNameForRootID[name] = usecase
            self.lastChild[self.spanMap[parent.traceid]!] = usecase

            self.startTimer()
            return usecase
        } else {
            // new root use case
            let usecase : UseCase = UseCase(name)
            
            self.spanMap[usecase.id] = usecase
            self.spanNameForRootID[name] = usecase
            self.lastChild[usecase] = usecase
            
            self.startTimer()
            return usecase
        }
    }
    
    /// Start a new use case with the given name in the tree of the given root
    /// and insert after the last previously inserted span.
    /// Create a new root if the root has not been found
    ///
    /// - parameters:
    ///     - name: the name of the use case to create
    ///     - root: the name of the root
    /// - returns: the created use case object
    public func startUseCaseAppendLast(name: String, root: String) -> UseCase {
        if let rootspan : Span = self.spanNameForRootID[root] {
            return self.startUseCaseAppendLast(name: name, root: rootspan)
        } else {
            print("ROOT WITH NAME '\(root)' NOT FOUND, CREATED NEW ROOT")
            return self.startUseCase(name: name)
        }
    }
    
    /// Start a new use case with the given name in the tree of the given root
    /// and insert after the last previously inserted span
    ///
    /// - parameters:
    ///     - name: the name of the use case to create 
    ///     - root: the root span object 
    /// - returns: the created use case object
    public func startUseCaseAppendLast(name: String, root: Span) -> UseCase {
        return self.startUseCase(parentSpan: self.lastChild[root]!, name: name)
    }
    
    /// Start the use case and append it at the end of the given root
    ///
    /// - parameters:
    ///     - name: the name of the use case
    ///     - root: the name of the root
    /// - returns: the created use case object
    public func startUseCase(name: String, root: String) -> UseCase {
        if let rootspan : Span = self.spanNameForRootID[root] {
            return self.startUseCase(name: name, root: rootspan)
        } else {
            print("ROOT WITH NAME '\(root)' NOT FOUND, CREATED NEW ROOT")
            return self.startUseCase(name: name)
        }
    }
    
    /// Start the use case and append it at the end of the given root
    ///
    /// - parameters:
    ///     - name: the name of the use case
    ///     - root: the root span object
    /// - returns: the created use case object
    public func startUseCase(name: String, root: Span) -> UseCase {
        return self.startUseCase(parentSpan: self.lastChild[root], name: name)
    }
    
    /// Start the use case and append it to the tree of the given root as child
    /// of the given parent
    ///
    /// - parameters:
    ///     - name: the name of the use case
    ///     - root: the name of the root
    ///     - parent: the name of the parent
    /// - returns: the created use case object
    public func startUseCase(name: String, root: String, parent: String) -> UseCase {
        return self.startUseCase(name: name, root: self.spanNameForRootID[root]!, parent: parent)
    }
    
    /// Start the use case and append it to the tree of the given root as child
    /// of the given parent
    ///
    /// - parameters:
    ///     - name: the name of the use case
    ///     - root: the root span object
    ///     - parent: the name of the parent
    /// - returns: the created use case object
    public func startUseCase(name: String, root: Span, parent: String) -> UseCase {
        for s in self.getChildren(span: root) {
            if s.name == parent {
                return self.startUseCase(parentSpan: s, name: name)
            }
        }
        return self.startUseCase(name: name)
    }
    
    /// Close the use case with the given name in the tree of the given root.
    /// This function returns without any modification if the root is not found.
    /// Note: if the span has children they will be closed
    ///
    /// - parameters:
    ///     - name: the name of the use case 
    ///     - root: the name of the root use case
    public func closeUseCase(name: String, root: String) {
        if let span : Span = self.spanNameForRootID[root] {
            self.closeUseCase(name: name, root: span)
        } else {
            print("WARNING! Root with name: '\(name) has not been found. Nothing has been closed'")
        }
    }
    
    /// Close the use case with the given name in the tree of the given root
    /// This function returns without any modification if the root is not found.
    /// Note: if the span has children they will be closed
    ///
    /// - parameters:
    ///     - name: the name of the use case
    ///     - root: the root span object
    public func closeUseCase(name: String, root: Span) {
        for s in self.getChildren(span: root) {
            if s.name == name {
                self.closeUseCase(span: s)
                return
            }
        }
        print("WARNING! Use Case with name: '\(name)' has not been found. Nothing has been closed")
    }
    
    
    /// Close the given span and all of its children if not already closed
    ///
    /// - parameters:
    ///     - usecase: the span object to close
    public func closeRemoteCall(span: RemoteCall, responseCode: Int, timeout: Bool) {
        span.endRemoteCall(metrics: self.asyncMetricsConrtoller, responseCode: responseCode, timeout: timeout)
        self.closeSpan(span)
    }
    
    /// Close all children of the given span which is nested into the given
    /// rootspan
    ///
    /// - parameters:
    ///     - span: the span to close the children of and to close
    ///     - rootspan: the root of the span
    private func closeChildren(_ span : Span, _  rootspan : Span, filename: String = #file, line: Int = #line, funcname: String = #function) {
        // now we need to close all spans bottom up, since the children list
        // is generated top down the reversed list is bottom up
        for s in self.getChildren(span: span).reversed() {
            // close the use case
            s.close(filename, line, funcname, self.intervalMetricsConrtoller, self.asyncMetricsConrtoller)
            
            if self.lastChild[rootspan]!.id == rootspan.id {
                self.lastChild[rootspan] = span
            }
            
            // remove everything from the span map
            self.spanMap[s.id] = nil
            
            // serialize the result
            self.dataSerializer.serializeSpan(s)
        }
    }
    
    /// Close the given span and all of its children if not already closed
    ///
    /// - parameters:
    ///     - usecase: the span object to close
    private func closeSpan(_ span : Span) {
        if let rootspan : Span = self.spanMap[span.traceid] {
        self.closeChildren(span, rootspan)
        
        // if the last element
        if rootspan.id == span.id {
            self.lastChild[span] = nil
            self.spanNameForRootID[span.name] = nil
            self.handleUsecaseDispatch(rootId: rootspan.traceid)
        } else {
            // Replace the stack end with the parent
            let parentspan : Span = self.spanMap[span.parentid]!
            if self.lastChild[rootspan]?.id == span.id {
                self.lastChild[rootspan] = parentspan
            }
        
            // remove the span as children from its parent
            for (index, s) in parentspan.children.enumerated() {
                if s.id == span.id {
                    parentspan.children.remove(at: index)
                    return
                }
            }
        }
        }
    }
    
    /// Close the given span and all of its children if not already closed
    ///
    /// - parameters:
    ///     - usecase: the span object to closex
    public func closeUseCase(span : Span) {
        self.closeSpan(span)
    }
    
    
    
    
    
    
    
    
    
    /// Starts a new root usecase and sets start properties such as beginTime, id, etc.
    /// Important: Two root usecases with the same name can't existst
    ///
    /// - parameters:
    ///     - name: name of the root usecase
    public func startRootUsecase(name: String, filename: String = #file, line: Int = #line, funcname: String = #function) -> UInt64 {
        let usecase : UseCase = UseCase(name)
        usecase.openUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
        if self.spanDictionary[name] == nil {
            var spanStack = [Span]()
            spanStack.append(usecase)
            self.spanDictionary[name] = spanStack
            self.spanIDDictionary[usecase.id] = spanStack
			return usecase.id
        } else {
            print("Usecase already started, command ignored")
			return 0
        }
        // Agent.pushUseCase(useCase: usecase)
        //self.startTimer()
    }

    /// Starts a new subusecase for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the subusecase
    ///     - root: id of the root usecase, which the subusecase should be appended on
    public func startUsecase(name: String, root: UInt64, filename: String = #file, line: Int = #line, funcname: String = #function) {
        var rootid: UInt64?
        var parentid: UInt64?
        if var spanStack = self.spanIDDictionary[root] {
            rootid = spanStack?.first?.id
            parentid = spanStack?.last?.id
            let usecase : UseCase = UseCase(name, rootid!, parentid!)
            spanStack.append(usecase)
            usecase.openUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
            self.spanIDDictionary[root] = spanStack
        } else {
            print("Root usecase not found, command ignored")
        }
        if (!self.intervalMetricsConrtoller.timer.isValid){
            self.intervalMetricsConrtoller.getDataInSpecificIntervall()
        }
    }

    /// Starts a new subusecase for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the subusecase
    ///     - root: name of the root usecase, which the subusecase should be appended on
    public func startUsecase(name: String, root: String, filename: String = #file, line: Int = #line, funcname: String = #function) {
        var rootid: UInt64?
        var parentid: UInt64?
        if var spanStack = self.spanDictionary[root] {
            rootid = spanStack?.first?.id
            parentid = spanStack?.last?.id
            let usecase : UseCase = UseCase(name, rootid!, parentid!)
            spanStack.append(usecase)
            usecase.openUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
            self.spanDictionary[root] = spanStack
        } else {
            print("Root usecase not found, command ignored")
        }
        if (!self.intervalMetricsConrtoller.timer.isValid){
            self.intervalMetricsConrtoller.getDataInSpecificIntervall()
        }
    }

    /// Closes a subusecase for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: name of the subusecase to close
    ///     - root: id of the root usecase, which the subusecase is appended on
    public func closeUsecase(name: String, root: UInt64, filename: String = #file, line: Int = #line, funcname: String = #function) {
        var usecasefound = false
        var foundIndex = -1
        if var spanStack = self.spanIDDictionary[root] {
            for (index, span) in spanStack.enumerated() {
                if span.name == name {
                    usecasefound = true
                    foundIndex = index
                }
                if usecasefound {
                    // Closing spans bottom-up
                    if spanStack.count > foundIndex {
                        if let usecase = span as? UseCase {
                            usecase.closeUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
                            self.dataSerializer.serializeUsecaseSpan(usecase)
                        } else if let remotecall = span as? RemoteCall {
                            remotecall.forceEndRemoteCall(metrics: self.asyncMetricsConrtoller)
                            self.dataSerializer.serializeRemoteCallSpan(remotecall)
                        }
                        spanStack.remove(at: spanStack.count - 1)
                    }
                }
            }
            if !usecasefound {
                print("Root usecase found, but not the subusecase. command ignored.")
            } else {
                if spanStack.isEmpty {
                    spanStack = nil
                    self.spanIDDictionary[root] = spanStack
                    self.handleUsecaseDispatch(rootId: root)
                } else {
                    self.spanIDDictionary[root] = spanStack
                }
            }
            
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(root))")
        }
    }


    /// Closes a subusecase for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: name of the subusecase to close
    ///     - root: name of the root usecase, which the subusecase is appended on
    public func closeUsecase(name: String, root: String, filename: String = #file, line: Int = #line, funcname: String = #function) {
        var usecasefound = false
        var foundIndex = -1
        if var spanStack = self.spanDictionary[root] {
            
            let rootId: UInt64 = spanStack[0].traceid
            for (index, span) in spanStack.enumerated() {
                if span.name == name {
                    usecasefound = true
                    foundIndex = index
                }
                if usecasefound {
                    // Closing spans bottom-up
                    if spanStack.count > foundIndex {
                        if let usecase = span as? UseCase {
                            usecase.closeUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
                            self.dataSerializer.serializeUsecaseSpan(usecase)
                        } else if let remotecall = span as? RemoteCall {
                            remotecall.forceEndRemoteCall(metrics: self.asyncMetricsConrtoller)
                            self.dataSerializer.serializeRemoteCallSpan(remotecall)
                        }
                        spanStack.remove(at: spanStack.count - 1)
                    }
                }
            }
            if !usecasefound {
                print("Root usecase found, but not the subusecase. command ignored.")
            } else {
                if spanStack.isEmpty {
                    spanStack = nil
                    self.spanDictionary[root] = spanStack
                    self.handleUsecaseDispatch(rootId: rootId)
                } else {
                    self.spanDictionary[root] = spanStack
                }
            }
            
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(root))")
        }
    }

    /// Closes a subusecase for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: id of the root usecase to close
    public func closeRootUsecase(name: UInt64, filename: String = #file, line: Int = #line, funcname: String = #function) {
        if var spanStack = self.spanIDDictionary[name] {
            let rootId : UInt64 = spanStack[0].traceid
            for span in spanStack.reversed() {
                if let usecase = span as? UseCase {
                    usecase.closeUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
                    self.dataSerializer.serializeUsecaseSpan(usecase)
                } else if let remotecall = span as? RemoteCall {
                    remotecall.forceEndRemoteCall(metrics: self.asyncMetricsConrtoller)
                    self.dataSerializer.serializeRemoteCallSpan(remotecall)
                }
                spanStack.removeLast()
            }
            spanStack = nil
            self.spanIDDictionary[name] = spanStack
            self.handleUsecaseDispatch(rootId: rootId)
            
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(name))")
        }
    }


    /// Closes a subusecase for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: name of the root usecase to close
    public func closeRootUsecase(name: String, filename: String = #file, line: Int = #line, funcname: String = #function) {
        if var spanStack = self.spanDictionary[name] {
            if spanStack != nil {
            let rootId : UInt64 = spanStack[0].traceid
            for span in spanStack.reversed() {
                if let usecase = span as? UseCase {
                    usecase.closeUseCase(filename, line, funcname, self.intervalMetricsConrtoller)
                    self.dataSerializer.serializeUsecaseSpan(usecase)
                } else if let remotecall = span as? RemoteCall {
                    remotecall.forceEndRemoteCall(metrics: self.asyncMetricsConrtoller)
                    self.dataSerializer.serializeRemoteCallSpan(remotecall)
                }
                spanStack.removeLast()
            }
            spanStack = nil
            self.spanDictionary[name] = spanStack
            self.handleUsecaseDispatch(rootId: rootId)
            }
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(name))")
        }
    }

    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: id of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCall(name: String, root: UInt64, url: String, httpMethod: String, request: inout NSMutableURLRequest) {
        var rootid: UInt64?
        var parentid: UInt64?
        request.url = URL(string: url)
        if var spanStack = self.spanIDDictionary[root] {
            rootid = spanStack?.first?.id
            parentid = spanStack?.last?.id
            let remotecall : RemoteCall = RemoteCall(name, rootid!, parentid!, url, httpMethod, self.asyncMetricsConrtoller)
            self.addHeaderAttributes(request: request, id: remotecall.id, rootid: remotecall.traceid)
            spanStack.append(remotecall)
            self.spanIDDictionary[root] = spanStack
        } else {
            print("Root usecase not found, command ignored")
        }
    }


    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: name of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCall(name: String, root: String, url: String, httpMethod: String, request: inout NSMutableURLRequest) {
        var rootid: UInt64?
        var parentid: UInt64?
        if var spanStack = self.spanDictionary[root] {
            rootid = spanStack?.first?.id
            parentid = spanStack?.last?.id
            let remotecall : RemoteCall = RemoteCall(name, rootid!, parentid!, url, httpMethod, self.asyncMetricsConrtoller)
            self.addHeaderAttributes(request: request, id: remotecall.id, rootid: remotecall.traceid)
            spanStack.append(remotecall)
            self.spanDictionary[root] = spanStack
        } else {
            print("Root usecase not found, command ignored")
        }
    }

    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: id of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - timeout: the timeout interval
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCallWithTimeout(name: String, root: UInt64, url: String, httpMethod: String, timeout: TimeInterval, request: inout NSMutableURLRequest) {
        request.timeoutInterval = timeout
        self.startRemoteCall(name: name, root: root, url: url, httpMethod: httpMethod, request: &request)
    }


    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: name of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - timeout: the timeout interval
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCallWithTimeout(name: String, root: String, url: String, httpMethod: String, timeout: TimeInterval, request: inout NSMutableURLRequest) {
        request.timeoutInterval = timeout
        self.startRemoteCall(name: name, root: root, url: url, httpMethod: httpMethod, request: &request)
    }
    
    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: name of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - timeout: the timeout interval
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCallWithTimeout(name: String, root: String, parent: String, url: String, httpMethod: String, timeout: TimeInterval, request: inout NSMutableURLRequest) {
        request.timeoutInterval = timeout
        self.startRemoteCall(name: name, root: root, parent: parent, url: url, httpMethod: httpMethod, request: &request)
    }
    
    /// Starts a new remotecall measurement for a specific root usecase and sets start properties such as beginTime, id, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall
    ///     - root: name of the root usecase, which the remotecall should be appended on
    ///     - url: url path of the remotecall
    ///     - httpMethod: http request method as String
    ///     - request: NSMutableURLRequest object needed to add header attributes
    public func startRemoteCall(name: String, root: String, parent: String, url: String, httpMethod: String, request: inout NSMutableURLRequest) -> RemoteCall? {
        var rootid: UInt64?
        var parentid: UInt64?
        if var spanStack = self.spanDictionary[root] {
            if spanStack != nil {
            rootid = spanStack?.first?.id
            for element in spanStack {
                if (element.name == parent) {
                    parentid = element.id
                }
            }
            if (parentid == nil) {
                parentid = spanStack?.first?.id
            }
            let remotecall : RemoteCall = RemoteCall(name, rootid!, parentid!, url, httpMethod, self.asyncMetricsConrtoller)
            self.addHeaderAttributes(request: request, id: remotecall.id, rootid: remotecall.traceid)
            spanStack.append(remotecall)
            self.spanDictionary[root] = spanStack
            return remotecall
            }
        } else {
            print("Root usecase not found, command ignored")
        }
        return nil
    }
    
    /// Closes a remotecall measurement for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall to close
    ///     - root: name of the root usecase, which the remotecall is appended on
    ///     - resposeCode: response code of the http request
    ///     - timeout: bool value if request was timed out
    public func closeRemoteCall(name: String, root: String, responseCode: Int, timeout: Bool) {
        var remotecallfound = false
        if var spanStack = spanDictionary[root] {
            //DispatchQueue.global().async {
            if spanStack != nil {
                for (index, span) in spanStack.enumerated() {
                    if span.name == name {
                        remotecallfound = true
                        if let remotecall = span as? RemoteCall {
                            remotecall.endRemoteCall(metrics: self.asyncMetricsConrtoller, responseCode: responseCode, timeout: timeout)
                            self.dataSerializer.serializeRemoteCallSpan(remotecall)
                        }
                        spanStack.remove(at: index)
                        if spanStack.isEmpty {
                            spanStack = nil
                        }
                        self.spanDictionary[root] = spanStack
                        return
                    }
                }
            }
                if !remotecallfound {
                    print("Root usecase found, but not the subusecase. command ignored.")
                }
           // }
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(root))")
        }
    }
    
    /// Closes a remotecall measurement for a specific root usecase and sets end properties such as endTime, duration, etc.
    ///
    /// - parameters:
    ///     - name: name of the remotecall to close
    ///     - root: name of the root usecase, which the remotecall is appended on
    ///     - resposeCode: response code of the http request
    ///     - timeout: bool value if request was timed out
    public func closeRemoteCall(name: String, root: String, id: UInt64, responseCode: Int, timeout: Bool) {
        var remotecallfound = false
        if var spanStack = spanDictionary[root] {
            for (index, span) in spanStack.enumerated() {
                if span.id == id {
                    remotecallfound = true
                    if let remotecall = span as? RemoteCall {
                        remotecall.endRemoteCall(metrics: self.asyncMetricsConrtoller, responseCode: responseCode, timeout: timeout)
                        self.dataSerializer.serializeRemoteCallSpan(remotecall)
                    }
                    spanStack.remove(at: index)
                    if spanStack.isEmpty {
                        spanStack = nil
                    }
                    self.spanDictionary[root] = spanStack
                    return
                }
            }
            if !remotecallfound {
                print("Root usecase found, but not the subusecase. command ignored.")
            }
        } else {
            print("Root usecase not found. Command to terminate usecase ignored. (Root: \(root))")
        }
    }
    
    /// Adds x-inspectit-id and x-inspectit-trace-id header attribute in request
    /// - Important: These attributes are needed to establish a correlation with client and server traces
    ///
    /// - parameters:
    ///     - request: NSMutableURLRequest object needed to add header attributes
    ///     - id: remotecall id
    ///     - rootid: root usecase id
    func addHeaderAttributes(request: NSMutableURLRequest, id: UInt64, rootid: UInt64) {
        request.addValue("\(Constants.decimalToHex(decimal: id))", forHTTPHeaderField: "x-inspectit-spanid")
        request.addValue("\(Constants.decimalToHex(decimal: rootid))", forHTTPHeaderField: "x-inspectit-traceid")
    }
    
    /// Initialize a timer interval with the given amount of seconds.
    /// The frequency of the timer is given by seconds
    ///
    /// - parameter seconds: the amount of seconds to use as timer interval
    public func changeTimerIntervall(seconds: Float) {
        intervalMetricsConrtoller.changeTimerIntervall(seconds: seconds)
        intervalMetricsConrtoller.reinitializeTimer()
    }
    
    /// Handles the distribution of the measured metrics
    /// - Important: JSON file only sent if Wifi connection is established. In other cases the information will be stored
    private func handleUsecaseDispatch(rootId: UInt64) {
        if let json = dataSerializer.getJsonObject(intervalMetricsConrtoller, deviceID: id, rootId: rootId) {
            usecaseOutputStorage.append(json)
        }
    }
    
    func spansDispatch() {
        if usecaseOutputStorage.count != 0 && dispatchAllowed {
            dispatchAllowed = false
            usecaseOutputStorageBuffer = usecaseOutputStorage
            usecaseOutputStorage = []
            for (index,storageItem) in usecaseOutputStorageBuffer.enumerated() {
                self.restManager.makeHTTPPostRequest(path: Constants.spanServicetUrl + Constants.submitResultUrl, body: storageItem) { response,i,j  in
                    //print(self.usecaseOutputStorageBuffer[index])
                    self.usecaseOutputStorageBuffer.remove(at: index)
                    self.dispatchAllowed = self.usecaseOutputStorageBuffer.count == 0
                }
            }
            clearStorage()
        }
    }
    
    /// Saves the measured metrics on hard drive
    func saveUsecasesInStorage() {
        if !usecaseOutputStorage.isEmpty {
            self.storageController.storeUsecases(storageData: usecaseOutputStorage)
        }
    }
    
    /// Loads previously measured metrics from hard drive
    private func loadUsecasesFromStorage() -> [String] {
        return self.storageController.loadUsecases()
    }
    
    /// Clears measurements storage
    func clearStorage() {
        return self.storageController.clearStorage()
    }
    
    /// Requests location tracking permission
    /// - Important: The UIViewContoller of the Agent object should not be nil otherwise you may not able to track the user location
    func requestLocationAuthorization() {
        self.asyncMetricsConrtoller.locationHandler.requestLocationAuthorization()
    }
    
    /// Loads the Agent ID whitch will be created once
    /// If not any stored than a new ID will be created
    func loadAgentId(){
        if let agentid = storageController.loadAgentId() {
            self.id = agentid
        } else {
            self.id = generateAgentId()
            self.storageController.storeAgentId(id: self.id)
        }
    }
    
    /// Loads the Host Url an the Span Service Url from the storage
    func loadConstantsFromStorage(){
        if let hostUrl = storageController.loadHostUrl() {
            Constants.HOST = hostUrl
        }
        if let monitorUrl = storageController.loadMonitorUrl() {
            Constants.spanServicetUrl = monitorUrl
        }
    }
    
    /// Generates an agent ID
    /// by adding 2 random 32-bit unsigned integers
    /// - returns: agent id
    func generateAgentId() -> UInt64 {
        // adding two 32bit integers is not ideal for returning a 64bit integer
        // since at least the upper 31bit are never used
        return Util.calculateUniqueId()
    }
    
}
