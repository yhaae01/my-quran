import SwiftUI
import WidgetKit

// Shared with the Runner target. Enable the App Groups capability for both
// targets and use the same identifier in HomeWidget.setAppGroupId().
private let appGroup = "group.com.example.myQuran.prayer"
private let widgetKind = "PrayerTimesWidget"

private struct PrayerMoment {
  let name: String
  let time: String
  let date: Date
}

private struct PrayerEntry: TimelineEntry {
  let date: Date
  let location: String
  let name: String
  let time: String
  let nextPrayer: Date?
  let isPlaceholder: Bool
}

private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(
      date: Date(),
      location: "Jakarta",
      name: "Subuh",
      time: "04:32",
      nextPrayer: Date().addingTimeInterval(3600),
      isPlaceholder: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(currentEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let moments = loadMoments()
    let now = Date()
    let upcoming = moments.filter { $0.date > now }

    var entries: [PrayerEntry] = []
    if let first = upcoming.first {
      entries.append(
        PrayerEntry(
          date: now,
          location: locationName(),
          name: first.name,
          time: first.time,
          nextPrayer: first.date,
          isPlaceholder: false
        )
      )
    }
    for moment in upcoming.prefix(12) {
      entries.append(
        PrayerEntry(
          date: moment.date,
          location: locationName(),
          name: moment.name,
          time: moment.time,
          nextPrayer: moment.date,
          isPlaceholder: false
        )
      )
    }

    if entries.isEmpty {
      entries.append(currentEntry())
    }

    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func currentEntry() -> PrayerEntry {
    let moments = loadMoments()
    let next = moments.first { $0.date > Date() }
    return PrayerEntry(
      date: Date(),
      location: locationName(),
      name: next?.name ?? "Waktu shalat",
      time: next?.time ?? "--:--",
      nextPrayer: next?.date,
      isPlaceholder: false
    )
  }

  private func locationName() -> String {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: "prayer_widget_payload"),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return "Al-Qur'an" }
    return json["location"] as? String ?? "Al-Qur'an"
  }

  private func loadMoments() -> [PrayerMoment] {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: "prayer_widget_payload"),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let moments = json["moments"] as? [[String: Any]]
    else { return [] }

    return moments.compactMap { item in
      guard
        let name = item["label"] as? String,
        let time = item["time"] as? String,
        let epoch = item["epochMs"] as? Double
      else { return nil }
      return PrayerMoment(
        name: name,
        time: time,
        date: Date(timeIntervalSince1970: epoch / 1000)
      )
    }.sorted { $0.date < $1.date }
  }
}

private struct PrayerTimesWidgetEntryView: View {
  var entry: PrayerEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(entry.location)
        .font(.system(size: 11))
        .foregroundStyle(Color(red: 0.73, green: 0.87, blue: 0.83))
        .lineLimit(1)

      Text(entry.name)
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(Color(red: 0.94, green: 0.83, blue: 0.54))

      HStack(alignment: .lastTextBaseline, spacing: 10) {
        Text(entry.time)
          .font(.system(size: 30, weight: .bold))
          .foregroundStyle(Color(red: 1.0, green: 0.98, blue: 0.95))

        if let next = entry.nextPrayer {
          VStack(alignment: .leading, spacing: 0) {
            Text("menuju adzan")
              .font(.system(size: 9))
              .foregroundStyle(Color(red: 0.73, green: 0.87, blue: 0.83))
            Text(next, style: .timer)
              .font(.system(size: 14, weight: .semibold, design: .rounded))
              .foregroundStyle(Color(red: 1.0, green: 0.98, blue: 0.95))
          }
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(16)
    .containerBackground(
      LinearGradient(
        colors: [
          Color(red: 0.06, green: 0.36, blue: 0.31),
          Color(red: 0.04, green: 0.25, blue: 0.21),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ),
      for: .widget
    )
  }
}

@main
struct PrayerTimesWidget: Widget {
  let kind: String = widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerTimesWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Waktu Shalat")
    .description("Waktu shalat berikutnya dan hitung mundur adzan.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
