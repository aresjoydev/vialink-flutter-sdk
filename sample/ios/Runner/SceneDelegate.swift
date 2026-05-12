import Flutter
import UIKit
import ViaLinkCore

/// iOS 13+ Scene 기반 앱은 Universal Link 가 AppDelegate 의 `application(_:continue:)`
/// 가 아니라 SceneDelegate 의 `scene(_:continue:)` 로 들어온다. Flutter plugin 의
/// `addApplicationDelegate` 등록은 scene 콜백을 받지 못하므로, SceneDelegate 에서
/// ViaLinkSDK 를 직접 호출해야 한다.
class SceneDelegate: FlutterSceneDelegate {

    /// Cold start — Universal Link / URL Scheme 으로 앱이 처음 띄워진 경우.
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        for activity in connectionOptions.userActivities
            where activity.activityType == NSUserActivityTypeBrowsingWeb {
            NSLog("[ViaLink] willConnectTo userActivity: \(activity.webpageURL?.absoluteString ?? "-")")
            _ = ViaLinkSDK.shared.handleUniversalLink(activity)
        }

        for context in connectionOptions.urlContexts {
            NSLog("[ViaLink] willConnectTo urlContext: \(context.url.absoluteString)")
            _ = ViaLinkSDK.shared.handleURL(context.url)
        }
    }

    /// 앱이 백그라운드에 있다가 Universal Link 로 재진입한 경우.
    override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        NSLog("[ViaLink] scene continue: \(userActivity.webpageURL?.absoluteString ?? "-")")
        _ = ViaLinkSDK.shared.handleUniversalLink(userActivity)
        super.scene(scene, continue: userActivity)
    }

    /// 앱이 백그라운드에 있다가 Custom URL Scheme 로 재진입한 경우.
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            NSLog("[ViaLink] scene openURL: \(context.url.absoluteString)")
            _ = ViaLinkSDK.shared.handleURL(context.url)
        }
        super.scene(scene, openURLContexts: URLContexts)
    }
}
