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
                             headers: [String: Any]?,
                             completion: @escaping (Bool, String?, String?) -> Void
  ) {
    guard let url = Self.makeURL(passUrlString) else {
      completion(false, "INVALID_URL", "The pass URL is invalid")
      return
    }
    addPasses([(position: 1, url: url)], headers: headers, numbered: false, completion: completion)
  }

  // MARK: - addPassesFromUrls

  // Takes [Any]: an element that is not a string (null from JS) must reject,
  // not trap in the bridge.
  @MainActor @objc(addPassesFromUrls:headers:completion:)
  public func addPassesFromUrls(_ passUrlStrings: [Any],
                                headers: [String: Any]?,
                                completion: @escaping (Bool, String?, String?) -> Void
  ) {
    guard !passUrlStrings.isEmpty else {
      completion(false, "INVALID_URL", "No pass URLs given")
      return
    }
    var entries: [(position: Int, url: URL)] = []
    for (index, value) in passUrlStrings.enumerated() {
      guard let string = value as? String, let url = Self.makeURL(string) else {
        completion(false, "INVALID_URL", "URL \(index + 1): The pass URL is invalid")
        return
      }
      // The same URL is downloaded once.
      if !entries.contains(where: { $0.url == url }) {
        entries.append((position: index + 1, url: url))
      }
    }
    addPasses(entries, headers: headers, numbered: true, completion: completion)
  }

  // Downloads every URL, merges the passes and presents them in one sheet.
  // The first download that fails cancels the others and rejects the call.
  // With `numbered`, an error message names the failed URL by its position.
  @MainActor private func addPasses(_ entries: [(position: Int, url: URL)],
                                    headers: [String: Any]?,
                                    numbered: Bool,
                                    completion: @escaping (Bool, String?, String?) -> Void
  ) {
    guard beginAddPass() else {
      completion(false, "ADD_PASS_IN_PROGRESS", "Another pass is already being added")
      return
    }
    self.completion = completion
    self.isLoading = true

    var downloads = [Data?](repeating: nil, count: entries.count)
    var failure: (index: Int, errorCode: String, errorMessage: String)?
    var tasks: [URLSessionDataTask] = []
    let lock = NSLock()
    let group = DispatchGroup()
    // All tasks are created before any starts and the array is shared under
    // the lock, so the first failure can cancel every other download.
    let created = entries.enumerated().map { index, entry in
      Self.makeTask(entry.url, headers: headers) { data, errorCode, errorMessage in
        var toCancel: [URLSessionDataTask] = []
        lock.lock()
        if let data = data {
          downloads[index] = data
        } else if failure == nil {
          failure = (index, errorCode ?? "INVALID_DATA", errorMessage ?? "No data received")
          toCancel = tasks
        }
        lock.unlock()
        toCancel.forEach { $0.cancel() }
        group.leave()
      }
    }
    lock.lock()
    tasks = created
    lock.unlock()
    // Enter for every task before any starts: a failure cancels tasks that are
    // not started yet, and their completions leave the group right away.
    created.forEach { _ in group.enter() }
    created.forEach { $0.resume() }

    group.notify(queue: .main) { [weak self] in
      // The completions capture `tasks`, and the tasks hold the completions.
      // Clear it so the cycle never outlives the request.
      lock.lock()
      tasks = []
      lock.unlock()

      guard let self = self else { return }
      self.isLoading = false

      let fail = { (index: Int, errorCode: String, errorMessage: String) in
        let message = numbered ? "URL \(entries[index].position): \(errorMessage)" : errorMessage
        self.addPassCompletion(false, errorCode, message)
      }

      if let failure = failure {
        fail(failure.index, failure.errorCode, failure.errorMessage)
        return
      }

      var passes: [PKPass] = []
      for (index, data) in downloads.enumerated() {
        let parsed = Self.parsePasses(from: data ?? Data())
        guard !parsed.isEmpty else {
          fail(index, "INVALID_PASS", "Failed to parse pass data")
          return
        }
        passes.append(contentsOf: parsed)
      }

      self.showViewController(with: Self.uniquePasses(passes))
    }
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
    let parsedPasses = Self.uniquePasses(Self.parsePasses(from: data))
    guard !parsedPasses.isEmpty else {
      addPassCompletion(false, "INVALID_PASS", "Failed to parse pass data")
      return
    }
    showViewController(with: parsedPasses)
  }

  @MainActor private func showViewController(with parsedPasses: [PKPass]) {
    let library = PKPassLibrary()
    let missingPasses = parsedPasses.filter { !library.containsPass($0) }
    guard !missingPasses.isEmpty else {
      let message = parsedPasses.count == 1
        ? "This pass is already in your wallet"
        : "These passes are already in your wallet"
      addPassCompletion(false, "PASS_ALREADY_EXISTS", message)
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

  // A GET task with custom headers (for authentication), not started yet. Calls
  // back off the main thread with the body, or with an error code and message.
  private static func makeTask(_ url: URL,
                               headers: [String: Any]?,
                               completion: @escaping (Data?, String?, String?) -> Void) -> URLSessionDataTask {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    for (key, value) in headers ?? [:] {
      if let text = headerValue(value) {
        request.setValue(text, forHTTPHeaderField: key)
      }
    }

    return URLSession.shared.dataTask(with: request) { data, response, error in
      if let error = error {
        completion(nil, "NETWORK_ERROR", error.localizedDescription)
        return
      }
      if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
        completion(nil, "HTTP_ERROR", "HTTP \(httpResponse.statusCode)")
        return
      }
      guard let data = data else {
        completion(nil, "INVALID_DATA", "No data received")
        return
      }
      completion(data, nil, nil)
    }
  }

  // Header values come from JS untyped: a number or boolean is sent as text,
  // null is skipped.
  private static func headerValue(_ value: Any) -> String? {
    switch value {
    case let text as String:
      return text
    case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
      return number.boolValue ? "true" : "false"
    case let number as NSNumber:
      return number.stringValue
    default:
      return nil
    }
  }

  // Accepts a single .pkpass or a .pkpasses bundle of them. Callers remove
  // duplicates with uniquePasses.
  private static func parsePasses(from data: Data) -> [PKPass] {
    if let pass = try? PKPass(data: data) {
      return [pass]
    }

    var passes: [PKPass] = []
    for (index, entry) in PassesBundle.extractPassEntries(from: data).enumerated() {
      do {
        passes.append(try PKPass(data: entry))
      } catch {
        print("wallet", "Failed to parse pass \(index) in bundle:", error.localizedDescription)
      }
    }
    return passes
  }

  private static func uniquePasses(_ passes: [PKPass]) -> [PKPass] {
    var seen = Set<String>()
    return passes.filter { seen.insert($0.passTypeIdentifier + "\n" + $0.serialNumber).inserted }
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
