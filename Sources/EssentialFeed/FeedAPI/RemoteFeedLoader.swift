//
//  RemoteFeedLoader.swift
//  
//
//  Created by Brent Mifsud on 2023-02-05.
//

import Foundation
import SwiftUI

public typealias RemoteFeedLoaderResult = Result<[FeedItem], RemoteFeedLoader.Error>
public final class RemoteFeedLoader {
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
	
	public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void) {
		client.get(from: url) { httpClientResponse in
			switch httpClientResponse {
			case let .success((data, httpResponse)):
				completion(FeedItemMapper.map(data, from: httpResponse))
			case .failure:
				completion(.failure(.connectivity))
			}
		}
	}
	
	
}
