//
//  FeedLoader.swift
//  
//
//  Created by Brent Mifsud on 2023-02-04.
//

import Foundation

public enum FeedResult {
	case success([FeedItem])
	case failure(Error)
}

public protocol FeedLoader {
	func load(completion: @escaping (FeedResult) -> Void)
}
