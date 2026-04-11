//
//  DateFormatters.swift
//  SpatialWeather
//
//  Created by Vasishta Atmuri on 2024-11-13.
//
import Foundation

struct DateFormatters {
    static var timeZone: TimeZone = .autoupdatingCurrent {
        didSet {
            hourFormatter.timeZone = timeZone
            weekdayFormatter.timeZone = timeZone
            abbreviatedWeekdayFormatter.timeZone = timeZone
            shortTimeFormatter.timeZone = timeZone
            monthDayFormatter.timeZone = timeZone
        }
    }

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.timeZone = timeZone
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timeZone
        return formatter
    }()

    private static let abbreviatedWeekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.timeZone = timeZone
        return formatter
    }()

    private static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = timeZone
        return formatter
    }()

    private static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        formatter.timeZone = timeZone
        return formatter
    }()

    static func formatHour(_ date: Date) -> String {
        hourFormatter.string(from: date)
    }

    static func formatDay(_ date: Date) -> String {
        weekdayFormatter.string(from: date)
    }

    static func formatAbbreviatedDay(_ date: Date) -> String {
        abbreviatedWeekdayFormatter.string(from: date)
    }

    static func formatShortTime(_ date: Date) -> String {
        shortTimeFormatter.string(from: date)
    }

    static func formatMonthDay(_ date: Date) -> String {
        monthDayFormatter.string(from: date)
    }
}

func formatHour(_ date: Date) -> String {
    DateFormatters.formatHour(date)
}

func formatDay(_ date: Date) -> String {
    DateFormatters.formatDay(date)
}
