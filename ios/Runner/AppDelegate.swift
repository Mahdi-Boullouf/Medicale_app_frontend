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

    // Fix: isVideo can arrive as Bool (NSNumber), String "true"/"false", or Int 1/0
    let isVideo: Bool = {
      if let b = userInfo["isVideo"] as? Bool { return b }
      if let n = userInfo["isVideo"] as? NSNumber { return n.boolValue }
      if let s = userInfo["isVideo"] as? String { return s == "true" || s == "1" }
      return false
    }()

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    data.avatar = userInfo["callerAvatar"] as? String ?? ""

    // Ensure ALL push payload keys are in extra so Dart can read chatId, callerId, etc.
    var extra = userInfo as? [String: Any] ?? [:]
    // Normalise key aliases so handleCallKitAction always finds them
    if extra["callerName"] == nil { extra["callerName"] = nameCaller }
    if extra["callerId"]   == nil { extra["callerId"]   = extra["fromUserId"] }
    if extra["uuid"]       == nil { extra["uuid"]       = id }
    data.extra = extra as NSDictionary

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(data, fromPushKit: true) {
      completion()
    }
  }


  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushCredentialsFor type: PKPushType) {
    print("⚠️ [iOS] VoIP Token invalidated")
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    methodChannel?.invokeMethod("onVoIPTokenUpdate", arguments: "")
  }
  
  override func application(_ application: UIApplication,
                           didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📩 [iOS] Background remote notification received: \(userInfo)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}
