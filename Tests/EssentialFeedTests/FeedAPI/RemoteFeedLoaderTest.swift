//
//  RemoteFeedLoaderTest.swift
//  
//
//  Created by Brent Mifsud on 2023-02-04.
//

import XCTest
import EssentialFeed
import EssentialFeedTestHelpers

// Three As of testing
// Arrange
// Act
// Assert

final class RemoteFeedLoaderTest: XCTestCase {
	func test_init_doesNotRequestDataFromURL() {
		let (_, client) = makeSUT()
		XCTAssertTrue(client.requestedURLs.isEmpty)
	}
	
	func test_load_requestsDataFromURL() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		sut.load { _ in }
		XCTAssertEqual(client.requestedURLs, [url])
	}
	
	func test_loadTwice_requestsDataFromURLTwice() {
		let url = URL(string: "https://a-given-url.com")!
		let (sut, client) = makeSUT(url: url)
		sut.load { _ in }
		sut.load { _ in }
		XCTAssertEqual(client.requestedURLs.count, 2)
		XCTAssertEqual(client.requestedURLs, [url, url])
	}
	
	func test_load_deliversErrorOnClientError() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: failure(.connectivity)) {
			let clientError = NSError(domain: "Test", code: 0)
			client.complete(with: clientError)
		}
	}
	
	func test_load_deliversErrorOnNon200HTTPResponse() {
		let (sut, client) = makeSUT()
		
		let samples = [199, 201, 300, 400, 500]
		
		samples.enumerated().forEach { (index, statusCode) in
			expect(sut, toCompleteWith: failure(.invalidData)) {
				client.complete(
					withStatusCode: statusCode,
					data: makeItemsJSON([]),
					at: index
				)
			}
		}
	}
	
	func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: failure(.invalidData)) {
			let invalidJSON = "invalid json".data(using: .utf8)!
			client.complete(withStatusCode: 200, data: invalidJSON)
		}
	}
	
	func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
		let (sut, client) = makeSUT()
		
		expect(sut, toCompleteWith: .success([])) {
			client.complete(withStatusCode: 200, data: makeItemsJSON([]), at: 0)
		}
	}
	
	func test_load_deliversFeedItemsOn200HTTPResponseWithJSONItems() {
		let (sut, client) = makeSUT()
		
		let feedItems = [
			FeedItem(id: .init(), description: nil, location: nil, imageURL: URL(string: "http://a-url.com")!),
			FeedItem(id: .init(), description: "A description", location: nil, imageURL: URL(string: "http://a-url.com")!),
			FeedItem(id: .init(), description: nil, location: "A location", imageURL: URL(string: "http://a-url.com")!),
			FeedItem(id: .init(), description: "A description", location: "A location", imageURL: URL(string: "http://a-url.com")!),
		]
		
		expect(sut, toCompleteWith: .success(feedItems)) {
			let jsonData = makeItemsJSON(feedItems)
			client.complete(withStatusCode: 200, data: jsonData, at: 0)
		}
	}
	
	func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
		let url = URL(string: "http://any-url.com")!
		let client = HTTPClientSpy()
		var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
		
		var capturedResults = [RemoteFeedLoader.Result]()
		sut?.load(completion: { capturedResults.append($0) })
		
		sut = nil
		client.complete(withStatusCode: 200, data: makeItemsJSON([]))
		
		XCTAssertTrue(capturedResults.isEmpty)
	}
	
	// MARK: - Helpers
	
	private func makeSUT(
		url: URL = URL(string: "https://a-url.com")!,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
		let client = HTTPClientSpy()
		let sut = RemoteFeedLoader(url: url, client: client)
		
		trackForMemoryLeaks(sut, file: file, line: line)
		trackForMemoryLeaks(client, file: file, line: line)
		
		return (sut: sut, client: client)
	}
	
	private func expect(
		_ sut: RemoteFeedLoader,
		toCompleteWith expectedResult: RemoteFeedLoader.Result,
		file: StaticString = #filePath,
		line: UInt = #line,
		when action: () -> Void
	) {
		let exp = expectation(description: "Wait for load completion")
		
		sut.load { receivedResult in
			switch (receivedResult, expectedResult) {
			case let (.success(receivedItems), .success(expectedItems)):
				XCTAssertEqual(receivedItems, expectedItems, file: file, line: line)
			case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
				XCTAssertEqual(receivedError, expectedError, file: file, line: line)
			default:
				XCTFail("Expected result: \(expectedResult) got \(receivedResult) instead", file: file, line: line)
			}
			exp.fulfill()
		}
		
		action()
		
		waitForExpectations(timeout: 2)
	}
	
	private func makeItemsJSON(_ feedItems: [FeedItem]) -> Data {
		try! JSONSerialization.data(withJSONObject: ["items": feedItems.map(\.asDictionary)])
	}
	
	private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
		.failure(error)
	}
}

extension FeedItem {
	var asDictionary: [String: Any] {
		[
			"id": id.uuidString,
			"description": description,
			"location": location,
			"image": imageURL.absoluteString
		].compactMapValues { $0 }
	}
}

private class HTTPClientSpy: HTTPClient {
	typealias Message = (
		url: URL,
		completion: (HTTPClientResult) -> Void
	)
	private var messages = [Message]()
	
	var requestedURLs: [URL] {
		messages.map(\.url)
	}
	
	func get(
		from url: URL,
		completion: @escaping (HTTPClientResult) -> Void
	) {
		messages.append(Message(url: url, completion: completion))
	}
	
	func complete(with error: Error, at index: Int = 0) {
		messages[index].completion(.failure(error))
	}
	
	func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
		let httpResponse = HTTPURLResponse(
			url: requestedURLs[index],
			statusCode: statusCode,
			httpVersion: nil,
			headerFields: nil
		)!
		
		messages[index].completion(.success((data, httpResponse)))
	}
}
