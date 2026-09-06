import Foundation

/// Soft seasonal templates for US / AU / UK / CA — explainable, not weather-AI magic.
struct SeasonAdjuster {
    enum Hemisphere {
        case northern
        case southern
    }

    /// Rough multiplier applied to adaptive baseline by season.
    /// Winter indoor plants often need less frequent watering.
    func intervalMultiplier(for date: Date = Date(), locale: Locale = .current) -> Double {
        let hemisphere = Self.hemisphere(for: locale)
        let month = Calendar.current.component(.month, from: date)
        let season = Self.season(month: month, hemisphere: hemisphere)
        switch season {
        case .winter: return 1.25
        case .spring: return 1.0
        case .summer: return 0.85
        case .autumn: return 1.05
        }
    }

    func applySoftAdjust(baselineDays: Double, date: Date = Date(), locale: Locale = .current) -> Double {
        let adjusted = baselineDays * intervalMultiplier(for: date, locale: locale)
        return ScheduleEngine().clamp(adjusted)
    }

    func explanation(locale: Locale = .current, date: Date = Date()) -> String {
        let hemisphere = Self.hemisphere(for: locale)
        let month = Calendar.current.component(.month, from: date)
        let season = Self.season(month: month, hemisphere: hemisphere)
        let region = locale.region?.identifier ?? "your region"
        return "Soft \(season.rawValue) adjust for \(region) (\(hemisphere == .southern ? "southern" : "northern") hemisphere). Guide only — always feel the soil."
    }

    // MARK: - Helpers

    enum Season: String {
        case winter, spring, summer, autumn
    }

    static func hemisphere(for locale: Locale) -> Hemisphere {
        let region = locale.region?.identifier.uppercased() ?? ""
        // AU / NZ / ZA / parts of SA — southern; default northern for US/UK/CA.
        let southern: Set<String> = ["AU", "NZ", "ZA", "AR", "CL", "UY", "BR"]
        return southern.contains(region) ? .southern : .northern
    }

    static func season(month: Int, hemisphere: Hemisphere) -> Season {
        // Meteorological seasons
        let northern: Season
        switch month {
        case 12, 1, 2: northern = .winter
        case 3, 4, 5: northern = .spring
        case 6, 7, 8: northern = .summer
        default: northern = .autumn
        }
        if hemisphere == .northern { return northern }
        // Flip for southern
        switch northern {
        case .winter: return .summer
        case .spring: return .autumn
        case .summer: return .winter
        case .autumn: return .spring
        }
    }
}
