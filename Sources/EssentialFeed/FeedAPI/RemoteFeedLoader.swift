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
				guard httpResponse.statusCode == 200 else {
					completion(.failure(.invalidData))
					return
				}
				
				do {
					let feedItems = try JSONDecoder().decode(Root.self, from: data)
						.items
						.map(\.asFeedItem)
					completion(.success(feedItems))
				} catch {
					completion(.failure(.invalidData))
				}
			case .failure:
				completion(.failure(.connectivity))
			}
		}
	}
}

private struct Root: Decodable {
	let items: [Item]
}

private struct Item: Decodable {
	let id: UUID
	let description: String?
	let location: String?
	let image: URL
	
	var asFeedItem: FeedItem {
		.init(id: id, description: description, location: location, imageURL: image)
	}
}
