import Foundation
import SwiftData
import UniformTypeIdentifiers

/// CSV export of care log for power users (Pro feature).
struct ExportService {
    struct CareLogRow: Sendable {
        var plantNickname: String
        var kind: String
        var timestamp: Date
        var performedBy: String
        var soilMoisture: String
        var note: String
        var intervalBefore: String
        var intervalAfter: String
    }

    func buildRows(from events: [CareEvent]) -> [CareLogRow] {
        events
            .sorted { $0.timestamp > $1.timestamp }
            .map { event in
                CareLogRow(
                    plantNickname: event.plant?.nickname ?? "",
                    kind: event.kind.displayName,
                    timestamp: event.timestamp,
                    performedBy: event.performedBy,
                    soilMoisture: event.soilMoisture?.displayName ?? "",
                    note: event.note ?? "",
                    intervalBefore: event.intervalBefore.map { String(format: "%.1f" , $0) } ?? "",
                    intervalAfter: event.intervalAfter.map { String(format: "%.1f", $0) } ?? ""
                )
            }
    }

    func csvString(from events: [CareEvent]) -> String {
        let header = "plant,kind,timestamp,performed_by,soil_moisture,note,interval_before_days,interval_after_days"
        let formatter = ISO8601DateFormatter()
        let rows = buildRows(from: events).map { row in
            [
                escape(row.plantNickname),
                escape(row.kind),
                escape(formatter.string(from: row.timestamp)),
                escape(row.performedBy),
                escape(row.soilMoisture),
                escape(row.note),
                escape(row.intervalBefore),
                escape(row.intervalAfter)
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    func writeTempCSV(from events: [CareEvent]) throws -> URL {
        let csv = csvString(from: events)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("watertruth-care-log-\(Int(Date().timeIntervalSince1970)).csv")
        try csv.data(using: .utf8)?.write(to: url)
        return url
    }

    private func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
