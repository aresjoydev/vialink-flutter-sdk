import Flutter
import UIKit
import ViaLinkCore

/// ViaLink Flutter Plugin — iOS 네이티브 브릿지
///
/// Pigeon 생성 ViaLinkHostApi 프로토콜을 구현하여 네이티브 ViaLinkSDK를 호출합니다.
/// Universal Link / URL Scheme을 자동 감지하여 딥링크를 처리합니다.
public class ViaLinkFlutterPlugin: NSObject, FlutterPlugin, ViaLinkHostApi {

    private static let wrapperVersion = "2.0.0"

    private var flutterApi: ViaLinkFlutterApi?

    // MARK: - FlutterPlugin

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ViaLinkFlutterPlugin()
        instance.flutterApi = ViaLinkFlutterApi(binaryMessenger: registrar.messenger())
        ViaLinkHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)

        // Universal Link / URL Scheme 자동 처리
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - ViaLinkHostApi (Pigeon)

    func configure(apiKey: String) throws {
        ViaLinkSDK.shared.setWrapperInternal("flutter/\(Self.wrapperVersion)")
        ViaLinkSDK.shared.configure(apiKey: apiKey)

        // 네이티브 콜백 → Flutter 이벤트
        ViaLinkSDK.shared.onDeepLink { [weak self] data in
            self?.flutterApi?.onDeepLink(data: data.toPigeon()) { _ in }
        }

        ViaLinkSDK.shared.onDeferredDeepLink { [weak self] data, error in
            self?.flutterApi?.onDeferredDeepLink(
                data: data?.toPigeon(),
                error: error?.localizedDescription
            ) { _ in }
        }
    }

    func handleDeepLink(url: String) throws {
        guard let nsUrl = URL(string: url) else { return }
        ViaLinkSDK.shared.handleURL(nsUrl)
    }

    func track(eventName: String, data: [String? : String?]?) throws {
        let cleanData = data?.compactMap { key, value -> (String, String)? in
            guard let k = key, let v = value else { return nil }
            return (k, v)
        }.reduce(into: [String: String]()) { $0[$1.0] = $1.1 }

        ViaLinkSDK.shared.track(eventName, data: cleanData)
    }

    func getDeepLinkData() throws -> VLDeepLinkData? {
        return ViaLinkSDK.shared.getDeepLinkData()?.toPigeon()
    }

    func getDeferredLinkData() throws -> VLDeepLinkData? {
        return ViaLinkSDK.shared.getDeferredLinkData()?.toPigeon()
    }

    func awaitDeepLinkData(completion: @escaping (Result<VLDeepLinkData?, any Error>) -> Void) {
        Task {
            do {
                let data = try await ViaLinkSDK.shared.awaitDeepLinkData()
                completion(.success(data?.toPigeon()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func awaitDeferredLinkData(completion: @escaping (Result<VLDeepLinkData?, any Error>) -> Void) {
        Task {
            do {
                let data = try await ViaLinkSDK.shared.awaitDeferredLinkData()
                completion(.success(data?.toPigeon()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func createLink(args: VLCreateLinkArgs, completion: @escaping (Result<String, any Error>) -> Void) {
        Task {
            do {
                let cleanData = args.data?.compactMap { key, value -> (String, String)? in
                    guard let k = key, let v = value else { return nil }
                    return (k, v)
                }.reduce(into: [String: String]()) { $0[$1.0] = $1.1 }

                let tagsList = args.tags?.compactMap { $0 }

                let url = try await ViaLinkSDK.shared.createLink(
                    path: args.path,
                    data: cleanData,
                    campaign: args.campaign,
                    linkType: args.linkType,
                    iosUrl: args.iosUrl,
                    androidUrl: args.androidUrl,
                    webUrl: args.webUrl,
                    ogTitle: args.ogTitle,
                    ogDescription: args.ogDescription,
                    ogImageUrl: args.ogImageUrl,
                    channel: args.channel,
                    feature: args.feature,
                    tags: tagsList,
                    expiresAt: args.expiresAt
                )
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func trackPayment(args: VLPaymentArgs, completion: @escaping (Result<VLPaymentResult, any Error>) -> Void) {
        Task {
            do {
                let metadataMap = args.metadata?.compactMap { key, value -> (String, String)? in
                    guard let k = key, let v = value else { return nil }
                    return (k, v)
                }.reduce(into: [String: String]()) { $0[$1.0] = $1.1 }

                let payArgs = PaymentInitiatedArgs(
                    orderId: args.orderId,
                    amount: args.amount,
                    currency: args.currency,
                    linkId: args.linkId.map { Int($0) },
                    paymentMethod: args.paymentMethod,
                    metadata: metadataMap
                )
                let result = try await ViaLinkSDK.shared.payment.initiated(payArgs)
                completion(.success(VLPaymentResult(
                    success: result.success,
                    paymentEventId: result.paymentEventId
                )))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Universal Link 자동 처리

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        return ViaLinkSDK.shared.handleUniversalLink(userActivity)
    }

    public func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return ViaLinkSDK.shared.handleURL(url)
    }
}

// MARK: - DeepLinkData → Pigeon 변환

private extension DeepLinkData {
    func toPigeon() -> VLDeepLinkData {
        return VLDeepLinkData(
            path: path,
            params: params,
            shortCode: shortCode,
            linkId: linkId.map { Int64($0) }
        )
    }
}
