import Foundation

/// Recalculates watering intervals from soil-check outcomes and early/late/snooze behavior.
/// Manual mode ignores learning and uses a fixed interval.
struct ScheduleEngine {
    /// Minimum / maximum adaptive interval bounds (days).
    static let minIntervalDays: Double = 2
    static let maxIntervalDays: Double = 45

    /// Snooze when soil is still moist/wet (days until next check).
    static let moistSnoozeDays: Double = 2
    static let wetSnoozeDays: Double = 3

    /// Learning step when watering early or late vs scheduled due.
    static let earlyLateAdjustment: Double = 0.5

    struct Outcome {
        var nextDueAt: Date
        var intervalDays: Double
        var didWater: Bool
        var snoozeDays: Double?
        var eventKind: CareEventKind
    }

    /// Apply a soil-check result and optionally water.
    /// - Parameters:
    ///   - plant: Current plant schedule state (read-only snapshot fields).
    ///   - moisture: dry / moist / wet.
    ///   - waterIfDry: If true and dry, log watering; if false, treat dry as "check only".
    ///   - now: Injectable clock for tests.
    func applySoilCheck(
        intervalDays: Double,
        baselineIntervalDays: Double,
        scheduleMode: ScheduleMode,
        nextDueAt: Date,
        lastWateredAt: Date?,
        moisture: SoilMoisture,
        waterIfDry: Bool = true,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Outcome {
        switch moisture {
        case .moist:
            let snooze = Self.moistSnoozeDays
            let due = calendar.date(byAdding: .day, value: Int(snooze.rounded()), to: now) ?? now
            return Outcome(
                nextDueAt: due,
                intervalDays: intervalDays,
                didWater: false,
                snoozeDays: snooze,
                eventKind: .snoozed
            )
        case .wet:
            let snooze = Self.wetSnoozeDays
            let due = calendar.date(byAdding: .day, value: Int(snooze.rounded()), to: now) ?? now
            // Slightly lengthen adaptive interval — plant stays wet longer than expected.
            var newInterval = intervalDays
            if scheduleMode == .adaptive {
                newInterval = clamp(intervalDays + Self.earlyLateAdjustment)
            }
            return Outcome(
                nextDueAt: due,
                intervalDays: newInterval,
                didWater: false,
                snoozeDays: snooze,
                eventKind: .snoozed
            )
        case .dry:
            if waterIfDry {
                return applyWatering(
                    intervalDays: intervalDays,
                    scheduleMode: scheduleMode,
                    nextDueAt: nextDueAt,
                    lastWateredAt: lastWateredAt,
                    now: now,
                    calendar: calendar
                )
            } else {
                // Checked dry but chose not to water — remind tomorrow.
                let due = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                return Outcome(
                    nextDueAt: due,
                    intervalDays: intervalDays,
                    didWater: false,
                    snoozeDays: 1,
                    eventKind: .soilCheck
                )
            }
        }
    }

    /// Log a watering (after dry soil or explicit water). Adapts interval for early/late.
    func applyWatering(
        intervalDays: Double,
        scheduleMode: ScheduleMode,
        nextDueAt: Date,
        lastWateredAt: Date?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Outcome {
        var newInterval = intervalDays

        if scheduleMode == .adaptive {
            // Compare actual watering time to scheduled due.
            let secondsEarly = nextDueAt.timeIntervalSince(now)
            let daysDelta = secondsEarly / 86_400
            if daysDelta > 0.75 {
                // Watered early → shorten interval
                newInterval = clamp(intervalDays - Self.earlyLateAdjustment)
            } else if daysDelta < -0.75 {
                // Watered late → lengthen interval
                newInterval = clamp(intervalDays + Self.earlyLateAdjustment)
            }
        }

        let days = Int(max(1, newInterval.rounded()))
        let due = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return Outcome(
            nextDueAt: due,
            intervalDays: newInterval,
            didWater: true,
            snoozeDays: nil,
            eventKind: .watered
        )
    }

    /// Explicit snooze from Due Today without full soil flow (still OK; soil sheet preferred).
    func applySnooze(
        intervalDays: Double,
        days: Int = 1,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Outcome {
        let due = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return Outcome(
            nextDueAt: due,
            intervalDays: intervalDays,
            didWater: false,
            snoozeDays: Double(days),
            eventKind: .snoozed
        )
    }

    /// Manual override: lock to exact N days from now (or from last watered).
    func applyManualOverride(
        everyDays: Int,
        from now: Date = Date(),
        calendar: Calendar = .current
    ) -> (intervalDays: Double, nextDueAt: Date, mode: ScheduleMode) {
        let clamped = max(1, min(Int(Self.maxIntervalDays), everyDays))
        let due = calendar.date(byAdding: .day, value: clamped, to: now) ?? now
        return (Double(clamped), due, .manual)
    }

    /// Switch back to adaptive using current interval as baseline.
    func switchToAdaptive(currentInterval: Double) -> (intervalDays: Double, mode: ScheduleMode) {
        (clamp(currentInterval), .adaptive)
    }

    func clamp(_ value: Double) -> Double {
        min(Self.maxIntervalDays, max(Self.minIntervalDays, value))
    }
}

// MARK: - Plant mutation helpers (SwiftData)

extension ScheduleEngine {
    @MainActor
    func applySoilCheck(to plant: Plant, moisture: SoilMoisture, performedBy: String, waterIfDry: Bool = true) -> CareEvent {
        let before = plant.intervalDays
        let outcome = applySoilCheck(
            intervalDays: plant.intervalDays,
            baselineIntervalDays: plant.baselineIntervalDays,
            scheduleMode: plant.scheduleMode,
            nextDueAt: plant.nextDueAt,
            lastWateredAt: plant.lastWateredAt,
            moisture: moisture,
            waterIfDry: waterIfDry
        )
        plant.lastSoilMoisture = moisture
        plant.intervalDays = outcome.intervalDays
        plant.nextDueAt = outcome.nextDueAt
        plant.updatedAt = Date()
        if outcome.didWater {
            plant.lastWateredAt = Date()
            plant.lastWateredBy = performedBy
        }
        let event = CareEvent(
            kind: outcome.eventKind,
            performedBy: performedBy,
            soilMoisture: moisture,
            note: outcome.snoozeDays.map { "Snoozed \($0) day(s)" },
            intervalBefore: before,
            intervalAfter: outcome.intervalDays,
            plant: plant
        )
        plant.careEvents.append(event)
        return event
    }

    @MainActor
    func applyManualOverride(to plant: Plant, everyDays: Int) {
        let result = applyManualOverride(everyDays: everyDays)
        plant.scheduleMode = result.mode
        plant.intervalDays = result.intervalDays
        plant.baselineIntervalDays = result.intervalDays
        plant.nextDueAt = result.nextDueAt
        plant.updatedAt = Date()
    }
}
