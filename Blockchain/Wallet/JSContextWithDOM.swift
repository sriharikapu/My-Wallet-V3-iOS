//
//  JSContextWithDOM.swift
//  Blockchain
//
//  Created by kevinwu on 4/27/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import JavaScriptCore

class JSContextWithDOM: JSContext {

    override init() {
        super.init()

        setupConsoleFunctions()

        setupExceptionHandler()

        setupSetTimeout()
        setupClearTimeout()

        setupSetInterval()
        setupClearInterval()

        setObject(ModuleXMLHttpRequest.self, forKeyedSubscript: "XMLHttpRequest" as NSString)
    }

    func setupConsoleFunctions() {
        let consoleNames = ["log",
                            "debug",
                            "info",
                            "warn",
                            "error",
                            "assert",
                            "dir",
                            "dirxml",
                            "group",
                            "groupEnd",
                            "time",
                            "timeEnd",
                            "count",
                            "trace",
                            "profile",
                            "profileEnd"]

        consoleNames.forEach { name in
            let consoleLog: (String) -> Void = { message in
                print("Javascript \(name): \(message)")
            }
            self.objectForKeyedSubscript("console").setObject(consoleLog, forKeyedSubscript: name as NSString)
        }
    }

    func setupExceptionHandler() {
        let exceptionHandler: (JSContext?, JSValue?) -> Void = { context, exception in
            guard let exception = exception else {
                print("Exception handler error: could not get exception")
                return
            }
            guard let message = exception.toString() else {
                print("Exception handler error: could not get message")
                return
            }
            guard let stackTrace = exception.objectForKeyedSubscript("stack").toString() else {
                print("Exception handler error: could not get stack trace")
                return
            }
            guard let lineNumber = exception.objectForKeyedSubscript("line").toString() else {
                print("Exception handler error: could not get line number")
                return
            }
            print("\(message) \nstack: \(stackTrace)\nline number: \(lineNumber)")
        }
        self.exceptionHandler = exceptionHandler
    }

    var timers = [String: Timer]()

    lazy var removeTimer: (String) -> Void = { [unowned self] identifier in
        if let timer = self.timers[identifier] {
            timer.invalidate()
            self.timers.removeValue(forKey: identifier)
        }
    }

    func getAddTimer(repeats: Bool) -> (JSValue?, Double) -> String {
        return { [unowned self] callback, timeout in
            let uuid = NSUUID().uuidString
            let blockOperation = BlockOperation.init(block: {
                DispatchQueue.main.async {
                    if self.timers[uuid] != nil {
                        _ = callback?.call(withArguments: nil)
                    }
                }
            })
            let timer = Timer.scheduledTimer(timeInterval: timeout/1000,
                                             target: blockOperation,
                                             selector: #selector(BlockOperation.main),
                                             userInfo: nil,
                                             repeats: repeats)
            self.timers[uuid] = timer
            timer.fire()
            return uuid
        }
    }

    func setupSetTimeout() {
        self.setObject(getAddTimer(repeats: false), forKeyedSubscript: "setTimeout" as NSString)
    }

    func setupClearTimeout() {
        self.setObject(removeTimer, forKeyedSubscript: "clearTimeout" as NSString)
    }

    func setupSetInterval() {
        self.setObject(getAddTimer(repeats: true), forKeyedSubscript: "setInterval" as NSString)
    }

    func setupClearInterval() {
        self.setObject(removeTimer, forKeyedSubscript: "clearInterval" as NSString)
    }
}
