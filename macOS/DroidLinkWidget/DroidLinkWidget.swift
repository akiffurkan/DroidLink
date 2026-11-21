import WidgetKit
import SwiftUI

public struct BatteryWidgetEntry: TimelineEntry {
    public let date: Date
    public let batteryLevel: Int
    public let isCharging: Bool
    public let deviceName: String
    public let isOnline: Bool
    
    public init(
        date: Date = Date(),
        batteryLevel: Int = 84,
        isCharging: Bool = true,
        deviceName: String = "Galaxy A04e",
        isOnline: Bool = true
    ) {
        self.date = date
        self.batteryLevel = batteryLevel
        self.isCharging = isCharging
        self.deviceName = deviceName
        self.isOnline = isOnline
    }
}

public struct DroidLinkTimelineProvider: TimelineProvider {
    public typealias Entry = BatteryWidgetEntry
    
    public func placeholder(in context: Context) -> BatteryWidgetEntry {
        BatteryWidgetEntry()
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (BatteryWidgetEntry) -> Void) {
        completion(fetchCurrentEntry())
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<BatteryWidgetEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // WidgetKit bütçesini korumak için 15 dakikalık yenileme planı
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchCurrentEntry() -> BatteryWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.com.droidlink.shared")
        let level = defaults?.integer(forKey: "batteryLevel") ?? 0
        let isCharging = defaults?.bool(forKey: "isCharging") ?? false
        let deviceName = defaults?.string(forKey: "deviceName") ?? "Galaxy A04e"
        let lastSeenTimestamp = defaults?.double(forKey: "lastSeen") ?? 0
        
        let isOnline = (Date().timeIntervalSince1970 - lastSeenTimestamp) < 180 && lastSeenTimestamp > 0
        
        return BatteryWidgetEntry(
            date: Date(),
            batteryLevel: level > 0 ? level : 84,
            isCharging: isCharging,
            deviceName: deviceName,
            isOnline: isOnline
        )
    }
}

public struct DroidLinkWidgetEntryView: View {
    var entry: BatteryWidgetEntry
    @Environment(\.widgetFamily) var family
    
    public var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }
    
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "iphone.gen3")
                    .foregroundColor(.accentColor)
                Spacer()
                if entry.isCharging {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            Text("\(entry.batteryLevel)%")
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text(entry.isOnline ? entry.deviceName : "Çevrimdışı")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.black.opacity(0.85)
        }
    }
    
    private var mediumWidgetView: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.gen3")
                        .foregroundColor(.accentColor)
                    Text(entry.deviceName)
                        .font(.system(size: 13, weight: .bold))
                }
                
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.batteryLevel)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if entry.isCharging {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .padding(.leading, 4)
                    }
                }
                
                Text(entry.isOnline ? "Canlı Bağlantı" : "Son Senkronize Veri")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Pil Çubuğu Grafiği
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: CGFloat(entry.batteryLevel) / 100.0)
                    .stroke(
                        entry.batteryLevel <= 20 ? Color.red : (entry.batteryLevel <= 40 ? Color.yellow : Color.green),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: entry.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.black.opacity(0.85)
        }
    }
}

@main
public struct DroidLinkWidget: Widget {
    public let kind: String = "DroidLinkWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DroidLinkTimelineProvider()) { entry in
            DroidLinkWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DroidLink Pil")
        .description("Samsung telefonunuzun pil seviyesini Mac masaüstünüzde takip edin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
