import SwiftUI
import WidgetKit

// Shared with the Runner target. Enable the App Groups capability for both
// targets and use the same identifier in HomeWidget.setAppGroupId().
private let appGroup = "group.com.example.myQuran.prayer"
private let widgetKind = "PrayerTimesWidget"

private struct PrayerMoment: Identifiable {
  let key: String
  let name: String
  let time: String
  let date: Date

  var id: String { "\(key)-\(date.timeIntervalSince1970)" }
}

private struct PrayerDay {
  let hijri: String
  let prayers: [PrayerMoment]
}

private struct PrayerPayload {
  let location: String
  let hijri: String
  let days: [PrayerDay]
  let moments: [PrayerMoment]
}

private struct PrayerEntry: TimelineEntry {
  let date: Date
  let location: String
  let hijri: String
  let prayers: [PrayerMoment]
  let next: PrayerMoment?
  let isPlaceholder: Bool
}

private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    let prayers = placeholderPrayers()
    return PrayerEntry(
      date: Date(),
      location: "Jakarta",
      hijri: "15 Jumadil Awal 1448 H",
      prayers: prayers,
      next: prayers.first,
      isPlaceholder: true
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(entry(at: Date(), payload: loadPayload()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let payload = loadPayload()
    let now = Date()
    let calendar = Calendar.current

    var dates: Set<Date> = [now]
    if let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
      dates.insert(midnight)
    }
    for moment in payload.moments.filter({ $0.date > now }).prefix(15) {
      // One second after the adhan so the countdown rolls to the next prayer.
      dates.insert(moment.date.addingTimeInterval(1))
    }

    let entries = dates.sorted().map { entry(at: $0, payload: payload) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func entry(at date: Date, payload: PrayerPayload) -> PrayerEntry {
    PrayerEntry(
      date: date,
      location: payload.location,
      hijri: hijri(for: date, payload: payload),
      prayers: prayers(for: date, payload: payload),
      next: payload.moments.first { $0.date > date },
      isPlaceholder: false
    )
  }

  /// The five prayers of the civil day in progress. After Isya this is
  /// tomorrow's row, matching the upcoming Fajr that gets highlighted.
  private func prayers(for date: Date, payload: PrayerPayload) -> [PrayerMoment] {
    if let day = payload.days.first(where: { ($0.prayers.last?.date ?? .distantPast) > date }) {
      return day.prayers
    }
    if let last = payload.days.last {
      return last.prayers
    }
    return Array(payload.moments.prefix(5))
  }

  private func hijri(for date: Date, payload: PrayerPayload) -> String {
    if let day = payload.days.first(where: { ($0.prayers.last?.date ?? .distantPast) > date }),
       !day.hijri.isEmpty {
      return day.hijri
    }
    if let last = payload.days.last, !last.hijri.isEmpty {
      return last.hijri
    }
    return payload.hijri
  }

  private func loadPayload() -> PrayerPayload {
    guard
      let raw = UserDefaults(suiteName: appGroup)?.string(forKey: "prayer_widget_payload"),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return PrayerPayload(location: "Al-Qur'an", hijri: "", days: [], moments: [])
    }

    let moments = parseMoments(json["moments"] as? [[String: Any]] ?? [])
      .sorted { $0.date < $1.date }
    let days = (json["days"] as? [[String: Any]] ?? []).compactMap { item -> PrayerDay? in
      let prayers = parseMoments(item["prayers"] as? [[String: Any]] ?? [])
      guard !prayers.isEmpty else { return nil }
      return PrayerDay(
        hijri: item["hijriDate"] as? String ?? "",
        prayers: prayers
      )
    }

    return PrayerPayload(
      location: json["location"] as? String ?? "Al-Qur'an",
      hijri: json["hijriDate"] as? String ?? "",
      days: days,
      moments: moments
    )
  }

  private func parseMoments(_ items: [[String: Any]]) -> [PrayerMoment] {
    items.compactMap { item in
      guard
        let key = item["prayer"] as? String,
        let name = item["label"] as? String,
        let time = item["time"] as? String,
        let epoch = item["epochMs"] as? Double
      else { return nil }
      return PrayerMoment(
        key: key,
        name: name,
        time: time,
        date: Date(timeIntervalSince1970: epoch / 1000)
      )
    }
  }

  private func placeholderPrayers() -> [PrayerMoment] {
    let now = Date()
    let rows = [
      ("fajr", "Subuh", "04:32"),
      ("dhuhr", "Dzuhur", "11:58"),
      ("asr", "Ashar", "15:16"),
      ("maghrib", "Maghrib", "18:02"),
      ("isha", "Isya", "19:12"),
    ]
    return rows.enumerated().map { index, row in
      PrayerMoment(
        key: row.0,
        name: row.1,
        time: row.2,
        date: now.addingTimeInterval(Double(index + 1) * 3600)
      )
    }
  }
}

private struct PrayerTimesWidgetEntryView: View {
  var entry: PrayerEntry

  private let cream = Color(red: 1.0, green: 0.98, blue: 0.95)
  private let gold = Color(red: 0.94, green: 0.83, blue: 0.54)
  private let muted = Color(red: 0.73, green: 0.87, blue: 0.83)

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        Text(entry.location)
          .font(.system(size: 11))
          .lineLimit(1)
          .foregroundStyle(muted)

        Spacer(minLength: 4)

        if !entry.hijri.isEmpty {
          Text(entry.hijri)
            .font(.system(size: 10, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(gold.opacity(0.95))
        }
      }

      HStack(alignment: .center, spacing: 8) {
        VStack(alignment: .leading, spacing: 0) {
          Text("SHOLAT SELANJUTNYA")
            .font(.system(size: 8, weight: .semibold))
            .tracking(0.7)
            .foregroundStyle(muted)

          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.next?.name ?? "Waktu shalat")
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(gold)

            Text(entry.next?.time ?? "--:--")
              .font(.system(size: 24, weight: .bold, design: .rounded))
              .foregroundStyle(cream)
          }
        }

        Spacer(minLength: 2)

        if let next = entry.next {
          VStack(alignment: .trailing, spacing: 0) {
            Text("menuju adzan")
              .font(.system(size: 9))
              .foregroundStyle(muted)

            Text(next.date, style: .timer)
              .font(.system(size: 13, weight: .semibold, design: .rounded))
              .monospacedDigit()
              .foregroundStyle(cream)
          }
        }
      }

      Rectangle()
        .fill(gold.opacity(0.25))
        .frame(height: 1)

      HStack(spacing: 3) {
        ForEach(entry.prayers) { prayer in
          let highlighted = prayer.key == entry.next?.key

          VStack(spacing: 1) {
            Text(prayer.name)
              .font(.system(size: 9, weight: highlighted ? .bold : .regular))
              .lineLimit(1)
              .minimumScaleFactor(0.7)

            Text(prayer.time)
              .font(.system(size: 12, weight: highlighted ? .bold : .semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.75)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 7)
              .fill(highlighted ? gold.opacity(0.16) : Color.clear)
          )
          .foregroundStyle(highlighted ? gold : cream.opacity(0.92))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(14)
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
    .description("Lima waktu shalat, hitung mundur adzan, dan tanggal Hijriah.")
    .supportedFamilies([.systemMedium, .systemLarge])
  }
}
