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
  private var pass: PKPass?
  private var passLibrary: PKPassLibrary?
  private var completion: ((Bool, String?, String?) -> Void)?

  // MARK: - canAddPasses

  @MainActor @objc
  public func canAddPasses() -> Bool {
    return PKAddPassesViewController.canAddPasses()
  }

  // MARK: - Show from file

  @MainActor @objc
  public func showAddPassControllerFromFile(_ filepath: String) -> Bool {

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
    guard let url = URL(string: passUrlString) else {
      completion(false, "INVALID_URL", "The pass URL is invalid")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    // Add custom headers (for authentication)
    if let headers = headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }

      if let error = error {
        DispatchQueue.main.async {
          completion(false, "NETWORK_ERROR", error.localizedDescription)
        }
        return
      }

      if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
        DispatchQueue.main.async {
          completion(false, "HTTP_ERROR", "HTTP \(httpResponse.statusCode)")
        }
        return
      }

      guard let data = data else {
        DispatchQueue.main.async {
          completion(false, "INVALID_DATA", "No data received")
        }
        return
      }

      DispatchQueue.main.async {
        self.completion = completion
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
    guard let pass = try? PKPass(data: data) else {
      addPassCompletion(false, "INVALID_PASS", "Failed to parse pass data")
      return
    }

    self.pass = pass
    self.passLibrary = PKPassLibrary()

    if self.passLibrary?.containsPass(pass) == true {
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

    guard let controller = PKAddPassesViewController(pass: pass) else {
      addPassCompletion(false, "CONTROLLER_ERROR", "Failed to create pass controller")
      return
    }
    controller.delegate = self

    top.present(controller, animated: true)

  }

  // MARK: - Delegate

  @MainActor public func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
    controller.dismiss(animated: true) { [weak self] in
      guard let self = self else { return }
      if
         let pass = self.pass,
         let library = self.passLibrary {
        let wasAdded = library.containsPass(pass)
        if wasAdded {
          addPassCompletion(true, nil, nil)
        } else {
          addPassCompletion(false, "USER_CANCELLED", "User cancelled or declined to add pass")
        }
      }
      self.passLibrary = nil
      self.pass = nil
      controller.delegate = nil
    }
  }

  // MARK: - Helper

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
