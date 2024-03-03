//
//  ContentView.swift
//  CircuitBreaker
//
//  Created by Shashwat Kashyap on 03/03/24.
//

import SwiftUI
import Observation
import Combine

struct ContentView: View {
    // Ideally it should be injected just for testing
    @State private var viewModel = ViewModel()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

// Ideally VM should not be handling the retry/cricuit breaking, it is reponsibility of APIClient but just for testing purpose
@Observable
class ViewModel {
    
    let retryQueue = RetryQueue()
    
    func doFetchResource(_ request: URLRequest, handler: @escaping (Data?) -> Void ) {
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            //Can also check status code in 200...300
            guard error == nil, response != nil else {
                self?.retryQueue.add(request, handler: handler)
                return
            }
            
            // Normal flow / Happy flow
        }
    }
}

class RetryQueue {
    typealias Handler = (Data?) -> Void
    
    // Ordered Map Ideally
    var trackingMap: [URLRequest: Int] = [:]
    var handlers: [URLRequest: Handler] = [:]
    
    let timer = Timer.publish(every: 15, on: .current, in: .common).autoconnect()
    var cancellable: AnyCancellable?
    
    
    init() {
        self.cancellable = timer.sink(receiveValue: { _ in
            
        })
    }
    
    func add(_ request: URLRequest, handler: @escaping Handler) {
        guard trackingMap[request] != nil else {
            trackingMap[request] = 0
            handlers[request] = handler
            return
        }
        
        trackingMap[request] =  trackingMap[request, default: 0] + 1
    }
    
    func cancel(_ request: URLRequest) {
        trackingMap.removeValue(forKey: request)
    }
}
