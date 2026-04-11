import SwiftUI
import WeatherKit
import os

// File-scoped so BottomSheetView can share the same type.
fileprivate enum SheetDetent {
    case hidden
    case collapsed
    case expanded
}

struct WeatherMainContent: View {
    private static let logger = Logger(subsystem: "SpatialWeather", category: "WeatherMainContent")

    @ObservedObject var weatherManager: WeatherManager
    @ObservedObject var locationManager: LocationManager
    @Binding var useCelsius: Bool

    @State private var selectedHour: Date?
    @State private var showLocationPicker = false
    @State private var showSettings = false
    @State private var sheetDetent: SheetDetent = .collapsed
    @State private var isSheetDragging = false
    @State private var isVerticalDetailsScrolling = false
    @State private var isHourlyRailScrolling = false
    @State private var lastSceneSelectionNonce = 0
    @State private var hasSelectionPlaybackOverride = false

    #if DEBUG
    @StateObject private var splineDebugState = SplineDebugState()
    #endif

    private let calendar = Calendar.current

    private var selectedWeather: HourlyForecast? {
        guard let selectedHour else { return nil }
        return weatherManager.hourlyForecast.first {
            calendar.isDate($0.date, equalTo: selectedHour, toGranularity: .hour)
        }
    }

    private var selectedDayForecast: DailyForecast? {
        guard let selectedHour else { return weatherManager.dailyForecast.first }
        return weatherManager.dailyForecast.first { calendar.isDate($0.date, inSameDayAs: selectedHour) }
    }

    private var activeCondition: WeatherKit.WeatherCondition? {
        selectedWeather?.condition ?? weatherManager.currentWeather?.condition
    }

    private var activeTemperature: Double? {
        selectedWeather?.temperature ?? weatherManager.currentWeather?.temperature
    }

    private var activeHighTemperature: Double? {
        selectedDayForecast?.highTemperature ?? weatherManager.currentWeather?.highTemperature
    }

    private var activeLowTemperature: Double? {
        selectedDayForecast?.lowTemperature ?? weatherManager.currentWeather?.lowTemperature
    }

    private var activeFeelsLike: Double? {
        selectedWeather?.feelsLike ?? weatherManager.currentWeather?.feelsLike
    }

    private var liveIsNighttime: Bool {
        if let selectedHour,
           let selectedDayForecast,
           let sunrise = selectedDayForecast.sunrise,
           let sunset = selectedDayForecast.sunset {
            return selectedHour < sunrise || selectedHour > sunset
        }

        if let currentWeather = weatherManager.currentWeather,
           let sunrise = currentWeather.sunrise,
           let sunset = currentWeather.sunset {
            let now = Date()
            return now < sunrise || now > sunset
        }

        // Fallback: use local hour when sunrise/sunset data is unavailable
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 6 || hour >= 19
    }

    private var liveFamily: SimplifiedWeatherFamily {
        activeCondition?.simplifiedFamily ?? .clear
    }

    private var liveSeason: Season {
        Season.presentationSeason(
            for: selectedHour ?? Date(),
            latitude: locationManager.location?.coordinate.latitude,
            family: activeCondition?.simplifiedFamily
        )
    }

    private var effectiveFamily: SimplifiedWeatherFamily {
        #if DEBUG
        splineDebugState.isEnabled ? splineDebugState.effectiveFamily : liveFamily
        #else
        liveFamily
        #endif
    }

    private var effectiveSeason: Season {
        #if DEBUG
        splineDebugState.isEnabled ? splineDebugState.season : liveSeason
        #else
        liveSeason
        #endif
    }

    private var effectiveIsNighttime: Bool {
        #if DEBUG
        splineDebugState.isEnabled ? splineDebugState.effectiveIsNighttime : liveIsNighttime
        #else
        liveIsNighttime
        #endif
    }

    private var theme: WeatherTheme {
        WeatherThemeResolver.resolve(
            family: effectiveFamily,
            season: effectiveSeason,
            isNighttime: effectiveIsNighttime
        )
    }

