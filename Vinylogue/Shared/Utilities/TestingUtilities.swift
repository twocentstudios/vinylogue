import Foundation

/// Utility for detecting testing environments
enum TestingUtilities {
    /// Returns true if the app is running in a testing environment
    static var isTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Returns true if the app is running in screenshot testing mode
    static var isScreenshotTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-testing")
    }

    /// Gets test data from launch environment
    static func getTestData<T: Codable>(for key: String, type: T.Type) -> T? {
        guard let jsonString = ProcessInfo.processInfo.environment[key],
              let data = jsonString.data(using: .utf8)
        else {
            return nil
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to decode test data for key \(key): \(error)")
            return nil
        }
    }

    /// Gets string test data from launch environment
    static func getTestString(for key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }
}

/// Global computed property for easy access
var isTesting: Bool {
    TestingUtilities.isTesting
}

/// Global computed property for screenshot testing
var isScreenshotTesting: Bool {
    TestingUtilities.isScreenshotTesting
}
