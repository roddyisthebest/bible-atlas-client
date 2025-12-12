import XCTest
@testable import BibleAtlas

final class AppInitializerTests: XCTestCase {
    
    private class MockAPIClient: APIClientProtocol {
        var didFetchBooks = false
        var shouldFail = false
        
        func fetchBooks() async throws -> [Book] {
            if shouldFail {
                throw NSError(domain: "TestError", code: 1, userInfo: nil)
            }
            didFetchBooks = true
            return [Book(id: 1, name: "Genesis")]
        }
    }
    
    private class MockSettingsManager: SettingsManagerProtocol {
        var didLoadSettings = false
        func loadSettings() -> Settings {
            didLoadSettings = true
            return Settings(theme: "Dark")
        }
    }
    
    func test_initialize_callsFetchBooksAndLoadsSettings() async throws {
        let mockAPIClient = MockAPIClient()
        let mockSettingsManager = MockSettingsManager()
        let sut = AppInitializer(apiClient: mockAPIClient, settingsManager: mockSettingsManager)
        
        try await sut.initialize()
        
        XCTAssertTrue(mockAPIClient.didFetchBooks, "Expected fetchBooks to be called")
        XCTAssertTrue(mockSettingsManager.didLoadSettings, "Expected loadSettings to be called")
    }
    
    func test_initialize_propagatesAPIClientError() async {
        let mockAPIClient = MockAPIClient()
        mockAPIClient.shouldFail = true
        
        let mockSettingsManager = MockSettingsManager()
        let sut = AppInitializer(apiClient: mockAPIClient, settingsManager: mockSettingsManager)
        
        do {
            try await sut.initialize()
            XCTFail("Expected initialize to throw error when API client fails")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
