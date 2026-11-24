import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let notificationChannelName = "com.example.loyallig_flutter/notification_permissions"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NotificationPermissionsChannel"
    ) {
      let channel = FlutterMethodChannel(
        name: notificationChannelName,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleNotificationMethod(call: call, result: result)
      }
    }
  }

  private func handleNotificationMethod(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "checkStatus":
      checkNotificationPermissionStatus(result: result)
    case "requestPermission":
      requestNotificationPermission(result: result)
    case "openNotificationSettings":
      openAppNotificationSettings(result: result)
    case "setBadgeCount":
      let count = (call.arguments as? [String: Any])?["count"] as? Int ?? 0
      setAppBadgeCount(count, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setAppBadgeCount(_ count: Int, result: @escaping FlutterResult) {
    let safeCount = count < 0 ? 0 : count
    DispatchQueue.main.async {
      if #available(iOS 16.0, *) {
        UNUserNotificationCenter.current().setBadgeCount(safeCount) { error in
          DispatchQueue.main.async {
            result(error == nil)
          }
        }
      } else {
        UIApplication.shared.applicationIconBadgeNumber = safeCount
        result(true)
      }
    }
  }

  private func checkNotificationPermissionStatus(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        result(self.mapSettings(settings))
      }
    }
  }

  private func requestNotificationPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        var payload = self.mapSettings(settings)
        if granted && (payload["granted"] as? Bool) != true {
          payload["granted"] = true
          payload["status"] = "granted"
        }
        DispatchQueue.main.async {
          result(payload)
        }
      }
    }
  }

  private func mapSettings(_ settings: UNNotificationSettings) -> [String: Any] {
    let status: String
    let isGranted: Bool

    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      status = "granted"
      isGranted = true
    case .notDetermined:
      status = "notDetermined"
      isGranted = false
    case .denied:
      status = "permanentlyDenied"
      isGranted = false
    @unknown default:
      status = "permanentlyDenied"
      isGranted = false
    }

    return [
      "granted": isGranted,
      "status": status,
    ]
  }

  private func openAppNotificationSettings(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let urlString: String
      if #available(iOS 16.0, *) {
        urlString = UIApplication.openNotificationSettingsURLString
      } else {
        urlString = UIApplication.openSettingsURLString
      }

      guard let url = URL(string: urlString) else {
        result(false)
        return
      }

      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }
}
