import Foundation
import Testing
import WeatherKit
@testable import SpatialWeather

struct WeatherPresentationTests {

    @Test func northernHemisphereSeasonMappingUsesCalendarMonth() {
        let julyDate = ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z")!
        let januaryDate = ISO8601DateFormatter().date(from: "2026-01-12T12:00:00Z")!

        #expect(Season.resolve(for: julyDate, latitude: 29.42) == .summer)
        #expect(Season.resolve(for: januaryDate, latitude: 29.42) == .winter)
    }

    @Test func southernHemisphereSeasonMappingInvertsNorthernDefault() {
        let julyDate = ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z")!
        let octoberDate = ISO8601DateFormatter().date(from: "2026-10-12T12:00:00Z")!

        #expect(Season.resolve(for: julyDate, latitude: -33.86) == .winter)
        #expect(Season.resolve(for: octoberDate, latitude: -33.86) == .spring)
    }

    @Test func snowPresentationSeasonForcesWinter() {
        let julyDate = ISO8601DateFormatter().date(from: "2026-07-12T12:00:00Z")!
        let season = Season.presentationSeason(for: julyDate, latitude: 40.71, family: .snow)

        #expect(season == .winter)
    }

    @Test func splineSceneKeyUsesOverrideWhenProvided() {
        let key = SplineSceneKey(
            family: .rain,
            isNighttime: false,
            override: .thunderstormNight
        )

        #expect(key.sceneName == .thunderstormNight)
    }

    @Test func splineSceneKeyResolvesExpectedDefaultScene() {
        let key = SplineSceneKey(family: .snow, isNighttime: true)
        #expect(key.sceneName == .snowNight)
    }

    @Test func weatherKitConditionMapsToSimplifiedFamily() {
        #expect(WeatherKit.WeatherCondition.clear.simplifiedFamily == .clear)
        #expect(WeatherKit.WeatherCondition.rain.simplifiedFamily == .rain)
        #expect(WeatherKit.WeatherCondition.cloudy.simplifiedFamily == .cloudy)
        #expect(WeatherKit.WeatherCondition.thunderstorms.simplifiedFamily == .thunderstorm)
    }

    @Test func nighttimeIconsUseMoonVariantsWhenAvailable() {
        #expect(WeatherKit.WeatherCondition.clear.systemIcon(isNighttime: true) == "moon.stars.fill")
        #expect(WeatherKit.WeatherCondition.partlyCloudy.systemIcon(isNighttime: true) == "cloud.moon.fill")
        #expect(WeatherKit.WeatherCondition.sunShowers.systemIcon(isNighttime: true) == "cloud.moon.rain.fill")
    }
}
