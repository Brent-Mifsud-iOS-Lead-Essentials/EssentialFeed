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
	
	internal static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
		guard response.statusCode == OK_200 else {
			throw RemoteFeedLoader.Error.invalidData
		}
		
		return try JSONDecoder().decode(Root.self, from: data)
			.items
			.map(\.asFeedItem)
	}
}
