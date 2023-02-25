//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Brent Mifsud on 2023-02-20.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
	private let session: URLSession
	
	init(session: URLSession) {
		self.session = session
	}
	
	func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
		session.dataTask(with: url) { _, _, _ in
			
		}
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test_getFromURL_createsDataTaskWithURL() {
		let url = URL(string: "http://any-url.com")!
		let session = URLSessionSpy()
		let sut = URLSessionHTTPClient(session: session)
		sut.get(from: url) { _ in }
		
		XCTAssertEqual(session.receivedURLs, [url])
	}
}

// MARK: - Helpers
private class URLSessionSpy: URLSession {
	var receivedURLs = [URL]()
	
	override init() {}
	
	override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		receivedURLs.append(url)
		return FakeURLSessionDataTask()
	}
}

private class FakeURLSessionDataTask: URLSessionDataTask {
	
}
