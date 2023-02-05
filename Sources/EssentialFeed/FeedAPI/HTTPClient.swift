//
//  HTTPClient.swift
//  
//
//  Created by Brent Mifsud on 2023-02-05.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}
