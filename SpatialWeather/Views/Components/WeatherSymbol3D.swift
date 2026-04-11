import SwiftUI
import SplineRuntime
import os

private let weatherSymbol3DLogger = Logger(subsystem: "SpatialWeather", category: "WeatherSymbol3D")

enum ScenePlaybackMode: Equatable {
    case active
    case pausedForInteraction
    case pausedForModal

    var isActive: Bool {
        self == .active
    }
}

@MainActor
struct WeatherSymbol3D: View {
    let splineState: SplineWeatherState
    let scenePlaybackMode: ScenePlaybackMode

    /* --- COMMENTED OUT FOR ALL-IN-ONE SPLINE PERFORMANCE TEST ---
    @State private var sceneLayers: [SceneLayer] = []
    @State private var displayedLayerID: UUID?
    @State private var stagedLayerID: UUID?
    @State private var sceneTransitionProgress = 1.0
    @State private var isSceneTransitionAnimating = false
    @State private var sceneTransitionTask: Task<Void, Never>?

    private static let sceneSwapDuration: Duration = .milliseconds(350)
    private static let sceneSwapAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    private static let minimumVisibleScale: CGFloat = 0.001

    private var targetSceneKey: SplineWeatherSceneKey {
        SplineWeatherSceneKey(family: splineState.family)
    }
    */

