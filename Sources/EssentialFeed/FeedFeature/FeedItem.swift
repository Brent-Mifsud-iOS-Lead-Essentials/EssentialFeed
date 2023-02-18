//
//  FeedItem.swift
//
//
//  Created by Brent Mifsud on 2023-02-04.
//

import Foundation

public struct FeedResponse: Decodable {
	public let items: [FeedItem]
	
	public init(items: [FeedItem]) {
		self.items = items
	}
}

public struct FeedItem: Equatable, Decodable {
	public let id: UUID
	public let description: String?
	public let location: String?
	public let imageURL: URL
	
	public init(id: UUID, description: String?, location: String?, imageURL: URL) {
		self.id = id
		self.description = description
		self.location = location
		self.imageURL = imageURL
	}
	
	private enum CodingKeys: String, CodingKey {
		case id
		case description
		case location
		case imageURL = "image"
	}
}
