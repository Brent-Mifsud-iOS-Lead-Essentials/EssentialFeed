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
	
	init(session: URLSession = .shared) {
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

final class URLSessionHTTPClientTests: XCTestCase {
	override func setUp() {
		super.setUp()
		URLProtocolStub.startInterceptingRequests()
	}
	
	override func tearDown() {
		super.tearDown()
		URLProtocolStub.stopInterceptingRequests()
	}
	
	func test_getFromURL_performsGETRequestWithURL() {
		let url = getAnyURL()
		let exp = expectation(description: "Wait for observer")
		
		URLProtocolStub.observeRequests { request in
			XCTAssertEqual(request.url, url)
			XCTAssertEqual(request.httpMethod, "GET")
			exp.fulfill()
		}
		
		makeSUT().get(from: url, completion: { _ in })
		
		wait(for: [exp], timeout: 1)
	}
	
	func test_getFromURL_failsOnRequestError() {
		let error = NSError(domain: "Test", code: 1)
		URLProtocolStub.stub(data: nil, response: nil, error: error)
		
		let exp = expectation(description: "Wait for completion")
		
		makeSUT().get(from: getAnyURL()) { result in
			switch result {
			case let .failure(receivedError as NSError):
				XCTAssertEqual(receivedError.domain, error.domain)
				XCTAssertEqual(receivedError.code, error.code)
			default:
				XCTFail("Expected failure with error \(error), got \(result) instead")
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1.0)
	}
	
	private func makeSUT() -> URLSessionHTTPClient {
		let sut = URLSessionHTTPClient()
		trackForMemoryLeaks(sut)
		return sut
	}
	
	private func getAnyURL() -> URL {
		return URL(string: "http://any-url.com")!
	}
}

// MARK: - Helpers

private class URLProtocolStub: URLProtocol {
	private struct Stub {
		let data: Data?
		let response: URLResponse?
		let error: Error?
	}
	
	private static var stub: Stub?
	private static var requestObserver: ((URLRequest) -> Void)?
	
	static func stub(data: Data?, response: URLResponse?, error: Error?) {
		stub = Stub(data: data, response: response, error: error)
	}
	
	static func startInterceptingRequests() {
		URLProtocol.registerClass(URLProtocolStub.self)
	}
	
	static func stopInterceptingRequests() {
		URLProtocol.unregisterClass(URLProtocolStub.self)
		stub = nil
		requestObserver = nil
	}
	
	static func observeRequests(observer: @escaping (URLRequest) -> Void) {
		requestObserver = observer
	}
	
	override class func canInit(with request: URLRequest) -> Bool {
		requestObserver?(request)
		return true
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}
	
	override func startLoading() {
		if let data = Self.stub?.data {
			client?.urlProtocol(self, didLoad: data)
		}
		
		if let response = Self.stub?.response {
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
		}
		
		if let error = Self.stub?.error {
			client?.urlProtocol(self, didFailWithError: error)
		}
		
		client?.urlProtocolDidFinishLoading(self)
	}
	
	override func stopLoading() {}
}
