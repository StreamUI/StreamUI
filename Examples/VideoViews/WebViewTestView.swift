//
//  File.swift
//
//
//  Created by Jordan Howlett on 6/20/24.
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let urlString: String

    func makeNSView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            nsView.load(request)
        }
    }
}

public struct SimpleWebView: View {
    public init() {}
    public var body: some View {
        WebView(urlString: "https://www.apple.com")
    }
}