    /*
    private var sceneKey: SplineSceneKey? {
        #if DEBUG
        if splineDebugState.isEnabled {
            return SplineSceneKey(
                family: effectiveFamily,
                isNighttime: effectiveIsNighttime,
                override: splineDebugState.sceneName
            )
        }
        #endif

        guard weatherManager.currentWeather != nil || selectedWeather != nil else {
            return nil
        }

        return SplineSceneKey(family: effectiveFamily, isNighttime: effectiveIsNighttime)
    }
    */

    private var splineState: SplineWeatherState {
        #if DEBUG
        if splineDebugState.isEnabled {
            return splineDebugState.splineState
        }
        #endif

        return SplineWeatherState(
            family: effectiveFamily,
            season: effectiveSeason,
            isNighttime: effectiveIsNighttime
        )
    }

    private var scenePlaybackMode: ScenePlaybackMode {
        if showSettings || showLocationPicker {
            return .pausedForModal
        }

        if hasSelectionPlaybackOverride {
            return .active
        }

        if isSheetDragging || isVerticalDetailsScrolling || isHourlyRailScrolling {
            return .pausedForInteraction
        }

        return .active
    }

    private var overlaySurfaceStyle: WeatherSurfaceStyle {
        if isSheetDragging || isVerticalDetailsScrolling || isHourlyRailScrolling {
            return .flatTint
        }

        return .liveGlass
    }

    private var themeKey: String {
        "\(effectiveSeason.rawValue)-\(effectiveFamily.rawValue)-\(effectiveIsNighttime)"
    }

    private var selectionSummary: String {
        if let selectedHour {
            return "Previewing \(DateFormatters.formatShortTime(selectedHour))"
        }
        return weatherManager.currentWeather == nil ? "Loading current conditions" : "Live conditions"
    }

    private var isLoading: Bool {
        weatherManager.currentWeather == nil && weatherManager.hourlyForecast.isEmpty
    }

    private var hasRenderableSplineScene: Bool {
        weatherManager.currentWeather != nil || selectedWeather != nil
    }

    private var debugSceneSnapshotKey: String {
        let selectedHourStamp = selectedHour?.timeIntervalSince1970 ?? -1
        let currentSunriseStamp = weatherManager.currentWeather?.sunrise?.timeIntervalSince1970 ?? -1
        let currentSunsetStamp = weatherManager.currentWeather?.sunset?.timeIntervalSince1970 ?? -1
        let selectedSunriseStamp = selectedDayForecast?.sunrise?.timeIntervalSince1970 ?? -1
        let selectedSunsetStamp = selectedDayForecast?.sunset?.timeIntervalSince1970 ?? -1

        return [
            String(selectedHourStamp),
            String(currentSunriseStamp),
            String(currentSunsetStamp),
            String(selectedSunriseStamp),
            String(selectedSunsetStamp),
            String(describing: activeCondition),
            splineState.key
        ].joined(separator: "|")
    }

    #if DEBUG
    private var debugSplineSummary: String {
        // Show the actual live state (not the debug override defaults) so snow→winter is visible.
        let state = splineDebugState.isEnabled ? splineDebugState.splineState : splineState
        return "Spline w:\(Int(state.weatherIndex)) t:\(Int(state.timeOfDay)) s:\(Int(state.season))"
    }
    #endif

