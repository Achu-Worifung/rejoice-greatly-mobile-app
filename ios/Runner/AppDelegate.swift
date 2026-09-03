import Flutter
import UIKit
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// The host our NFC check-in links resolve through. Must stay in step with
  /// `NfcCheckinService.checkinLinkHost` on the Dart side (the URI record it
  /// writes onto tags) and with the `applinks:` entry in `Runner.entitlements`.
  private static let checkinLinkHost = "rejoice-greatly-admin.vercel.app"

  /// Path prefix of a check-in link: `/nfc-checkin/<tagId>`.
  private static let checkinLinkPathPrefix = "/nfc-checkin/"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // app_links forwards every universal link to Dart and then, by default
    // (`defaultUrlHandling == .never`), tells iOS the link was *not* handled so
    // other plugins still get a look at it. iOS's contract for an unhandled
    // `NSUserActivityTypeBrowsingWeb` activity is to open the URL in the default
    // browser — which is why an NFC tap used to check the member in *and* drop
    // them on the web page, whose "Open the app" button handed the link straight
    // back to us for another unhandled round: an endless app ⇄ browser loop.
    //
    // Claiming our own check-in links (and only those) ends the loop. Every
    // other URL still reports "not handled", so the Firebase / Google / Apple
    // sign-in callbacks keep the pass-through behaviour they rely on.
    //
    // This hook (and app_links' UIScene support, which the `SceneDelegate` this
    // app runs on needs) landed in app_links 7 — see `pubspec.yaml`.
    AppLinks.shared.urlHandledCallBack = { url in
      AppDelegate.isCheckinLink(url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// Whether `url` is one of our `/nfc-checkin/<tagId>` links — i.e. a link
  /// `NfcDeepLinkService` will act on, so iOS must not also open it in Safari.
  private static func isCheckinLink(_ url: URL) -> Bool {
    guard let host = url.host?.lowercased(), host == checkinLinkHost else {
      return false
    }
    return url.path.hasPrefix(checkinLinkPathPrefix)
      && url.path.count > checkinLinkPathPrefix.count
  }
}
