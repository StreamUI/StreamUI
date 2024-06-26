//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import Foundation

extension Duration {
    var inMilliseconds: Double {
        let v = components
        return Double(v.seconds) * 1000 + Double(v.attoseconds) * 1e-15
    }
}
