//
//  HTTPClient.swift
//  
//
//  Created by Brent Mifsud on 2023-02-05.
//

import Foundation

public typealias HTTPClientResult = Result<HTTPURLResponse, Error>

public protocol HTTPClient {
    func get(
        from url: URL,
        completion: @escaping (HTTPClientResult) -> Void
    )
}
