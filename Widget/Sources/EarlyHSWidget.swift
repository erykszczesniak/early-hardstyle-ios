import Core
import Services
import SwiftUI
import WidgetKit

/// "Set of the day": a deterministic daily pick from the seeded catalogue.
/// Tapping the widget deep-links straight into playback.
struct SetOfTheDayEntry: TimelineEntry {
    let date: Date
    let title: String
    let eventLine: String
    let bpm: Int?
    let deepLink: URL?
}

struct SetOfTheDayProvider: TimelineProvider {
    func placeholder(in _: Context) -> SetOfTheDayEntry {
        entry(for: .now)
    }

    func getSnapshot(in _: Context, completion: @escaping (SetOfTheDayEntry) -> Void) {
        completion(entry(for: .now))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<SetOfTheDayEntry>) -> Void) {
        // One entry per day for the coming week; the pick rotates by day-of-year.
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        let entries = (0 ..< 7).compactMap { offset -> SetOfTheDayEntry? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return entry(for: day)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> SetOfTheDayEntry {
        let catalog = SeedCatalog.catalog
        guard !catalog.sets.isEmpty else {
            return SetOfTheDayEntry(date: date, title: "EarlyHS", eventLine: "", bpm: nil, deepLink: nil)
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let set = catalog.sets[dayOfYear % catalog.sets.count]
        let event = catalog.event(for: set)?.name ?? ""
        return SetOfTheDayEntry(
            date: date,
            title: set.title,
            eventLine: "\(event) · \(set.year)",
            bpm: set.bpm,
            deepLink: DeepLink.play(setID: set.id).url
        )
    }
}

struct SetOfTheDayView: View {
    let entry: SetOfTheDayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SET OF THE DAY")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(Color(red: 0.61, green: 0.64, blue: 0.69))

            Spacer(minLength: 0)

            Text(entry.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(3)

            HStack {
                Text(entry.eventLine)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.61, green: 0.64, blue: 0.69))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let bpm = entry.bpm {
                    Text("\(bpm) BPM")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.38, green: 0.65, blue: 0.98))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.05),
                    Color(red: 0.09, green: 0.19, blue: 0.53)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(entry.deepLink)
    }
}

@main
struct EarlyHSWidgetBundle: WidgetBundle {
    var body: some Widget {
        SetOfTheDayWidget()
    }
}

struct SetOfTheDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SetOfTheDay", provider: SetOfTheDayProvider()) { entry in
            SetOfTheDayView(entry: entry)
        }
        .configurationDisplayName("Set of the Day")
        .description("A daily early-hardstyle pick — tap to play.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
