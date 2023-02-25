//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Brent Mifsud on 2023-02-20.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
	enum Error: Swift.Error {
		case unknown
	}
	
	private let session: URLSession
	
	init(session: URLSession = .shared) {
		self.session = session
	}
	
	func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
		session.dataTask(with: url) { _, _, error in
			if let error {
				completion(.failure(error))
				return
			} else {
				completion(.failure(Error.unknown))
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
		let requestError = NSError(domain: "any error", code: 1)
		let recievedError = resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
		XCTAssertEqual(recievedError?.domain, requestError.domain)
		XCTAssertEqual(recievedError?.code, requestError.code)
	}
	
	func test_getFromURL_failsOnAllNilValues() {
		let recievedError = resultErrorFor(data: nil, response: nil, error: nil)
		XCTAssertNotNil(recievedError)
		
		guard let clientError = recievedError as? URLSessionHTTPClient.Error else {
			XCTFail("Expected URLSesstionHTTPClient.Error. Got \(String(describing: recievedError))")
			return
		}
		
		XCTAssertEqual(clientError, URLSessionHTTPClient.Error.unknown)
	}
	
	private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
		let sut = URLSessionHTTPClient()
		trackForMemoryLeaks(sut, file: file, line: line)
		return sut
	}
	
	private func resultErrorFor(
		data: Data?,
		response: URLResponse?,
		error: Error?,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> Error? {
		URLProtocolStub.stub(data: data, response: response, error: error)
		
		let exp = expectation(description: "Wait for completion")
		
		var receivedError: Error?
		
		makeSUT().get(from: getAnyURL()) { result in
			switch result {
			case let .failure(error):
				receivedError = error
			default:
				XCTFail("Expected failure, got \(result) instead", file: file, line: line)
			}
			
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1.0)
		return receivedError
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
