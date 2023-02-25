//
//  URLSessionHTTPClientTests.swift
//  
//
//  Created by Brent Mifsud on 2023-02-20.
//

import XCTest
import EssentialFeed

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
		let url = anyURL()
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
		let requestError = anyNSError()
		
		let recievedError = resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
		
		XCTAssertEqual(recievedError?.domain, requestError.domain)
		XCTAssertEqual(recievedError?.code, requestError.code)
	}
	
	func test_getFromURL_failsOnAllInvalidRepresentationCases() {
		XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
		XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse(), error: nil))
		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
		XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
		XCTAssertNotNil(resultErrorFor(data: nil, response: anyURLResponse(), error: anyNSError()))
		XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
		XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyURLResponse(), error: anyNSError()))
		XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
		XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyURLResponse(), error: nil))
	}
	
	func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
		let data = anyData()
		let response = anyHTTPURLResponse()
		
		let recievedResponse = resultValuesFor(data: data, response: response, error: nil)
		
		XCTAssertEqual(recievedResponse?.data, data)
		XCTAssertEqual(recievedResponse?.response.url, response.url)
		XCTAssertEqual(recievedResponse?.response.statusCode, response.statusCode)
	}
	
	func test_getFromURL_suceedsOnHTTPURLResponseWithNilData() {
		let response = anyHTTPURLResponse()
		
		let recievedResponse = resultValuesFor(data: nil, response: response, error: nil)
		
		let emptyData = Data()
		XCTAssertEqual(recievedResponse?.data, emptyData)
		XCTAssertEqual(recievedResponse?.response.url, response.url)
		XCTAssertEqual(recievedResponse?.response.statusCode, response.statusCode)
	}
	
	// MARK: - Helpers
	
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
		switch resultFor(data: data, response: response, error: error, file: file, line: line) {
		case let .success(result):
			XCTFail("Expected failure, got \(result) instead", file: file, line: line)
			return nil
		case let .failure(error):
			return error
		}
	}
	
	private func resultValuesFor(
		data: Data?,
		response: URLResponse?,
		error: Error?,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> (data: Data, response: HTTPURLResponse)? {
		switch resultFor(data: data, response: response, error: error, file: file, line: line) {
		case let .success(response):
			return response
		case let .failure(error):
			XCTFail("Expected success, got \(error) instead", file: file, line: line)
			return nil
		}
	}
	
	private func resultFor(
		data: Data?,
		response: URLResponse?,
		error: Error?,
		file: StaticString = #filePath,
		line: UInt = #line
	) -> HTTPClientResult {
		URLProtocolStub.stub(data: data, response: response, error: error)
		
		let exp = expectation(description: "Wait for completion")
		
		var receivedResult: HTTPClientResult!
		
		makeSUT().get(from: anyURL()) { result in
			receivedResult = result
			exp.fulfill()
		}
		
		wait(for: [exp], timeout: 1.0)
		
		return receivedResult
	}
	
	private func anyURL() -> URL {
		URL(string: "http://any-url.com")!
	}
	
	private func anyData() -> Data {
		Data(repeating: 5, count: 5)
	}
	
	private func anyNSError() -> NSError {
		NSError(domain: "any error", code: 0)
	}
	
	private func anyURLResponse() -> URLResponse {
		URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
	}
	
	private func anyHTTPURLResponse() -> HTTPURLResponse {
		HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
	}
	
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
}
