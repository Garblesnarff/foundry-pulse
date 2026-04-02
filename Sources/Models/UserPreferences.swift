import Foundation

/// User preferences and settings persistence.
///
/// Stores settings in UserDefaults:
/// - pollingInterval: How often to check metrics (1-5 seconds)
/// - menuBarGraph: Which metric to show as sparkline (CPU/GPU)
/// - selectedTab: Last selected tab in popover
/// - popoverWidth/Height: Last popover size
/// - isPro: Pro tier status (placeholder for StoreKit)
final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let pollingInterval = "pollingInterval"
        static let menuBarGraph = "menuBarGraph"
        static let selectedTab = "selectedTab"
        static let popoverWidth = "popoverWidth"
        static let popoverHeight = "popoverHeight"
        static let isPro = "isPro"
        static let showBattery = "showBattery"
        static let showNetwork = "showNetwork"
    }
    
    // MARK: - Properties
    
    /// Polling interval in seconds (1-5, default 2)
    @Published var pollingInterval: Double {
        didSet {
            defaults.set(pollingInterval, forKey: Keys.pollingInterval)
        }
    }
    
    /// Which metric to show in menu bar sparkline
    @Published var menuBarGraph: MenuBarMetric {
        didSet {
            defaults.set(menuBarGraph.rawValue, forKey: Keys.menuBarGraph)
        }
    }
    
    /// Last selected tab
    @Published var selectedTab: TabSelection {
        didSet {
            defaults.set(selectedTab.rawValue, forKey: Keys.selectedTab)
        }
    }
    
    /// Popover width
    @Published var popoverWidth: Double {
        didSet {
            defaults.set(popoverWidth, forKey: Keys.popoverWidth)
        }
    }
    
    /// Popover height
    @Published var popoverHeight: Double {
        didSet {
            defaults.set(popoverHeight, forKey: Keys.popoverHeight)
        }
    }
    
    /// Pro tier status (would be checked via StoreKit)
    @Published var isPro: Bool {
        didSet {
            defaults.set(isPro, forKey: Keys.isPro)
        }
    }
    
    /// Show battery section
    @Published var showBattery: Bool {
        didSet {
            defaults.set(showBattery, forKey: Keys.showBattery)
        }
    }
    
    /// Show network section
    @Published var showNetwork: Bool {
        didSet {
            defaults.set(showNetwork, forKey: Keys.showNetwork)
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load saved values or defaults
        self.pollingInterval = defaults.object(forKey: Keys.pollingInterval) as? Double ?? 2.0
        self.menuBarGraph = MenuBarMetric(rawValue: defaults.string(forKey: Keys.menuBarGraph) ?? "cpu") ?? .cpu
        self.selectedTab = TabSelection(rawValue: defaults.string(forKey: Keys.selectedTab) ?? "overview") ?? .overview
        self.popoverWidth = defaults.object(forKey: Keys.popoverWidth) as? Double ?? 300.0
        self.popoverHeight = defaults.object(forKey: Keys.popoverHeight) as? Double ?? 600.0
        self.isPro = defaults.bool(forKey: Keys.isPro)
        self.showBattery = defaults.object(forKey: Keys.showBattery) as? Bool ?? true
        self.showNetwork = defaults.object(forKey: Keys.showNetwork) as? Bool ?? true
    }
    
    // MARK: - Methods
    
    /// Reset all settings to defaults
    func resetToDefaults() {
        pollingInterval = 2.0
        menuBarGraph = .cpu
        selectedTab = .overview
        popoverWidth = 300.0
        popoverHeight = 600.0
        showBattery = true
        showNetwork = true
    }
}

// MARK: - Supporting Types

enum MenuBarMetric: String, CaseIterable {
    case cpu = "cpu"
    case gpu = "gpu"
    case memory = "memory"
    
    var displayName: String {
        switch self {
        case .cpu: return "CPU"
        case .gpu: return "GPU"
        case .memory: return "Memory"
        }
    }
}

enum TabSelection: String, CaseIterable {
    case overview = "overview"
    case graphs = "graphs"
    case processes = "processes"
    case settings = "settings"
}
