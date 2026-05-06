import Flutter
import UIKit
import ViaLinkCore

public class ViaLinkFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    static let wrapperVersion = "2.1.0"

    private var deepLinkSink: FlutterEventSink?
    private var deferredHandler = DeferredStreamHandler()
    private var pendingDeepLink: [String: Any?]?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ViaLinkFlutterPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "com.vialink.sdk/methods",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)

        let deepLinkChannel = FlutterEventChannel(
            name: "com.vialink.sdk/deeplinks",
            binaryMessenger: registrar.messenger()
        )
        deepLinkChannel.setStreamHandler(instance)

        let deferredChannel = FlutterEventChannel(
            name: "com.vialink.sdk/deferred",
            binaryMessenger: registrar.messenger()
        )
        deferredChannel.setStreamHandler(instance.deferredHandler)

        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "configure":
            guard let apiKey = args?["apiKey"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "apiKey 필요", details: nil))
                return
            }
            ViaLinkSDK.shared.setWrapper("flutter/\(Self.wrapperVersion)")
            ViaLinkSDK.shared.configure(apiKey: apiKey)

            ViaLinkSDK.shared.onDeepLink { [weak self] data in
                let map = data.toFlutterMap()
                if let sink = self?.deepLinkSink {
                    sink(map)
                } else {
                    self?.pendingDeepLink = map
                }
            }
            // 디퍼드 콜백: SDK 3.0+ 시그니처 (data, error) — 항상 1회 호출
            // EventChannel 페이로드는 Dart 측이 ["data", "error"] 키로 파싱한다.
            ViaLinkSDK.shared.onDeferredDeepLink { [weak self] data, error in
                let payload: [String: Any?] = [
                    "data": data?.toFlutterMap() as Any?,
                    "error": error?.toFlutterMap() as Any?,
                ]
                if let sink = self?.deferredHandler.sink {
                    sink(payload)
                } else {
                    self?.deferredHandler.pending = payload
                }
            }
            result(nil)

        case "track":
            guard let eventName = args?["eventName"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "eventName 필요", details: nil))
                return
            }
            let data = args?["data"] as? [String: String]
            ViaLinkSDK.shared.track(eventName, data: data)
            result(nil)

        case "createLink":
            guard let path = args?["path"] as? String else {
                result(FlutterError(code: "INVALID_ARG", message: "path 필요", details: nil))
                return
            }
            let data = args?["data"] as? [String: String]
            let campaign = args?["campaign"] as? String
            // linkType: "static"(기본) 또는 "dynamic"
            let linkType = args?["linkType"] as? String ?? "static"
            // 폴백 URL/OG/채널/태그 등 부가 옵션 (선택)
            let iosUrl = args?["iosUrl"] as? String
            let androidUrl = args?["androidUrl"] as? String
            let webUrl = args?["webUrl"] as? String
            let ogTitle = args?["ogTitle"] as? String
            let ogDescription = args?["ogDescription"] as? String
            let ogImageUrl = args?["ogImageUrl"] as? String
            let channel = args?["channel"] as? String
            let feature = args?["feature"] as? String
            let tags = args?["tags"] as? [String]
            let expiresAt = args?["expiresAt"] as? String
            Task {
                do {
                    let url = try await ViaLinkSDK.shared.createLink(
                        path: path,
                        data: data,
                        campaign: campaign,
                        linkType: linkType,
                        iosUrl: iosUrl,
                        androidUrl: androidUrl,
                        webUrl: webUrl,
                        ogTitle: ogTitle,
                        ogDescription: ogDescription,
                        ogImageUrl: ogImageUrl,
                        channel: channel,
                        feature: feature,
                        tags: tags,
                        expiresAt: expiresAt
                    )
                    DispatchQueue.main.async { result(url) }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "CREATE_LINK_ERROR", message: error.localizedDescription, details: nil))
                    }
                }
            }

        case "paymentInitiated":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "E_INVALID_ARG", message: "arguments가 필요합니다.", details: nil))
                return
            }
            guard let orderId = args["orderId"] as? String,
                  let amount = (args["amount"] as? NSNumber)?.doubleValue,
                  let currency = args["currency"] as? String else {
                result(FlutterError(code: "E_INVALID_ARG", message: "orderId/amount/currency가 필요합니다.", details: nil))
                return
            }
            let linkId = (args["linkId"] as? NSNumber)?.intValue
            let paymentMethod = args["paymentMethod"] as? String
            let metadata = args["metadata"] as? [String: String]

            let payArgs = PaymentInitiatedArgs(
                orderId: orderId,
                amount: amount,
                currency: currency,
                linkId: linkId,
                paymentMethod: paymentMethod,
                metadata: metadata
            )

            Task {
                do {
                    let res = try await ViaLinkSDK.shared.payment.initiated(payArgs)
                    DispatchQueue.main.async {
                        result(["success": res.success, "paymentEventId": res.paymentEventId])
                    }
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "E_PAYMENT_FAILED",
                                            message: error.localizedDescription,
                                            details: nil))
                    }
                }
            }

        case "dispose":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler (deeplinks)
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        deepLinkSink = events
        if let pending = pendingDeepLink {
            events(pending)
            pendingDeepLink = nil
        }
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        deepLinkSink = nil
        return nil
    }

    // MARK: - Universal Link + URL Scheme 자동 수신
    public func application(_ application: UIApplication,
                            continue userActivity: NSUserActivity,
                            restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return ViaLinkSDK.shared.handleUniversalLink(userActivity)
    }

    public func application(_ app: UIApplication,
                            open url: URL,
                            options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return ViaLinkSDK.shared.handleURL(url)
    }
}

// 디퍼드 전용 StreamHandler
private class DeferredStreamHandler: NSObject, FlutterStreamHandler {
    var sink: FlutterEventSink?
    var pending: [String: Any?]?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        if let pending = pending {
            events(pending)
            self.pending = nil
        }
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}

// DeepLinkData → Flutter Map (linkId는 어트리뷰션 fallback용)
private extension DeepLinkData {
    func toFlutterMap() -> [String: Any?] {
        return ["path": path, "params": params, "shortCode": shortCode, "linkId": linkId as Any?]
    }
}

// DeferredError → Flutter Map (Dart DeferredError.fromMap과 키가 일치해야 함)
private extension DeferredError {
    func toFlutterMap() -> [String: Any?] {
        return [
            "code": code.rawValue,
            "message": message,
            "httpStatus": httpStatus as Any?,
            "retryable": retryable,
        ]
    }
}
