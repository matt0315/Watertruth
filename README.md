# Watertruth

**Soil-check-first watering reminders** that adapt when you water early/late — with honest billing, household share + who-watered attribution, and a free tier that still reminds. Not another plant-ID megastore.

## Open on Mac

```bash
# Prerequisites: Xcode 15+, [XcodeGen](https://github.com/yonaskolb/XcodeGen)
brew install xcodegen   # once

cd /path/to/Watertruth
xcodegen generate
open Watertruth.xcodeproj
```

1. Set your **Development Team** on the `Watertruth` and `WatertruthWidget` targets.
2. Enable App Groups `group.studio.botland.watertruth` and (when ready) iCloud container `iCloud.studio.botland.watertruth`.
3. Optionally attach `Watertruth/Resources/Store.storekit` to the Run scheme for StoreKit testing.
4. Run on an iOS 17+ simulator or device. Unit tests: `⌘U` (scheme **Watertruth**).

> Linux CI/box cannot compile this project — scaffold is Xcode-ready SwiftUI sources + `project.yml`.

## Pricing (StoreKit 2)

| SKU | Price | Notes |
| --- | ---: | --- |
| Pro Annual (**primary**) | **$34.99/yr** | Launch **$29.99** OK · **7-day trial** · show end date · day-5 reminder |
| Pro Monthly | **$5.99/mo** | |
| Lifetime (optional) | **$59.99** | |
| **No weekly SKU** | — | Deliberately omitted |

Free: full soil-check **reminders for 7 plants**. Pro: unlimited plants, household share, widget packs, CSV export, seasonal insights.

## MVP must-haves → files

| # | Must-have | Primary files |
| --- | --- | --- |
| 1 | Plant profiles (+ curated species list, not mega-ID) | `Models/Plant.swift`, `Views/AddPlantView.swift`, `Resources/CommonHouseplants.json` |
| 2 | Soil-check-first + “Check soil — {plant}” copy | `Views/SoilCheckFlowView.swift`, `Services/NotificationService.swift` |
| 3 | Adaptive intervals | `Services/ScheduleEngine.swift` |
| 4 | Manual override every N days | `Views/ManualOverrideView.swift` |
| 5 | Secondary fertilize / repot toggles | `Views/PlantDetailView.swift` |
| 6 | Due Today / Upcoming + room filter | `Views/DueTodayView.swift` |
| 7 | Local notifications | `Services/NotificationService.swift` |
| 8 | Home Screen widget | `WatertruthWidget/ThirstyTodayWidget.swift`, `Services/WidgetDataWriter.swift` |
| 9 | Photo journal timeline | `Views/JournalView.swift`, `Models/JournalEntry.swift` |
| 10 | Household share 2–3 (CloudKit stubs) | `Views/HouseholdShareView.swift`, `Services/ShareService.swift` |
| 11 | Who watered / when | `Models/Plant.swift` (`lastWateredBy`), Due Today + detail rows |
| 12 | Season / locale soft adjust | `Services/SeasonAdjuster.swift` |
| 13 | Transparent paywall + Manage Subscription | `Views/PaywallView.swift`, `Services/EntitlementService.swift` |
| 14 | Freemium fence N=7 | `Models/AppConstants.swift`, `EntitlementService`, add-plant gate |
| 15 | Backup / CSV export | `Services/ExportService.swift`, `SettingsView` (+ CloudKit TODO in app entry) |
| 16 | Trust copy | `Theme/WatertruthTheme.swift` (`TrustBanner`), empty states |

**Tests:** `WatertruthTests/ScheduleEngineTests.swift` — soil-check paths, early/late adaptation, manual lock, notification body.

## Out of scope (do not add)

- Mega plant identification / cloud ID
- Disease / pest doctor, AI botanist, expert hotline
- Social feed / community forum
- Hardware soil sensors / Bluetooth pots
- Affiliate shop / Amazon carts
- Android
- Weekly impulse subscription as primary offer
- Plant-sitter marketplace (in-household share only)

## Architecture

SwiftUI + SwiftData (+ CloudKit-ready) + WidgetKit + StoreKit 2 + UserNotifications.

```
Watertruth/
  project.yml          # XcodeGen
  Watertruth/          # App target
  WatertruthWidget/    # WidgetKit extension
  WatertruthTests/     # XCTest
```

## Product constraints (non-negotiable)

- Notifications say **“Check soil — {plant}”** — never bare “Water now”
- Adaptive intervals + always-on manual override
- Who-watered attribution
- Honest annual trial; **no weekly primary SKU**
- Free tier keeps reminders for **N=7** plants
- Household share 2–3 via CloudKit (stubbed until signing)

## License / studio

Botland Studio · Working title Watertruth · Research handoff 2026-09-06

## Botland Studio standards

- Site / contact: https://botland.studio
- Privacy: https://botland.studio/privacy
- Terms: https://botland.studio/terms
- Startup: Botland Studio load screen
- After ~3 days of use: share-with-friends prompt
