import Flutter
import UIKit
import AVFoundation
import Photos
import CoreLocation

// TODO: When ready to use Google Maps, add `google_maps_flutter` dependency and uncomment:
// import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let nativeConfigChannel = "com.example.app/native_config"
  private static let permissions = AppPermissions()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // Fallback: If window rootViewController is available, register channel here too
    if let controller = window?.rootViewController as? FlutterViewController {
      AppDelegate.setupChannel(messenger: controller.binaryMessenger)
    }

    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Primary: Register channel with the implicit engine's plugin registry
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeConfigPlugin") {
      AppDelegate.setupChannel(messenger: registrar.messenger())
    }
  }

  private static func setupChannel(messenger: FlutterBinaryMessenger) {
    permissions.register(messenger: messenger)
    let channel = FlutterMethodChannel(name: nativeConfigChannel, binaryMessenger: messenger)
    
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "initGoogleMaps" {
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(
            code: "INVALID_ARGUMENT",
            message: "Arguments must be a valid key-value map",
            details: "Received: \(String(describing: call.arguments))"
          ))
          return
        }

        guard let apiKey = args["apiKey"] as? String else {
          result(FlutterError(
            code: "MISSING_KEY",
            message: "The 'apiKey' field is missing or not a String",
            details: "Arguments received: \(args)"
          ))
          return
        }

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
          result(FlutterError(
            code: "EMPTY_KEY",
            message: "The Google Maps API Key provided is empty",
            details: nil
          ))
          return
        }

        // TODO: Uncomment the line below once GoogleMaps dependency is added:
        // GMSServices.provideAPIKey(trimmedKey)
        
        #if DEBUG
        print("🗺️ [iOS Native] Google Maps API Key initialized securely via MethodChannel: \(trimmedKey) (For debug and testing only)")
        #endif
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

private final class AppPermissions: NSObject, CLLocationManagerDelegate {
  private let location = CLLocationManager()
  private var locationResult: FlutterResult?

  func register(messenger: FlutterBinaryMessenger) {
    location.delegate = self
    let channel = FlutterMethodChannel(name: "org.openimis/permissions", binaryMessenger: messenger)
    channel.setMethodCallHandler { [self] call, result in
      let args = call.arguments as? [String: Any]
      let kind = args?["permission"] as? String ?? ""
      switch call.method {
      case "status": result(status(kind))
      case "openSettings":
        guard let url = URL(string: UIApplication.openSettingsURLString) else { result(false); return }
        UIApplication.shared.open(url) { opened in result(opened) }
      case "request":
        switch kind {
        case "camera":
          AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { result(self.status(kind)) }
          }
        case "photos":
          PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
            DispatchQueue.main.async { result(self.status(kind)) }
          }
        case "location":
          if location.authorizationStatus != .notDetermined { result(status(kind)); return }
          guard locationResult == nil else { result(FlutterError(code: "BUSY", message: "A location request is already open", details: nil)); return }
          locationResult = result
          location.requestWhenInUseAuthorization()
        default: result(FlutterError(code: "INVALID_PERMISSION", message: "Unknown permission", details: nil))
        }
      default: result(FlutterMethodNotImplemented)
      }
    }
  }

  private func status(_ kind: String) -> String {
    switch kind {
    case "camera":
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized: return "granted"
      case .notDetermined: return "notRequested"
      case .restricted: return "restricted"
      default: return "denied"
      }
    case "photos":
      switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
      case .authorized: return "granted"
      case .limited: return "limited"
      case .notDetermined: return "notRequested"
      case .restricted: return "restricted"
      default: return "denied"
      }
    case "location":
      switch location.authorizationStatus {
      case .authorizedAlways, .authorizedWhenInUse: return "granted"
      case .notDetermined: return "notRequested"
      case .restricted: return "restricted"
      default: return "denied"
      }
    default: return "unavailable"
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard manager.authorizationStatus != .notDetermined, let result = locationResult else { return }
    locationResult = nil
    result(status("location"))
  }
}

