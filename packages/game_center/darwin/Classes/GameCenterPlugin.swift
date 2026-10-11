import GameKit

#if os(iOS)
import Flutter
import UIKit
#else
import AppKit
import FlutterMacOS
#endif

/// Game Center for Donut: signs the player in, shows Apple's matchmaking
/// screen (invite friends or find players), and relays match data.
///
/// Methods on "donut/game_center": authenticate, findMatch {min, max},
/// send {data, to?, reliable?}, disconnect.
/// Events on "donut/game_center/events", each a map with a "type":
/// matchStarted {localId, players: [{id, alias}]}, data {from, data},
/// playerLeft {id}, cancelled, failed {message}.
public class GameCenterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, GKMatchDelegate,
  GKMatchmakerViewControllerDelegate, GKLocalPlayerListener
{
  private var sink: FlutterEventSink?
  private var match: GKMatch?
  private var started = false
  private var waitingForSignIn: [FlutterResult] = []
  private var signInHandlerSet = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    #if os(iOS)
      let messenger = registrar.messenger()
    #else
      let messenger = registrar.messenger
    #endif
    let instance = GameCenterPlugin()
    let methods = FlutterMethodChannel(name: "donut/game_center", binaryMessenger: messenger)
    registrar.addMethodCallDelegate(instance, channel: methods)
    FlutterEventChannel(name: "donut/game_center/events", binaryMessenger: messenger).setStreamHandler(instance)
  }

  // MARK: - Channels

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// Match callbacks can arrive on any thread; Flutter wants the main one.
  private func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { self.sink?(event) }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "authenticate":
      authenticate(result)
    case "findMatch":
      findMatch(min: args["min"] as? Int ?? 2, max: args["max"] as? Int ?? 4, result: result)
    case "send":
      send(args, result: result)
    case "disconnect":
      endMatch()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Signing in

  private func playerInfo() -> [String: Any] {
    let local = GKLocalPlayer.local
    return ["id": local.gamePlayerID, "alias": local.alias]
  }

  private func authenticate(_ result: @escaping FlutterResult) {
    let local = GKLocalPlayer.local
    if local.isAuthenticated {
      result(playerInfo())
      return
    }
    // Game Center only offers sign-in once per launch; after that the player
    // has to sign in from Settings
    if signInHandlerSet && waitingForSignIn.isEmpty {
      result(FlutterError(code: "not_signed_in",
                          message: "Sign in to Game Center in Settings to play with friends.", details: nil))
      return
    }
    waitingForSignIn.append(result)
    if signInHandlerSet { return }
    signInHandlerSet = true
    local.authenticateHandler = { [weak self] viewController, error in
      guard let self = self else { return }
      if let viewController = viewController {
        self.presentSignIn(viewController)
        return
      }
      let waiting = self.waitingForSignIn
      self.waitingForSignIn = []
      if local.isAuthenticated {
        // Hear about invites accepted from Messages or the Game Center app
        local.register(self)
        waiting.forEach { $0(self.playerInfo()) }
      } else {
        let message = error?.localizedDescription ?? "Sign in to Game Center to play with friends."
        waiting.forEach { $0(FlutterError(code: "not_signed_in", message: message, details: nil)) }
      }
    }
  }

  // MARK: - Matchmaking

  private func findMatch(min: Int, max: Int, result: @escaping FlutterResult) {
    guard GKLocalPlayer.local.isAuthenticated else {
      result(FlutterError(code: "not_signed_in", message: "Sign in to Game Center first.", details: nil))
      return
    }
    let request = GKMatchRequest()
    request.minPlayers = min
    request.maxPlayers = max
    guard let picker = GKMatchmakerViewController(matchRequest: request) else {
      result(FlutterError(code: "unavailable", message: "Game Center matchmaking isn't available.", details: nil))
      return
    }
    showMatchmaker(picker)
    result(nil)
  }

  private func showMatchmaker(_ picker: GKMatchmakerViewController) {
    endMatch()
    picker.matchmakerDelegate = self
    present(picker)
  }

  public func matchmakerViewControllerWasCancelled(_ viewController: GKMatchmakerViewController) {
    dismiss(viewController)
    emit(["type": "cancelled"])
  }

  public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFailWithError error: Error) {
    dismiss(viewController)
    emit(["type": "failed", "message": error.localizedDescription])
  }

  public func matchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKMatch) {
    dismiss(viewController)
    self.match = match
    started = false
    match.delegate = self
    startIfEveryoneIsHere(match)
  }

  /// An invite accepted outside the app opens the matchmaker on that invite.
  public func player(_ player: GKPlayer, didAccept invite: GKInvite) {
    guard let picker = GKMatchmakerViewController(invite: invite) else { return }
    showMatchmaker(picker)
  }

  private func startIfEveryoneIsHere(_ match: GKMatch) {
    guard !started, match.expectedPlayerCount == 0 else { return }
    started = true
    var players = [playerInfo()]
    players += match.players.map { ["id": $0.gamePlayerID, "alias": $0.alias] }
    emit(["type": "matchStarted", "localId": GKLocalPlayer.local.gamePlayerID, "players": players])
  }

  private func endMatch() {
    match?.delegate = nil
    match?.disconnect()
    match = nil
    started = false
  }

  // MARK: - In a match

  private func send(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let match = match, let data = args["data"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "no_match", message: "Not in a match.", details: nil))
      return
    }
    let mode: GKMatch.SendDataMode = (args["reliable"] as? Bool ?? true) ? .reliable : .unreliable
    do {
      if let to = args["to"] as? [String] {
        try match.send(data.data, to: match.players.filter { to.contains($0.gamePlayerID) }, dataMode: mode)
      } else {
        try match.sendData(toAllPlayers: data.data, with: mode)
      }
      result(nil)
    } catch {
      result(FlutterError(code: "send_failed", message: error.localizedDescription, details: nil))
    }
  }

  public func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
    emit(["type": "data", "from": player.gamePlayerID, "data": FlutterStandardTypedData(bytes: data)])
  }

  public func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
    switch state {
    case .connected:
      startIfEveryoneIsHere(match)
    case .disconnected:
      emit(["type": "playerLeft", "id": player.gamePlayerID])
    default:
      break
    }
  }

  public func match(_ match: GKMatch, didFailWithError error: Error?) {
    emit(["type": "failed", "message": error?.localizedDescription ?? "The match failed."])
  }

  // MARK: - Showing Apple's screens

  #if os(iOS)
    private static func topViewController() -> UIViewController? {
      let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
      var top = (windows.first { $0.isKeyWindow } ?? windows.first)?.rootViewController
      while let presented = top?.presentedViewController { top = presented }
      return top
    }

    private func presentSignIn(_ viewController: UIViewController) {
      Self.topViewController()?.present(viewController, animated: true)
    }

    private func present(_ picker: GKMatchmakerViewController) {
      Self.topViewController()?.present(picker, animated: true)
    }

    private func dismiss(_ picker: GKMatchmakerViewController) {
      picker.dismiss(animated: true)
    }
  #else
    private var window: NSWindow? { NSApplication.shared.mainWindow ?? NSApplication.shared.windows.first }

    private func presentSignIn(_ viewController: NSViewController) {
      window?.contentViewController?.presentAsSheet(viewController)
    }

    private func present(_ picker: GKMatchmakerViewController) {
      let dialogs = GKDialogController.shared()
      dialogs.parentWindow = window
      dialogs.present(picker)
    }

    private func dismiss(_ picker: GKMatchmakerViewController) {
      GKDialogController.shared().dismiss(picker)
    }
  #endif
}
