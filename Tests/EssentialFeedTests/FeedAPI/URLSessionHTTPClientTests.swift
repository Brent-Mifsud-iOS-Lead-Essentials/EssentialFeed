//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Brent Mifsud on 2023-02-20.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
	private let session: HTTPSession
	
	init(session: HTTPSession) {
		self.session = session
	}
	
	func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
		session.dataTask(with: url) { _, _, error in
			if let error {
				completion(.failure(error))
				return
			}
		}.resume()
	}
}

protocol HTTPSession {
	func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
	func resume()
}

final class URLSessionHTTPClientTests: XCTestCase {
	func test_getFromURL_resumesDataTaskWithURL() {
		let url = URL(string: "http://any-url.com")!
		let session = HTTPSessionSpy()
		let task = HTTPSessionTaskSpy()
		session.stub(url: url, task: task)
		let sut = URLSessionHTTPClient(session: session)
		sut.get(from: url) { _ in }
		
		XCTAssertEqual(task.resumeCallCount, 1)
	}
	
	func test_getFromURL_failsOnRequestError() {
		let url = URL(string: "http://any-url.com")!
		let error = NSError(domain: "Test", code: 1)
		let session = HTTPSessionSpy()
		let task = HTTPSessionTaskSpy()
		session.stub(url: url, task: task, error: error)
		let sut = URLSessionHTTPClient(session: session)
		
		let exp = expectation(description: "Wait for completion")
		
		sut.get(from: url) { result in
			switch result {
			case let .failure(recievedError as NSError):
				XCTAssertEqual(error, recievedError)
			default:
				XCTFail("Expected failure with error \(error), got \(result) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1.0)
	}
}

// MARK: - Helpers

private class HTTPSessionSpy: HTTPSession {
	private struct Stub {
		let task: HTTPSessionTask
		let error: Error?
	}
	
	private var stubs = [URL: Stub]()
	
	
	func stub(url: URL, task: HTTPSessionTask, error: Error? = nil) {
		stubs[url] = Stub(task: task, error: error)
	}
	
	func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
		guard let stub = stubs[url] else {
			fatalError("Couldn't find stub for \(url)", file: #filePath, line: #line)
		}
		
		completionHandler(nil, nil, stub.error)
		return stub.task
	}
}

private class HTTPSessionTaskSpy: HTTPSessionTask {
	var resumeCallCount: Int = 0
	
	func resume() {
		resumeCallCount += 1
	}
}
