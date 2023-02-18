//
//  RemoteFeedLoader.swift
//  
//
//  Created by Brent Mifsud on 2023-02-05.
//

import Foundation
import SwiftUI

public final class RemoteFeedLoader: FeedLoader {
	public typealias Result = FeedResult
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
	
	private let url: URL
	private let client: HTTPClient
	
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (Result) -> Void) {
		client.get(from: url) { [weak self] httpClientResponse in
			guard self != nil else { return }
			
			switch httpClientResponse {
			case let .success((data, httpResponse)):
				completion(FeedItemMapper.map(data, from: httpResponse))
			case .failure:
				completion(.failure(Error.connectivity))
			}
		}
	}
}
