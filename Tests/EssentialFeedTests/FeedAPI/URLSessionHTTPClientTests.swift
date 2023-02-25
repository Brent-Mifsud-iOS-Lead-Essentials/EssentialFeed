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
			
		}.resume()
	}
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test_getFromURL_resumesDataTaskWithURL() {
		let url = URL(string: "http://any-url.com")!
		let session = URLSessionSpy()
		let task = URLSessionDataTaskSpy()
		session.stub(url: url, task: task)
		let sut = URLSessionHTTPClient(session: session)
		sut.get(from: url) { _ in }
		XCTAssertEqual(task.resumeCallCount, 1)
	}
}

// MARK: - Helpers

private class URLSessionSpy: URLSession {
	var receivedURLs = [URL]()
	private var stubs = [URL: URLSessionDataTask]()
	
	override init() {}
	
	func stub(url: URL, task: URLSessionDataTask) {
		stubs[url] = task
	}
	
	override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		receivedURLs.append(url)
		return stubs[url] ?? FakeURLSessionDataTask()
	}
}

private class FakeURLSessionDataTask: URLSessionDataTask {
	override func resume() {}
}

private class URLSessionDataTaskSpy: URLSessionDataTask {
	var resumeCallCount: Int = 0
	
	override func resume() {
		resumeCallCount += 1
	}
}
