import Foundation
import MonitorEngine
import SQLite3

/// 基于SQLite的HistoryStore实现，支持持久化历史数据
public final class SQLiteHistoryStore: HistoryStore {
    private let db: OpaquePointer?

    public init(url: URL) throws {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(url.path, &db, flags, nil)
        if result != SQLITE_OK {
            sqlite3_close(db)
            throw HistoryStoreError.openFailed(result)
        }
        self.db = db
        try createTableIfNeeded()
    }

    /// 使用内存数据库（每次调用创建独立数据库，用于测试）
    public init(inMemory: Bool) throws {
        precondition(inMemory, "Use init(url:) for file-based databases")
        var db: OpaquePointer?
        // 使用唯一URI确保每次创建独立的内存数据库
        let uri = "file:memdb-\(UUID().uuidString)?mode=memory&cache=shared"
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_URI | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(uri, &db, flags, nil)
        if result != SQLITE_OK {
            sqlite3_close(db)
            throw HistoryStoreError.openFailed(result)
        }
        self.db = db
        try createTableIfNeeded()
    }

    /// 便利初始化：使用默认路径的文件数据库
    public convenience init() throws {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Silivue", isDirectory: true) else {
            throw HistoryStoreError.openFailed(SQLITE_CANTOPEN)
        }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try self.init(url: dir.appendingPathComponent("history.sqlite"))
    }

    deinit {
        sqlite3_close(db)
    }

    public func insertBatch(_ batchSamples: [AnyMonitorSample]) async throws {
        guard !batchSamples.isEmpty else { return }
        try execute("BEGIN TRANSACTION")
        for sample in batchSamples {
            try insertRaw(sample)
        }
        try execute("COMMIT")
    }

    public func insert(_ sample: AnyMonitorSample) async throws {
        try insertRaw(sample)
    }

    private func insertRaw(_ sample: AnyMonitorSample) throws {
        let sql = """
        INSERT INTO samples (monitor_id, timestamp, sample_type, value_json)
        VALUES (?, ?, ?, ?)
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, sample.monitorID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(stmt, 2, sample.timestamp.timeIntervalSince1970)

        let (sampleType, valueJSON) = try encodeSample(sample)
        sqlite3_bind_text(stmt, 3, sampleType, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_text(stmt, 4, valueJSON, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryStoreError.insertFailed(sqlite3_errcode(db))
        }
    }

    public func query(monitorID: String, from: Date, to: Date) async throws -> [AnyMonitorSample] {
        let sql = """
        SELECT sample_type, value_json FROM samples
        WHERE monitor_id = ? AND timestamp >= ? AND timestamp <= ?
        ORDER BY timestamp ASC
        """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, monitorID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        sqlite3_bind_double(stmt, 2, from.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 3, to.timeIntervalSince1970)

        var results: [AnyMonitorSample] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let sampleType = String(cString: sqlite3_column_text(stmt, 0))
            let valueJSON = String(cString: sqlite3_column_text(stmt, 1))

            if let sample = try decodeSample(type: sampleType, json: valueJSON) {
                results.append(sample)
            }
        }
        return results
    }

    public func delete(olderThan date: Date) async throws {
        let sql = "DELETE FROM samples WHERE timestamp < ?"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_double(stmt, 1, date.timeIntervalSince1970)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryStoreError.deleteFailed(sqlite3_errcode(db))
        }
    }

    public func sampleCount(monitorID: String) async throws -> Int {
        let sql = "SELECT COUNT(*) FROM samples WHERE monitor_id = ?"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, monitorID, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    // MARK: - Private

    private func createTableIfNeeded() throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS samples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            monitor_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            sample_type TEXT NOT NULL,
            value_json TEXT NOT NULL
        )
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryStoreError.createTableFailed(sqlite3_errcode(db))
        }

        // 创建索引加速查询
        let indexSQL = "CREATE INDEX IF NOT EXISTS idx_samples_monitor_timestamp ON samples(monitor_id, timestamp)"
        var indexStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, indexSQL, -1, &indexStmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(indexStmt) }
        guard sqlite3_step(indexStmt) == SQLITE_DONE else {
            throw HistoryStoreError.createTableFailed(sqlite3_errcode(db))
        }
    }

    private func encodeSample(_ sample: AnyMonitorSample) throws -> (String, String) {
        let encoder = JSONEncoder()
        let data: Data
        let type: String

        if let cpu = sample.cpu {
            data = try encoder.encode(cpu)
            type = "cpu"
        } else if let mem = sample.memory {
            data = try encoder.encode(mem)
            type = "memory"
        } else if let net = sample.network {
            data = try encoder.encode(net)
            type = "network"
        } else if let disk = sample.disk {
            data = try encoder.encode(disk)
            type = "disk"
        } else if let bat = sample.battery {
            data = try encoder.encode(bat)
            type = "battery"
        } else if let temp = sample.temperature {
            data = try encoder.encode(temp)
            type = "temperature"
        } else if let proc = sample.process {
            data = try encoder.encode(proc)
            type = "process"
        } else {
            throw HistoryStoreError.unsupportedSampleType
        }

        guard let json = String(data: data, encoding: .utf8) else {
            throw HistoryStoreError.unsupportedSampleType
        }
        return (type, json)
    }

    private func execute(_ sql: String) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw HistoryStoreError.prepareFailed(sqlite3_errcode(db))
        }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw HistoryStoreError.insertFailed(sqlite3_errcode(db))
        }
    }

    private func decodeSample(type: String, json: String) throws -> AnyMonitorSample? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()

        switch type {
        case "cpu":
            let sample = try decoder.decode(CPUSample.self, from: data)
            return AnyMonitorSample(sample)
        case "memory":
            let sample = try decoder.decode(MemorySample.self, from: data)
            return AnyMonitorSample(sample)
        case "network":
            let sample = try decoder.decode(NetworkSample.self, from: data)
            return AnyMonitorSample(sample)
        case "disk":
            let sample = try decoder.decode(DiskSample.self, from: data)
            return AnyMonitorSample(sample)
        case "battery":
            let sample = try decoder.decode(BatterySample.self, from: data)
            return AnyMonitorSample(sample)
        case "temperature":
            let sample = try decoder.decode(TemperatureSample.self, from: data)
            return AnyMonitorSample(sample)
        case "process":
            let sample = try decoder.decode(ProcessSample.self, from: data)
            return AnyMonitorSample(sample)
        default:
            return nil
        }
    }
}

public enum HistoryStoreError: Error, LocalizedError {
    case openFailed(Int32)
    case prepareFailed(Int32)
    case insertFailed(Int32)
    case deleteFailed(Int32)
    case createTableFailed(Int32)
    case unsupportedSampleType

    public var errorDescription: String? {
        switch self {
        case .openFailed(let code): return "Failed to open database (code: \(code))"
        case .prepareFailed(let code): return "Failed to prepare statement (code: \(code))"
        case .insertFailed(let code): return "Failed to insert sample (code: \(code))"
        case .deleteFailed(let code): return "Failed to delete samples (code: \(code))"
        case .createTableFailed(let code): return "Failed to create table (code: \(code))"
        case .unsupportedSampleType: return "Unsupported sample type"
        }
    }
}
