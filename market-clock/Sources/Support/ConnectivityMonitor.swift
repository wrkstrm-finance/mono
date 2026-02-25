import Foundation

#if canImport(Network)
import Network
#endif

public final class ConnectivityMonitor: ConnectivityService {
  public let states: AsyncStream<ConnectivityState>
  private let continuation: AsyncStream<ConnectivityState>.Continuation

  #if canImport(Network)
  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "marketclock.connectivity")
  #endif

  public init() {
    var cont: AsyncStream<ConnectivityState>.Continuation!
    self.states = AsyncStream<ConnectivityState> { c in cont = c }
    self.continuation = cont

    #if canImport(Network)
    let contRef = continuation
    monitor.pathUpdateHandler = { path in
      let state: ConnectivityState = (path.status == .satisfied) ? .online : .offline
      contRef.yield(state)
    }
    monitor.start(queue: queue)
    #else
    // Fallback: assume online
    cont.yield(.online)
    #endif
  }
}
