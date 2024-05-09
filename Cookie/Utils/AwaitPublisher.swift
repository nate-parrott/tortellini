//import Combine
//
//extension Publisher where Failure == Never {
//  /// Converts publisher to AsyncSequence
//  @available(iOS, deprecated: 15.0, message: "Use publisher.values directly")
//  var valuesAsync: AsyncPublisher<Self> {
//    AsyncPublisher(self)
//  }
//}
//
///// AsyncSequence from a Publisher that never errors.
///// Combine.AsyncPublisher is used when available, otherwise AsyncStream is used.
//@available(iOS, deprecated: 15.0, message: "Use Combine.AsyncPublisher directly")
//struct AsyncPublisher<P>: AsyncSequence where P: Publisher, P.Failure == Never {
//  typealias Element = P.Output
//
//  private let publisher: P
//  init(_ publisher: P) {
//    self.publisher = publisher
//  }
//
//  func makeAsyncIterator() -> Iterator {
//    if #available(iOS 15.0, *) {
//      var iterator = Combine.AsyncPublisher(publisher).makeAsyncIterator()
//      return Iterator { await iterator.next() }
//    } else {
//      var iterator = makeAsyncStream().makeAsyncIterator()
//      return Iterator { await iterator.next() }
//    }
//  }
//
//  struct Iterator: AsyncIteratorProtocol {
//    let _next: () async -> P.Output?
//
//    mutating func next() async -> P.Output? {
//      await _next()
//    }
//  }
//
//  private func makeAsyncStream() -> AsyncStream<Element> {
//    AsyncStream(Element.self, bufferingPolicy: .bufferingOldest(1)) { continuation in
//      publisher.receive(subscriber: Inner(continuation: continuation))
//    }
//  }
//}
//
//private extension AsyncPublisher {
//  final class Inner: Subscriber {
//    typealias Continuation = AsyncStream<Input>.Continuation
//    private var subscription: Subscription?
//    private let continuation: Continuation
//
//    init(continuation: Continuation) {
//      self.continuation = continuation
//      continuation.onTermination = cancel
//    }
//
//    func receive(subscription: Subscription) {
//      self.subscription = subscription
//      subscription.request(.max(1))
//    }
//
//    func receive(_ input: Element) -> Subscribers.Demand {
//      continuation.yield(input)
//      Task {  [subscription] in
//        // Demand for next value is requested asynchronously allowing
//        // synchronous publishers like Publishers.Sequence to yield and suspend.
//        subscription?.request(.max(1))
//      }
//      return .none
//    }
//
//    func receive(completion: Subscribers.Completion<Never>) {
//      subscription = nil
//      continuation.finish()
//    }
//
//    @Sendable
//    func cancel(_: Continuation.Termination) {
//      subscription?.cancel()
//      subscription = nil
//    }
//  }
//}
