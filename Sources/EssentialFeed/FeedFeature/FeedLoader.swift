//
//  FeedLoader.swift
//  
//
//  Created by Brent Mifsud on 2023-02-04.
//

import Foundation

public enum FeedResult<Error: Swift.Error> {
	case success([FeedItem])
	case failure(Error)
}

extension FeedResult: Equatable where Error: Equatable {}

public protocol FeedLoader {
	associatedtype Error: Swift.Error
	func load(completion: @escaping (FeedResult<Error>) -> Void)
}
