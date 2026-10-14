//
//  Logger+App.swift
//  FlightApp
//
//  Shared os.Logger categories. Unlike print, these can be filtered in Console.app
//  and debug-level messages aren't persisted in release builds.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "FlightApp"

    static let claude = Logger(subsystem: subsystem, category: "Claude")
    static let route = Logger(subsystem: subsystem, category: "Route")
    static let awards = Logger(subsystem: subsystem, category: "Awards")
    static let cashFares = Logger(subsystem: subsystem, category: "CashFares")
}