    var body: some View {
        GeometryReader { geometry in
            let currentTheme = theme
            let safeTop = geometry.safeAreaInsets.top
            let safeBottom = geometry.safeAreaInsets.bottom
            let availableSheetHeight = max(geometry.size.height - safeTop - 18, 0)
            let hiddenHeight = min(max(22, safeBottom + 10), availableSheetHeight)
            let expandedHeight = min(max(geometry.size.height * 0.78, 560), availableSheetHeight)
            let collapsedHeight = min(
                min(max(geometry.size.height * 0.34, 240), 300),
                expandedHeight
            )

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: currentTheme.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                LinearGradient(
                    colors: currentTheme.atmosphereColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.28), value: themeKey)

                if hasRenderableSplineScene {
                    WeatherSymbol3D(
                        splineState: splineState,
                        scenePlaybackMode: scenePlaybackMode
                    )
                        .equatable()
                        .ignoresSafeArea()
                }

                Rectangle()
                    .fill(currentTheme.overlayTint.opacity(currentTheme.overlayOpacity))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                LinearGradient(
                    colors: [
                        currentTheme.overlayTint.opacity(currentTheme.vignetteOpacity),
                        .clear,
                        currentTheme.overlayTint.opacity(0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

                heroSection(theme: currentTheme, surfaceStyle: overlaySurfaceStyle)
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    // Opacity only responds to detent snaps, not every drag tick —
                    // sheetDragTranslation now lives inside BottomSheetView.
                    .opacity(sheetDetent == .expanded ? 0.82 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: sheetDetent)

                BottomSheetView(
                    theme: currentTheme,
                    hiddenHeight: hiddenHeight,
                    collapsedHeight: collapsedHeight,
                    expandedHeight: expandedHeight,
                    safeBottom: safeBottom,
                    surfaceStyle: overlaySurfaceStyle,
                    sheetDetent: $sheetDetent,
                    selectedHour: $selectedHour,
                    hourlyForecast: weatherManager.hourlyForecast,
                    dailyForecast: weatherManager.dailyForecast,
                    currentWeather: weatherManager.currentWeather,
                    useCelsius: useCelsius,
                    onSheetDragStateChange: { isDragging in
                        if isSheetDragging != isDragging {
                            isSheetDragging = isDragging
                        }
                    },
                    onVerticalScrollStateChange: { isScrolling in
                        if isVerticalDetailsScrolling != isScrolling {
                            isVerticalDetailsScrolling = isScrolling
                        }
                    },
                    onHourlyRailScrollStateChange: { isScrolling in
                        if isHourlyRailScrolling != isScrolling {
                            isHourlyRailScrolling = isScrolling
                        }
                    },
                    onHourSelection: handleHourSelection,
                    onRefresh: {
                        if let location = locationManager.location {
                            await weatherManager.forceRefetch(for: location)
                        }
                    }
                )

                if isLoading {
                    ProgressView()
                        .tint(currentTheme.primaryText)
                        .scaleEffect(1.2)
                }
            }
        }
        .task(id: debugSceneSnapshotKey) {
            logSceneDecision(reason: "state-change")
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(locationManager: locationManager) {
                showLocationPicker = false
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            #if DEBUG
            SettingsView(useCelsius: $useCelsius, locationManager: locationManager, debugState: splineDebugState)
            #else
            SettingsView(useCelsius: $useCelsius, locationManager: locationManager)
            #endif
        }
    }

    private func heroSection(theme: WeatherTheme, surfaceStyle: WeatherSurfaceStyle) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Button {
                    showLocationPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.subheadline.weight(.semibold))
                        Text(locationManager.locationName)
                            .font(.title3.weight(.bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(theme.primaryText)
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 1)
                }
                .buttonStyle(.plain)

                Text(displayTemperature(activeTemperature))
                    .font(.system(size: 86, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .shadow(color: .black.opacity(0.20), radius: 6, x: 0, y: 2)
                    .contentTransition(.numericText())

                HStack(spacing: 8) {
                    Image(systemName: activeCondition?.systemIcon(isNighttime: effectiveIsNighttime) ?? "clock.fill")
                        .imageScale(.medium)
                        .font(.subheadline.weight(.semibold))
                    Text(activeCondition?.displayName ?? "Loading weather")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(theme.secondaryText)
                .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)

                HStack(spacing: 8) {
                    floatingPill(label: "H", value: displayTemperature(activeHighTemperature), theme: theme)
                    floatingPill(label: "L", value: displayTemperature(activeLowTemperature), theme: theme)
                    floatingPill(label: "Feels like", value: displayTemperature(activeFeelsLike), theme: theme)
                }
                .padding(.top, 2)

                Text(selectionSummary)
                    .font(.footnote)
                    .foregroundStyle(theme.tertiaryText)
                    .shadow(color: .black.opacity(0.20), radius: 3, x: 0, y: 1)

                #if DEBUG
                if splineDebugState.isEnabled {
                    Text(debugSplineSummary)
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.floatingChipFill, in: Capsule())
                        .overlay(Capsule().stroke(theme.cardStroke, lineWidth: 1))
                }
                #endif
            }
            .padding(.leading, 6)

            Spacer(minLength: 12)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .background(heroButtonFill(surfaceStyle: surfaceStyle, theme: theme), in: Circle())
            .overlay(Circle().stroke(theme.cardStroke, lineWidth: 1))
            .shadow(
                color: .black.opacity(surfaceStyle == .liveGlass ? 0.15 : 0.08),
                radius: surfaceStyle == .liveGlass ? 8 : 4,
                x: 0,
                y: 2
            )
        }
    }

