//
//  EssentialFeedAPIEndToEndTests.swift
//  
//
//  Created by Brent Mifsud on 2023-02-25.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {
	
	func test_endToEndTestServerGetFeedResult_matchesFixedTestAccountData() {
		switch getFeedResult() {
		case let .some(.success(items)):
			XCTAssertEqual(items.count, 8, "Expected 8 items in the test account feed")
			XCTAssertEqual(items[0], expectedItem(at: 0))
			XCTAssertEqual(items[1], expectedItem(at: 1))
			XCTAssertEqual(items[2], expectedItem(at: 2))
			XCTAssertEqual(items[3], expectedItem(at: 3))
			XCTAssertEqual(items[4], expectedItem(at: 4))
			XCTAssertEqual(items[5], expectedItem(at: 5))
			XCTAssertEqual(items[6], expectedItem(at: 6))
			XCTAssertEqual(items[7], expectedItem(at: 7))
		case let .some(.failure(error)):
			XCTFail("Expected successful feed result, got \(error) instead")
		case .none:
			XCTFail("Expected successful feed result, got no result instead")
		}
	}
	
	// MARK: - Helpers
	
	private func getFeedResult() -> RemoteFeedLoader.Result? {
		let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
		let client = URLSessionHTTPClient()
		let loader = RemoteFeedLoader(url: testServerURL, client: client)
		
		let exp = expectation(description: "wait for load completion")
		
		var receivedResult: RemoteFeedLoader.Result?
		
		loader.load { result in
			receivedResult = result
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 5)
		
		return receivedResult
	}
	
	private func expectedItem(at index: Int) -> FeedItem {
		return Self.testItems[index]
	}
	
	private static let testItems = [
		FeedItem(id: UUID(uuidString: "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6")!, description: "Description 1", location: "Location 1", imageURL: URL(string: "https://url-1.com")!),
		FeedItem(id: UUID(uuidString: "BA298A85-6275-48D3-8315-9C8F7C1CD109")!, description: nil, location: "Location 2", imageURL: URL(string: "https://url-2.com")!),
		FeedItem(id: UUID(uuidString: "5A0D45B3-8E26-4385-8C5D-213E160A5E3C")!, description: "Description 3", location: nil, imageURL: URL(string: "https://url-3.com")!),
		FeedItem(id: UUID(uuidString: "FF0ECFE2-2879-403F-8DBE-A83B4010B340")!, description: nil, location: nil, imageURL: URL(string: "https://url-4.com")!),
		FeedItem(id: UUID(uuidString: "DC97EF5E-2CC9-4905-A8AD-3C351C311001")!, description: "Description 5", location: "Location 5", imageURL: URL(string: "https://url-5.com")!),
		FeedItem(id: UUID(uuidString: "557D87F1-25D3-4D77-82E9-364B2ED9CB30")!, description: "Description 6", location: "Location 6", imageURL: URL(string: "https://url-6.com")!),
		FeedItem(id: UUID(uuidString: "A83284EF-C2DF-415D-AB73-2A9B8B04950B")!, description: "Description 7", location: "Location 7", imageURL: URL(string: "https://url-7.com")!),
		FeedItem(id: UUID(uuidString: "F79BD7F8-063F-46E2-8147-A67635C3BB01")!, description: "Description 8", location: "Location 8", imageURL: URL(string: "https://url-8.com")!),
	]
}
