import Flutter
import UIKit

private let channelName = "appstat_sdk"
private let nativeCrashMethod = "nativeCrash"

private var forwardedChannel: FlutterMethodChannel?
private var previousExceptionHandler: (@convention(c) (NSException) -> Void)?

private func appstatUncaughtExceptionHandler(_ exception: NSException) {
    let payload: [String: String] = [
        "type": "ios-nsException",
        "exception": "\(exception.name.rawValue): \(exception.reason ?? "unknown")",
        "stack": exception.callStackSymbols.joined(separator: "\n"),
    ]
    forwardedChannel?.invokeMethod(nativeCrashMethod, arguments: payload)
    previousExceptionHandler?(exception)
}

public class AppstatSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        forwardedChannel = channel
        previousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler(appstatUncaughtExceptionHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }
}
