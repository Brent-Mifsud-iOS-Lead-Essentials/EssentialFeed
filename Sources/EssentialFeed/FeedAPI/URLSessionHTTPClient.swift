//
//  URLSessionHTTPClient.swift
//  
//
//  Created by Brent Mifsud on 2023-02-25.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
	public enum Error: Swift.Error {
		case unknown
	}
	
	private let session: URLSession
	
	public init(session: URLSession = .shared) {
		self.session = session
	}
	
	public func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
		session.dataTask(with: url) { data, response, error in
			if let error {
				completion(.failure(error))
			} else if let data, let response = response as? HTTPURLResponse {
				completion(.success((data, response)))
			} else {
				completion(.failure(Error.unknown))
			}
		}.resume()
	}
}
