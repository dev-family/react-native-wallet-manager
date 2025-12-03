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
  private var completion: ((Bool) -> Void)?

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

  @MainActor @objc(addPassFromUrl:completion:)
  public func addPassFromUrl(_ passUrlString: String,
                             completion: @escaping (Bool) -> Void
  ) {
    guard let url = URL(string: passUrlString) else {
      completion(false)
      print("wallet", "The pass URL is invalid")
      return
    }
    
    guard let data = try? Data(contentsOf: url) else {
      completion(false)
      print("wallet", "The pass data is invalid")
      return
    }
    
    self.showViewController(with: data)
    self.completion = completion
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
      addPassCompletion(false)
      print("wallet", "The pass is invalid")
      return
    }

    self.pass = pass
    self.passLibrary = PKPassLibrary()

    if self.passLibrary?.containsPass(pass) == true {
      addPassCompletion(false)
      return print("wallet", "pass already added")
    }

    guard let root = UIApplication.shared.keyWindow?.rootViewController else {
      addPassCompletion(false)
      return print("wallet", "No rootViewController found")
    }

    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }

    guard let controller = PKAddPassesViewController(pass: pass) else {
      addPassCompletion(false)
      return print("wallet", "no PKAddPassesViewController")
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
        addPassCompletion(library.containsPass(pass))
      }
      self.passLibrary = nil
      self.pass = nil
      controller.delegate = nil
    }
  }

  // MARK: - Helper
  
  private func addPassCompletion(_ result: Bool) {
    self.completion?(result)
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
