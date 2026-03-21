import UIKit
import Flutter
import GoogleMaps
import PushKit
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  
  private var voipRegistry: PKPushRegistry?
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "com.docmobi.app/voip",
                                              binaryMessenger: controller.binaryMessenger)
    
    // Initialize Google Maps
    GMSServices.provideAPIKey("AIzaSyDwpV4RKu-t9aThomHv7SPcbY0uAj80dek")
    
    GeneratedPluginRegistrant.register(with: self)
    
    // 📞 Setup VoIP push registration
    self.setupVoIPPush()
    
    // Register for remote notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
      
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }
    
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setupVoIPPush() {
    self.voipRegistry = PKPushRegistry(queue: .main)
    self.voipRegistry?.delegate = self
    self.voipRegistry?.desiredPushTypes = [.voIP]
  }

  // MARK: - PKPushRegistryDelegate

  func pushRegistry(_ registry: PKPushRegistry, didUpdate PushCredentials: PKPushCredentials, for type: PKPushType) {
    let token = PushCredentials.token.map { String(format: "%02.2hhx", $0) }.joined()
    print("✅ [iOS] VoIP Token: \(token)")
    
    // Send token to Flutter
    methodChannel?.invokeMethod("onVoIPTokenUpdate", arguments: token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let userInfo = payload.dictionaryPayload
    print("📞 [iOS] Received VoIP Push: \(userInfo)")
    
    // 🚀 CRITICAL: Report call to CallKit immediately
    // flutter_callkit_incoming plugin provides a way to show call through its dedicated native API
    
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(userInfo)
    
    completion()
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushCredentialsFor type: PKPushType) {
    print("⚠️ [iOS] VoIP Token invalidated")
  }
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📩 [iOS] Foreground notification received: \(userInfo)")
    
    // Show notification even when app is in foreground
    if #available(iOS 14.0, *) {
      completionHandler([[.banner, .sound, .badge]])
    } else {
      completionHandler([[.alert, .sound, .badge]])
    }
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("🔔 [iOS] Notification tapped: \(userInfo)")
    
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
}