//
//  FeedLoader.swift
//  
//
//  Created by Brent Mifsud on 2023-02-04.
//

import Foundation

protocol FeedLoader {
	func load() async throws -> [FeedItem]
}
