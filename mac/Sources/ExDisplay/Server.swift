import Foundation
import Network
import ExDisplayCore

typealias TouchHandler = (UInt8, Float, Float) -> Void

final class Server {
    private var listener: NWListener?
    private var connection: NWConnection?
    private var recvBuf = [UInt8]()   // Array is always 0-based, unlike Data after removeFirst
    private var sentFirstKeyframe = false
    private let queue = DispatchQueue(label: "com.exdisplay.server", qos: .userInteractive)
    private let onTouch: TouchHandler
    private let displayWidth: UInt32
    private let displayHeight: UInt32

    // Called on main thread when a client connects or disconnects
    var onConnectionChanged: ((Bool) -> Void)?
    private(set) var isClientConnected = false

    // Two-finger scroll deltas (pixels). Set by AppController.
    var onScroll: ((Float, Float) -> Void)?

    // Three-finger swipe (direction: 0=L 1=R 2=U 3=D). Set by AppController.
    var onSwipe: ((UInt8) -> Void)?

    // Called on main thread if the listener can't bind (e.g. port already in use)
    var onListenerFailed: ((String) -> Void)?

    // Throughput counters (mutated on `queue`; read via statsSnapshot)
    private var framesSent = 0
    private var bytesSent = 0

    init(width: UInt32, height: UInt32, onTouch: @escaping TouchHandler) {
        self.displayWidth = width
        self.displayHeight = height
        self.onTouch = onTouch
    }

    func start() throws {
        let tcp = NWProtocolTCP.Options()
        tcp.noDelay = true
        let params = NWParameters(tls: nil, tcp: tcp)
        params.allowLocalEndpointReuse = true

        let l = try NWListener(using: params, on: 8888)
        l.newConnectionHandler = { [weak self] conn in self?.queue.async { self?.accept(conn) } }
        l.stateUpdateHandler = { [weak self] state in
            if case .failed(let err) = state {
                log("[Server] Listener failed: \(err.localizedDescription)")
                DispatchQueue.main.async { self?.onListenerFailed?(err.localizedDescription) }
            }
        }
        l.start(queue: queue)
        listener = l
        log("[Server] Listening on 127.0.0.1:8888")
    }

    private func accept(_ conn: NWConnection) {
        connection?.cancel()
        connection = conn
        sentFirstKeyframe = false
        recvBuf.removeAll()
        conn.start(queue: queue)
        log("[Server] Client connected")
        isClientConnected = true
        DispatchQueue.main.async { self.onConnectionChanged?(true) }
        sendDisplayConfig()
        recv()
    }

    private func sendDisplayConfig() {
        guard let conn = connection else { return }
        let bytes = ProtoCodec.encodeConfig(width: displayWidth, height: displayHeight, rotation: 0)
        conn.send(content: Data(bytes), completion: .idempotent)
        log("[Server] Sent display config \(displayWidth)×\(displayHeight) (proto v\(Proto.version))")
    }

    func sendFrame(_ data: Data, isKeyframe: Bool) {
        queue.async { [weak self] in
            guard let self, let conn = self.connection else { return }
            if isKeyframe { self.sentFirstKeyframe = true }
            guard self.sentFirstKeyframe else { return }   // gate until first IDR

            guard ProtoCodec.isValidFrameSize(data.count) else {
                log("[Server] Dropping oversized frame: \(data.count) bytes (cap \(Proto.maxFrameBytes))")
                return
            }
            var msg = Data(ProtoCodec.encodeFrameHeader(payloadCount: data.count))
            msg.append(data)
            conn.send(content: msg, completion: .idempotent)
            self.framesSent += 1
            self.bytesSent += msg.count
        }
    }

    /// Cumulative (framesSent, bytesSent). Read from any thread.
    func statsSnapshot() -> (frames: Int, bytes: Int) {
        queue.sync { (framesSent, bytesSent) }
    }

    private func recv() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, done, err in
            guard let self else { return }
            if let d = data, !d.isEmpty { self.parse(d) }
            if done || err != nil {
                log("[Server] Client disconnected: \(err?.localizedDescription ?? "EOF")")
                self.connection = nil
                self.sentFirstKeyframe = false
                self.isClientConnected = false
                DispatchQueue.main.async { self.onConnectionChanged?(false) }
            } else {
                self.recv()
            }
        }
    }

    private func parse(_ incoming: Data) {
        recvBuf.append(contentsOf: incoming)
        switch ProtoCodec.parseInbound(&recvBuf) {
        case .ok(let messages):
            for m in messages {
                switch m {
                case .touch(let action, let x, let y): onTouch(action, x, y)
                case .scroll(let dx, let dy):          onScroll?(dx, dy)
                case .swipe(let direction):            onSwipe?(direction)
                }
            }
        case .desync:
            log("[Server] Inbound stream desynced — dropping connection")
            recvBuf.removeAll()
            connection?.cancel()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.connection?.cancel()
            self?.listener?.cancel()
        }
    }
}