    private func floatingPill(label: String, value: String, theme: WeatherTheme) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundStyle(theme.tertiaryText)
            Text(value)
                .foregroundStyle(theme.primaryText)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.floatingChipFill, in: Capsule())
        .overlay(
            Capsule()
                .stroke(theme.cardStroke, lineWidth: 1)
        )
    }

    private func displayTemperature(_ temperature: Double?) -> String {
        guard let temperature else { return "--" }
        return "\(formatTemperature(temperature, useCelsius: useCelsius))°"
    }

    private func heroButtonFill(surfaceStyle: WeatherSurfaceStyle, theme: WeatherTheme) -> AnyShapeStyle {
        switch surfaceStyle {
        case .liveGlass:
            AnyShapeStyle(.ultraThinMaterial)
        case .flatTint:
            AnyShapeStyle(theme.overlayTint.opacity(0.24))
        }
    }

    private func handleHourSelection(_: Date?) {
        isVerticalDetailsScrolling = false
        isHourlyRailScrolling = false
        Task { @MainActor in
            // Let the selected hour propagate through SwiftUI first so any replay
            // happens against the new splineState instead of the previous one.
            await Task.yield()

            lastSceneSelectionNonce &+= 1
            hasSelectionPlaybackOverride = true
            logSceneDecision(reason: "hour-selection nonce=\(lastSceneSelectionNonce)")

            let currentNonce = lastSceneSelectionNonce
            try? await Task.sleep(for: .milliseconds(350))
            guard currentNonce == lastSceneSelectionNonce else { return }
            hasSelectionPlaybackOverride = false
            logSceneDecision(reason: "hour-selection-reset nonce=\(currentNonce)")
        }
    }

    private func logSceneDecision(reason: String) {
        let selectedHourText = formatDebugDate(selectedHour)
        let selectedSunriseText = formatDebugDate(selectedDayForecast?.sunrise)
        let selectedSunsetText = formatDebugDate(selectedDayForecast?.sunset)
        let currentSunriseText = formatDebugDate(weatherManager.currentWeather?.sunrise)
        let currentSunsetText = formatDebugDate(weatherManager.currentWeather?.sunset)

        Self.logger.debug(
            """
            [scene] reason=\(reason, privacy: .public) selectedHour=\(selectedHourText, privacy: .public) \
            renderable=\(hasRenderableSplineScene, privacy: .public) \
            family=\(effectiveFamily.rawValue, privacy: .public) season=\(effectiveSeason.rawValue, privacy: .public) \
            isNight=\(effectiveIsNighttime, privacy: .public) splineKey=\(splineState.key, privacy: .public) \
            selectedSunrise=\(selectedSunriseText, privacy: .public) selectedSunset=\(selectedSunsetText, privacy: .public) \
            currentSunrise=\(currentSunriseText, privacy: .public) currentSunset=\(currentSunsetText, privacy: .public)
            """
        )
    }

    private func formatDebugDate(_ date: Date?) -> String {
        guard let date else { return "nil" }
        return date.formatted(date: .omitted, time: .standard)
    }
}

// MARK: - BottomSheetView

/// Owns sheetDragTranslation so drag-gesture state changes only re-evaluate this
/// view's body, not all of WeatherMainContent.
private struct BottomSheetView: View {
    let theme: WeatherTheme
    let hiddenHeight: CGFloat
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    let safeBottom: CGFloat
    let surfaceStyle: WeatherSurfaceStyle

    @Binding var sheetDetent: SheetDetent
    @Binding var selectedHour: Date?

    let hourlyForecast: [HourlyForecast]
    let dailyForecast: [DailyForecast]
    let currentWeather: Weather?
    let useCelsius: Bool
    let onSheetDragStateChange: (Bool) -> Void
    let onVerticalScrollStateChange: (Bool) -> Void
    let onHourlyRailScrollStateChange: (Bool) -> Void
    let onHourSelection: (Date?) -> Void
    let onRefresh: () async -> Void

    @State private var dragTranslation: CGFloat = 0

