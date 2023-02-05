//
//  RemoteFeedLoaderTest.swift
//  
//
//  Created by Brent Mifsud on 2023-02-04.
//

import XCTest

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "https://a-url.com")
    }
}

class HTTPClient {
    static let shared = HTTPClient()
    private init() {}
    var requestedURL: URL?
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        // Arrange
        let client = HTTPClient.shared
        let sut = RemoteFeedLoader()
        // Act
        sut.load()
        // Assert
        XCTAssertNotNil(client.requestedURL)
    }

}
