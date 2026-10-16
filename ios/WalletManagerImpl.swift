//
//  WalletManager.swift
//  WalletManager
//
//  Created by Евгений Сецко on 3.12.25.
//  Copyright © 2025 Facebook. All rights reserved.
//

import PassKit

@objc(WalletManagerImpl)
public class WalletManagerImpl: NSObject, @preconcurrency PKAddPassesViewControllerDelegate {
  private var passes: [PKPass] = []
  private var passLibrary: PKPassLibrary?
  private var completion: ((Bool, String?, String?) -> Void)?
  private var isLoading = false
  // Weak: a controller that UIKit refused to present is released and stops
  // blocking new requests.
  private weak var presentedController: PKAddPassesViewController?
  private var presentedAt = Date.distantPast

  private static let urlCharacters = CharacterSet(
    charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%"
  )

  // MARK: - canAddPasses

  @MainActor @objc
  public func canAddPasses() -> Bool {
    return PKAddPassesViewController.canAddPasses()
  }

  // MARK: - Show from file

  @MainActor @objc
  public func showAddPassControllerFromFile(_ filepath: String) -> Bool {
    guard beginAddPass() else {
      print("wallet", "Another pass is already being added")
      return false
    }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filepath)) else {
      print("File not found or empty")
      return false
    }
    self.showViewController(with: data)
    return true
  }

  // MARK: - addPassFromUrl

  @MainActor @objc(addPassFromUrl:headers:completion:)
  public func addPassFromUrl(_ passUrlString: String,
                             headers: [String: String]?,
                             completion: @escaping (Bool, String?, String?) -> Void
  ) {
    guard let url = Self.makeURL(passUrlString) else {
      completion(false, "INVALID_URL", "The pass URL is invalid")
      return
    }
    guard beginAddPass() else {
      completion(false, "ADD_PASS_IN_PROGRESS", "Another pass is already being added")
      return
    }
    self.completion = completion
    self.isLoading = true

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // Add custom headers (for authentication)
    if let headers = headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.isLoading = false

        if let error = error {
          self.addPassCompletion(false, "NETWORK_ERROR", error.localizedDescription)
          return
        }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
          self.addPassCompletion(false, "HTTP_ERROR", "HTTP \(httpResponse.statusCode)")
          return
        }

        guard let data = data else {
          self.addPassCompletion(false, "INVALID_DATA", "No data received")
          return
        }

        self.showViewController(with: data)
      }
    }.resume()
  }

  // MARK: - hasPass

  @objc
  public func hasPass(_ identifier: String,
               serialNumber: String?) -> Bool {
    let passLibrary = PKPassLibrary()
    print("passes count", passLibrary.passes().count)
    for pass in passLibrary.passes() {
      print(String(describing: identifier), String(describing: serialNumber))
      if self.checkPass(pass, identifier: identifier, serialNumber: serialNumber) {
        return true
      }
    }
    return false
  }

  // MARK: - removePass

  @objc
  public func removePass(_ identifier: String,
                  serialNumber: String?) -> Bool {
    let library = PKPassLibrary()
    for pass in library.passes() {
      if self.checkPass(pass, identifier: identifier, serialNumber: serialNumber) {
        library.removePass(pass)
        return true
      }
    }
    return false
  }

  // MARK: - viewInWallet

  @MainActor @objc
  public func viewInWallet(_ identifier: String,
                    serialNumber: String?
  ) -> Bool {
    let library = PKPassLibrary()
    for pass in library.passes() {
      if self.checkPass(pass, identifier: identifier, serialNumber: serialNumber) {
        if let url = pass.passURL {
          if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
          } else {
            print("wallet", "Unsupported platform")
          }
        }
        return true
      }
    }
    return false
  }

  // MARK: - Show controller

  @MainActor private func showViewController(with data: Data) {
    let parsedPasses = Self.parsePasses(from: data)
    guard !parsedPasses.isEmpty else {
      addPassCompletion(false, "INVALID_PASS", "Failed to parse pass data")
      return
    }

    let library = PKPassLibrary()
    let missingPasses = parsedPasses.filter { !library.containsPass($0) }
    guard !missingPasses.isEmpty else {
      addPassCompletion(false, "PASS_ALREADY_EXISTS", "This pass is already in your wallet")
      return
    }

    guard let windowScene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else {
      addPassCompletion(false, "NO_VIEW_CONTROLLER", "No root view controller found")
      return
    }

    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }

    let controller = missingPasses.count == 1
      ? PKAddPassesViewController(pass: missingPasses[0])
      : PKAddPassesViewController(passes: missingPasses)
    guard let controller = controller else {
      addPassCompletion(false, "CONTROLLER_ERROR", "Failed to create pass controller")
      return
    }
    controller.delegate = self

    self.passes = missingPasses
    self.passLibrary = library
    self.presentedController = controller
    self.presentedAt = Date()
    top.present(controller, animated: true)
  }

  // MARK: - Delegate

  @MainActor public func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
    controller.dismiss(animated: true) { [weak self] in
      guard let self = self else { return }
      let passes = self.passes
      let library = self.passLibrary
      self.passes = []
      self.passLibrary = nil
      self.presentedController = nil
      controller.delegate = nil

      guard let library = library, !passes.isEmpty else { return }
      if passes.contains(where: { library.containsPass($0) }) {
        self.addPassCompletion(true, nil, nil)
      } else {
        self.addPassCompletion(false, "USER_CANCELLED", "User cancelled or declined to add pass")
      }
    }
  }

  // MARK: - Helper

  // One request at a time: a second sheet cannot be presented over the first,
  // and a second request would replace the pending completion.
  @MainActor private func beginAddPass() -> Bool {
    if isLoading {
      return false
    }
    if let controller = presentedController,
       controller.presentingViewController != nil || Date().timeIntervalSince(presentedAt) < 5 {
      return false
    }
    // The previous sheet never appeared, so its promise is still pending.
    if completion != nil {
      addPassCompletion(false, "CONTROLLER_ERROR", "Failed to present pass controller")
    }
    passes = []
    passLibrary = nil
    presentedController = nil
    return true
  }

  // URL(string:) percent-encodes invalid characters since iOS 17 and returns nil
  // on earlier versions. Encode them everywhere, and require a scheme.
  private static func makeURL(_ string: String) -> URL? {
    let url = URL(string: string)
      ?? string.addingPercentEncoding(withAllowedCharacters: urlCharacters).flatMap { URL(string: $0) }
    guard let url = url, url.scheme != nil else { return nil }
    return url
  }

  // Accepts a single .pkpass or a .pkpasses bundle of them.
  private static func parsePasses(from data: Data) -> [PKPass] {
    if let pass = try? PKPass(data: data) {
      return [pass]
    }

    var passes: [PKPass] = []
    var seen = Set<String>()
    for (index, entry) in PassesBundle.extractPassEntries(from: data).enumerated() {
      do {
        let pass = try PKPass(data: entry)
        if seen.insert(pass.passTypeIdentifier + "\n" + pass.serialNumber).inserted {
          passes.append(pass)
        }
      } catch {
        print("wallet", "Failed to parse pass \(index) in bundle:", error.localizedDescription)
      }
    }
    return passes
  }

  private func addPassCompletion(_ success: Bool, _ errorCode: String?, _ errorMessage: String?) {
    self.completion?(success, errorCode, errorMessage)
    self.completion = nil
  }

  private func checkPass(_ pass: PKPass,
                         identifier: String,
                         serialNumber: String?) -> Bool {

    guard pass.passTypeIdentifier == identifier else { return false }

    if let sn = serialNumber {
      return pass.serialNumber == sn
    }

    return true
  }
}