    private var currentHeight: CGFloat {
        let base: CGFloat
        switch sheetDetent {
        case .hidden:    base = hiddenHeight
        case .collapsed: base = collapsedHeight
        case .expanded:  base = expandedHeight
        }
        return min(max(base - dragTranslation, hiddenHeight), expandedHeight)
    }

    private var headerOpacity: Double {
        min(max((currentHeight - hiddenHeight) / 36, 0), 1)
    }

    private var isContentVisible: Bool {
        currentHeight > hiddenHeight + 48
    }

    private var handlePrompt: String {
        switch sheetDetent {
        case .hidden:    return "Drag up to open details"
        case .collapsed: return "Drag up for more details"
        case .expanded:  return "Pull down to return to the scene"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle + label
            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.45))
                    .frame(width: 42, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                HStack {
                    Text(handlePrompt)
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 6)
                .opacity(headerOpacity)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    sheetDetent = nextDetent(after: sheetDetent)
                }
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    HourlyForecastView(
                        forecast: hourlyForecast,
                        dailyForecast: dailyForecast,
                        useCelsius: useCelsius,
                        theme: theme,
                        surfaceStyle: surfaceStyle,
                        selectedHour: $selectedHour,
                        onHourSelection: onHourSelection,
                        onScrollStateChange: onHourlyRailScrollStateChange
                    )

                    DailyForecastView(
                        forecast: dailyForecast,
                        useCelsius: useCelsius,
                        theme: theme,
                        surfaceStyle: surfaceStyle
                    )

                    WeatherDetailsGrid(
                        weather: currentWeather,
                        useCelsius: useCelsius,
                        theme: theme,
                        surfaceStyle: surfaceStyle
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, safeBottom + 18)
                .padding(.top, 6)
            }
            .refreshable {
                await onRefresh()
            }
            .onScrollPhaseChange { _, newPhase in
                onVerticalScrollStateChange(newPhase.isScrolling)
            }
            .opacity(isContentVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: expandedHeight, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(sheetBackgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    theme.overlayTint.opacity(0.18),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(surfaceStyle == .liveGlass ? 1 : 0.82)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(theme.cardStroke, lineWidth: 1)
                )
                .shadow(
                    color: .black.opacity(surfaceStyle == .liveGlass ? 0.24 : 0.10),
                    radius: surfaceStyle == .liveGlass ? 24 : 12,
                    x: 0,
                    y: -8
                )
        )
        .padding(.horizontal, 10)
        .padding(.bottom, max(6, safeBottom * 0.2))
        .offset(y: expandedHeight - currentHeight)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: sheetDetent)
        .onDisappear {
            onSheetDragStateChange(false)
            onVerticalScrollStateChange(false)
            onHourlyRailScrollStateChange(false)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                onSheetDragStateChange(true)
                dragTranslation = value.translation.height
            }
            .onEnded { value in
                onSheetDragStateChange(false)
                let base: CGFloat
                switch sheetDetent {
                case .hidden:    base = hiddenHeight
                case .collapsed: base = collapsedHeight
                case .expanded:  base = expandedHeight
                }

                let projectedHeight = min(
                    max(base - value.predictedEndTranslation.height, hiddenHeight),
                    expandedHeight
                )

                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    sheetDetent = nearestDetent(for: projectedHeight)
                    dragTranslation = 0
                }
            }
    }

    private var sheetBackgroundFill: AnyShapeStyle {
        switch surfaceStyle {
        case .liveGlass:
            AnyShapeStyle(.ultraThinMaterial)
        case .flatTint:
            AnyShapeStyle(theme.overlayTint.opacity(0.30))
        }
    }

    private func nextDetent(after detent: SheetDetent) -> SheetDetent {
        switch detent {
        case .hidden:    return .collapsed
        case .collapsed: return .expanded
        case .expanded:  return .hidden
        }
    }

    private func nearestDetent(for projectedHeight: CGFloat) -> SheetDetent {
        let detents: [(SheetDetent, CGFloat)] = [
            (.hidden, hiddenHeight),
            (.collapsed, collapsedHeight),
            (.expanded, expandedHeight)
        ]
        return detents.min { abs($0.1 - projectedHeight) < abs($1.1 - projectedHeight) }?.0 ?? .collapsed
    }
}