    var body: some View {
        SplineSceneLayerView(
            sceneKey: SplineWeatherSceneKey(family: splineState.family), // Kept for logging/reference
            splineState: splineState,
            scenePlaybackMode: scenePlaybackMode,
            onInitialReveal: nil
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
        /*
        ZStack {
            ForEach(sceneLayers) { layer in
                SplineSceneLayerView(
                    sceneKey: layer.sceneKey,
                    splineState: layer.splineState,
                    scenePlaybackMode: scenePlaybackMode,
                    onInitialReveal: {
                        handleLayerReady(layer.id)
                    }
                )
                .id(layer.id)
                .scaleEffect(layerScale(for: layer.id), anchor: .center)
                .opacity(layerOpacity(for: layer.id))
                .zIndex(layerZIndex(for: layer.id))
                .allowsHitTesting(layer.id == displayedLayerID && stagedLayerID == nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
        .task(id: splineState.key) {
            synchronizeSceneLayers()
        }
        .onDisappear {
            cancelSceneTransition(resetProgress: false)
        }
        */
    }

    /* --- END ALL-IN-ONE SPLINE TEST (Commenting out layer functions) --- */
    /*
    @MainActor
    private func synchronizeSceneLayers() {
        weatherSymbol3DLogger.debug(
            "[host] synchronize targetScene=\(targetSceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public) displayed=\(displayedLayerID?.uuidString ?? "nil", privacy: .public) staged=\(stagedLayerID?.uuidString ?? "nil", privacy: .public)"
        )

        if sceneLayers.isEmpty {
            let initialLayer = SceneLayer(sceneKey: targetSceneKey, splineState: splineState)
            sceneLayers = [initialLayer]
            displayedLayerID = initialLayer.id
            stagedLayerID = nil
            sceneTransitionProgress = 1
            weatherSymbol3DLogger.debug(
                "[host] created initial layer id=\(initialLayer.id.uuidString, privacy: .public) scene=\(initialLayer.sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(initialLayer.splineState.key, privacy: .public)"
            )
            return
        }

        if let displayedLayer, displayedLayer.sceneKey == targetSceneKey {
            if let stagedLayerID {
                cancelSceneTransition()
                removeLayer(withID: stagedLayerID)
                self.stagedLayerID = nil
            }
            updateLayer(id: displayedLayer.id, splineState: splineState)
            return
        }

        if let stagedLayer, stagedLayer.sceneKey == targetSceneKey {
            updateLayer(id: stagedLayer.id, splineState: splineState)
            return
        }

        retargetScene(to: targetSceneKey, splineState: splineState)
    }

    @MainActor
    private func retargetScene(to sceneKey: SplineWeatherSceneKey, splineState: SplineWeatherState) {
        adoptDominantLayerIfNeeded()
        cancelSceneTransition(resetProgress: false)

        if let stagedLayerID {
            removeLayer(withID: stagedLayerID)
            self.stagedLayerID = nil
        }

        if let displayedLayer, displayedLayer.sceneKey == sceneKey {
            updateLayer(id: displayedLayer.id, splineState: splineState)
            sceneTransitionProgress = 1
            return
        }

        let nextLayer = SceneLayer(sceneKey: sceneKey, splineState: splineState)
        sceneLayers.append(nextLayer)
        stagedLayerID = nextLayer.id
        sceneTransitionProgress = 0
        weatherSymbol3DLogger.debug(
            "[host] staged new layer id=\(nextLayer.id.uuidString, privacy: .public) scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public)"
        )
    }

    @MainActor
    private func adoptDominantLayerIfNeeded() {
        guard let dominantLayerID else { return }

        displayedLayerID = dominantLayerID
        stagedLayerID = nil
        sceneLayers.removeAll { $0.id != dominantLayerID }
        sceneTransitionProgress = 1
    }

    @MainActor
    private func handleLayerReady(_ layerID: UUID) {
        guard layerID == stagedLayerID, let outgoingLayerID = displayedLayerID else {
            return
        }

        guard !isSceneTransitionAnimating else { return }

        cancelSceneTransition(resetProgress: false)
        isSceneTransitionAnimating = true
        sceneTransitionProgress = 0
        weatherSymbol3DLogger.debug(
            "[host] layer ready incoming=\(layerID.uuidString, privacy: .public) outgoing=\(outgoingLayerID.uuidString, privacy: .public) starting transition"
        )

        sceneTransitionTask = Task {
            await MainActor.run {
                withAnimation(Self.sceneSwapAnimation) {
                    sceneTransitionProgress = 1
                }
            }

            try? await Task.sleep(for: Self.sceneSwapDuration)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                displayedLayerID = layerID
                stagedLayerID = nil
                sceneLayers.removeAll { $0.id == outgoingLayerID }
                sceneTransitionProgress = 1
                isSceneTransitionAnimating = false
                sceneTransitionTask = nil
                weatherSymbol3DLogger.debug(
                    "[host] transition finished displayed=\(layerID.uuidString, privacy: .public) removed=\(outgoingLayerID.uuidString, privacy: .public)"
                )
            }
        }
    }

    @MainActor
    private func cancelSceneTransition(resetProgress: Bool = true) {
        sceneTransitionTask?.cancel()
        sceneTransitionTask = nil
        isSceneTransitionAnimating = false

        if resetProgress {
            sceneTransitionProgress = stagedLayerID == nil ? 1 : 0
        }
    }

    private var displayedLayer: SceneLayer? {
        guard let displayedLayerID else { return nil }
        return sceneLayers.first { $0.id == displayedLayerID }
    }

    private var stagedLayer: SceneLayer? {
        guard let stagedLayerID else { return nil }
        return sceneLayers.first { $0.id == stagedLayerID }
    }

    private var dominantLayerID: UUID? {
        if let stagedLayerID, isSceneTransitionAnimating, sceneTransitionProgress >= 0.5 {
            return stagedLayerID
        }

        return displayedLayerID
    }

    @MainActor
    private func updateLayer(id: UUID, splineState: SplineWeatherState) {
        guard let index = sceneLayers.firstIndex(where: { $0.id == id }) else { return }
        sceneLayers[index].splineState = splineState
    }

    @MainActor
    private func removeLayer(withID id: UUID) {
        sceneLayers.removeAll { $0.id == id }
    }

    private func layerScale(for layerID: UUID) -> CGFloat {
        // Removing the scale transition during crossfade to make scenes swap cleanly.
        // It avoids the slow "zoom-in" effect when sweeping through weather conditions.
        return 1
    }

    private func layerOpacity(for layerID: UUID) -> Double {
        guard let stagedLayerID else { return 1 }

        if layerID == stagedLayerID {
            return sceneTransitionProgress
        }

        if layerID == displayedLayerID {
            return 1 - sceneTransitionProgress
        }

        return 1
    }

    private func layerZIndex(for layerID: UUID) -> Double {
        layerID == stagedLayerID ? 1 : 0
    }
    */
}

extension WeatherSymbol3D: @MainActor Equatable {
    static func == (lhs: WeatherSymbol3D, rhs: WeatherSymbol3D) -> Bool {
        lhs.splineState == rhs.splineState &&
        lhs.scenePlaybackMode == rhs.scenePlaybackMode
    }
}

private struct SceneLayer: Identifiable {
    let id = UUID()
    let sceneKey: SplineWeatherSceneKey
    var splineState: SplineWeatherState
}

@MainActor
private struct SplineSceneLayerView: View {
    let sceneKey: SplineWeatherSceneKey
    let splineState: SplineWeatherState
    let scenePlaybackMode: ScenePlaybackMode
    let onInitialReveal: (() -> Void)?

