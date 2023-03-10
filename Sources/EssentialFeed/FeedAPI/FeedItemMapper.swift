//
//  FeedItemMapper.swift
//  
//
//  Created by Brent Mifsud on 2023-02-18.
//

import Foundation

internal final class FeedItemMapper {
	private struct Root: Decodable {
		let items: [Item]
		
		var feed: [FeedItem] {
			items.map(\.asFeedItem)
		}
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
	
	private static var OK_200: Int { 200 }
	
	static func map(_ data: Data, from response: HTTPURLResponse) -> FeedResult {
		guard response.statusCode == OK_200,
			  let root = try? JSONDecoder().decode(Root.self, from: data) else {
			return .failure(RemoteFeedLoader.Error.invalidData)
		}
		
		return .success(root.feed)
	}
}
