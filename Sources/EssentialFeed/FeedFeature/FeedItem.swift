//
//  FeedItem.swift
//
//
//  Created by Brent Mifsud on 2023-02-04.
//

import Foundation

public struct FeedItem: Equatable {
	let id: UUID
	let description: String?
	let location: String?
	let imageURL: URL
}
