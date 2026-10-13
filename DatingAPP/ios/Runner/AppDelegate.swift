import Flutter
import UIKit
import FaceTecSDK

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "just2/facetec",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "startLiveness" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let presenter = self.window?.rootViewController else {
        result(FlutterError(code: "NO_PRESENTER", message: "Could not find the Flutter view controller.", details: nil))
        return
      }
      Just2FaceTecBridge.shared.start(from: presenter, result: result)
    }
  }
}

private final class Just2FaceTecBridge: NSObject, FaceTecInitializeCallback, FaceTecSessionRequestProcessor {
  static let shared = Just2FaceTecBridge()

  private let deviceKeyIdentifier = "dRbnBk7c4UYUsDSYRoe3xbSLOk3C3W2m"
  private let testingApiEndpoint = URL(string: "https://api.facetec.com/api/v4/biometrics/process-request")!
  private var sdkInstance: FaceTecSDKInstance?
  private var pendingResult: FlutterResult?
  private weak var presentingViewController: UIViewController?

  func start(from viewController: UIViewController, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "SESSION_ACTIVE", message: "A FaceTec session is already active.", details: nil))
      return
    }
    pendingResult = result
    presentingViewController = viewController

    if let sdkInstance {
      presentLiveness(using: sdkInstance)
    } else {
      FaceTec.sdk.initializeWithSessionRequest(
        deviceKeyIdentifier: deviceKeyIdentifier,
        sessionRequestProcessor: self,
        completion: self
      )
    }
  }

  func onFaceTecSDKInitializeSuccess(sdkInstance: FaceTecSDKInstance) {
    self.sdkInstance = sdkInstance
    presentLiveness(using: sdkInstance)
  }

  func onFaceTecSDKInitializeError(error: FaceTecInitializationError) {
    finish(error: FlutterError(code: "FACETEC_INIT", message: "FaceTec initialization failed: \(error)", details: nil))
  }

  private func presentLiveness(using sdkInstance: FaceTecSDKInstance) {
    guard let presenter = presentingViewController else {
      finish(error: FlutterError(code: "NO_PRESENTER", message: "Could not open FaceTec from this screen.", details: nil))
      return
    }
    let faceTecController = sdkInstance.start3DLiveness(with: self)
    presenter.present(faceTecController, animated: true)
  }

  func onSessionRequest(sessionRequestBlob: String, sessionRequestCallback: FaceTecSessionRequestProcessorCallback) {
    var request = URLRequest(url: testingApiEndpoint)
    request.httpMethod = "POST"
    request.timeoutInterval = 120
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(deviceKeyIdentifier, forHTTPHeaderField: "X-Device-Key")
    request.setValue(FaceTec.sdk.getTestingAPIHeader(), forHTTPHeaderField: "X-Testing-API-Header")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["requestBlob": sessionRequestBlob])

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self else { return }
      guard error == nil,
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode),
            let data,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let responseBlob = json["responseBlob"] as? String,
            !responseBlob.isEmpty else {
        DispatchQueue.main.async {
          sessionRequestCallback.abortOnCatastrophicError()
          self.finish(error: FlutterError(code: "FACETEC_REQUEST", message: "FaceTec test request failed. Check network and test account setup.", details: nil))
        }
        return
      }
      DispatchQueue.main.async {
        sessionRequestCallback.processResponse(responseBlob)
      }
    }.resume()
  }

  func onFaceTecExit(sessionResult: FaceTecSessionResult) {
    let completed = sessionResult.sessionStatus == .sessionCompleted
    DispatchQueue.main.async {
      self.finish(value: completed)
    }
  }

  private func finish(value: Any? = nil, error: FlutterError? = nil) {
    guard let result = pendingResult else { return }
    pendingResult = nil
    presentingViewController = nil
    if let error {
      result(error)
    } else {
      result(value)
    }
  }
}