    @State private var controller: SplineController
    @State private var hasLoadedScene = false
    @State private var hasInitiallyRevealed = false
    @State private var hasReportedInitialReveal = false
    @State private var lastLoggedAppliedStateKey: String?

    init(
        sceneKey: SplineWeatherSceneKey,
        splineState: SplineWeatherState,
        scenePlaybackMode: ScenePlaybackMode,
        onInitialReveal: (() -> Void)?
    ) {
        self.sceneKey = sceneKey
        self.splineState = splineState
        self.scenePlaybackMode = scenePlaybackMode
        self.onInitialReveal = onInitialReveal
        _controller = State(initialValue: Self.makeConfiguredController(for: splineState, sceneKey: sceneKey))
        weatherSymbol3DLogger.debug(
            "[layer] init scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public) timeOfDay=\(Int(splineState.timeOfDay), privacy: .public) season=\(Int(splineState.season), privacy: .public)"
        )
    }

    private var sceneURL: URL? {
        /* SplineWeatherSceneResolver.url(for: sceneKey) */
        
        // ALL-IN-ONE SPLINE MODIFICATION:
        // Force the single legacy "weather.splineswift" file instead of the family-specific ones.
        Bundle.main.url(forResource: "weather", withExtension: "splineswift")
    }

    var body: some View {
        Group {
            if let sceneURL {
                SplineView(sceneFileURL: sceneURL, controller: controller) { phase in
                    if let content = phase.content {
                        content
                            .onAppear {
                                hasLoadedScene = true
                                weatherSymbol3DLogger.debug(
                                    "[layer] appear scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public)"
                                )
                                Task { await performInitialReveal() }
                            }
                            .task(id: splineState.key) {
                                await applySplineVariables(shouldPlay: scenePlaybackMode.isActive)
                            }
                    } else {
                        Color.clear
                    }
                }
                // Keep the scene hidden until Spline settles into the requested variables.
                .opacity(hasInitiallyRevealed ? 1 : 0)
                .animation(hasInitiallyRevealed ? .none : .easeIn(duration: 0.35), value: hasInitiallyRevealed)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
        .task(id: scenePlaybackMode) {
            await updatePlaybackMode()
        }
    }

    @MainActor
    private func applyCurrentVariables(context: String) {
        controller.setNumberVariable(name: "weatherIndex", value: splineState.weatherIndex)
        controller.setNumberVariable(name: "timeofDay", value: splineState.timeOfDay)
        controller.setNumberVariable(name: "season", value: splineState.season)
        logAppliedStateIfNeeded(context: context)
    }

    @MainActor
    private func applySplineVariables(shouldPlay: Bool) async {
        guard hasLoadedScene, hasInitiallyRevealed else { return }
        weatherSymbol3DLogger.debug(
            "[layer] applySplineVariables scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public) shouldPlay=\(shouldPlay, privacy: .public)"
        )
        applyCurrentVariables(context: "applySplineVariables.start")
        if shouldPlay {
            controller.play()
        }
        try? await Task.sleep(for: .milliseconds(80))
        applyCurrentVariables(context: "applySplineVariables.retry")
        if shouldPlay {
            controller.play()
        }
    }

    @MainActor
    private func updatePlaybackMode() async {
        guard hasLoadedScene, hasInitiallyRevealed else { return }

        switch scenePlaybackMode {
        case .active:
            applyCurrentVariables(context: "updatePlaybackMode.active")
            controller.play()
        case .pausedForInteraction, .pausedForModal:
            controller.stop()
            weatherSymbol3DLogger.debug(
                "[layer] paused scene=\(sceneKey.sceneName.rawValue, privacy: .public) mode=\(String(describing: scenePlaybackMode), privacy: .public)"
            )
        }
    }

    @MainActor
    private func performInitialReveal() async {
        guard !hasInitiallyRevealed else { return }

        weatherSymbol3DLogger.debug(
            "[layer] initialReveal.start scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public)"
        )

        // Spline has complex internal startup sequences. Setting variables and playing
        // too early can cause race conditions where the scene graph resets to default
        // variables due to its internal 'on start' events.
        
        // 1. Give the scene runtime a setup buffer before we command it.
        try? await Task.sleep(for: .milliseconds(150))
        
        // 2. Prime the variables explicitly now that the graph is ready.
        applyCurrentVariables(context: "initialReveal.prime")
        controller.play()

        // 3. Allow time for internal 'start' transitions and animations to run.
        try? await Task.sleep(for: .milliseconds(850))
        
        // 4. Final safety apply in case any variables were clobbered during startup events.
        applyCurrentVariables(context: "initialReveal.final")

        hasInitiallyRevealed = true
        weatherSymbol3DLogger.debug(
            "[layer] initialReveal.done scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public)"
        )

        if scenePlaybackMode.isActive {
            controller.play()
        } else {
            controller.stop()
        }

        reportInitialRevealIfNeeded()
    }

    @MainActor
    private func reportInitialRevealIfNeeded() {
        guard hasInitiallyRevealed, !hasReportedInitialReveal else { return }
        hasReportedInitialReveal = true
        weatherSymbol3DLogger.debug(
            "[layer] reportInitialReveal scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public)"
        )
        onInitialReveal?()
    }

    private static func makeConfiguredController(for splineState: SplineWeatherState, sceneKey: SplineWeatherSceneKey) -> SplineController {
        let controller = SplineController()
        controller.setNumberVariable(name: "weatherIndex", value: splineState.weatherIndex)
        controller.setNumberVariable(name: "timeofDay", value: splineState.timeOfDay)
        controller.setNumberVariable(name: "season", value: splineState.season)
        weatherSymbol3DLogger.debug(
            "[layer] makeController scene=\(sceneKey.sceneName.rawValue, privacy: .public) weather=\(Int(splineState.weatherIndex), privacy: .public) timeOfDay=\(Int(splineState.timeOfDay), privacy: .public) season=\(Int(splineState.season), privacy: .public)"
        )
        return controller
    }

    @MainActor
    private func logAppliedStateIfNeeded(context: String) {
        let logKey = "\(context)|\(splineState.key)"
        guard lastLoggedAppliedStateKey != logKey else { return }
        lastLoggedAppliedStateKey = logKey

        weatherSymbol3DLogger.debug(
            "[layer] apply context=\(context, privacy: .public) scene=\(sceneKey.sceneName.rawValue, privacy: .public) splineKey=\(splineState.key, privacy: .public) weather=\(Int(splineState.weatherIndex), privacy: .public) timeOfDay=\(Int(splineState.timeOfDay), privacy: .public) season=\(Int(splineState.season), privacy: .public)"
        )
    }
}
