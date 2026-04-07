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

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
    methodChannel?.invokeMethod("onVoIPTokenUpdate", arguments: token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
    let userInfo = payload.dictionaryPayload
    print("📞 [iOS] Received VoIP Push: \(userInfo)")

    guard type == .voIP else {
      completion()
      return
    }

    // 📴 Handle Call Cancellation
    let dict = userInfo as? [String: AnyObject] ?? [:]
    let type = (dict["type"] as? String) ?? ""
    
    if (type == "cancel_call" || String(describing: dict["type"] ?? "" as AnyObject).contains("cancel_call")) {
        let uuid = (dict["id"] as? String) ?? (dict["uuid"] as? String) ?? ""
        print("📴 [iOS] VoIP Cancel Call received for UUID: \(uuid)")
        
        if (!uuid.isEmpty) {
            let cancelCallData = flutter_callkit_incoming.Data(
                id: uuid,
                nameCaller: "Call Cancelled",
                handle: "Call Cancelled",
                type: 0
            )
            SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endCall(cancelCallData)
        }
        
        // Always ensure all calls are ended for a 'cancel_call' type push
        SwiftFlutterCallkitIncomingPlugin.sharedInstance?.endAllCalls()
        
        completion()
        return
    }

    let id = (userInfo["id"] as? String)
      ?? (userInfo["uuid"] as? String)
      ?? UUID().uuidString
    let nameCaller = (userInfo["nameCaller"] as? String)
      ?? (userInfo["callerName"] as? String)
      ?? "Unknown"
    let handle = (userInfo["handle"] as? String)
      ?? "Docmobi Call"
    let isVideo = (userInfo["isVideo"] as? Bool)
      ?? ((userInfo["isVideo"] as? NSString)?.boolValue ?? false)

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    data.avatar = userInfo["callerAvatar"] as? String ?? ""
    data.extra = userInfo as NSDictionary

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushCredentialsFor type: PKPushType) {
    print("⚠️ [iOS] VoIP Token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    methodChannel?.invokeMethod("onVoIPTokenUpdate", arguments: "")
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
