//
//  SettingsManager.swift
//  ProCam Master
//
//  设置和偏好管理器
//  Created by Claude
//

import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {

    static let shared = SettingsManager()

    // MARK: - Published Settings
    @Published var cameraSettings: CameraSettings {
        didSet {
            saveCameraSettings()
        }
    }

    @Published var appPreferences: AppPreferences {
        didSet {
            saveAppPreferences()
        }
    }

    // MARK: - App Preferences
    struct AppPreferences {
        var showWelcome: Bool = true
        var enableHaptic: Bool = true
        var enableSound: Bool = true
        var autoSaveToPhotos: Bool = true
        var saveLocation: SaveLocation = .photos
        var fileNamingPattern: FileNamingPattern = .timestamp
        var keepOriginals: Bool = true

        enum SaveLocation: String, CaseIterable {
            case photos = "相册"
            case files = "文件"
            case both = "两者"
        }

        enum FileNamingPattern: String, CaseIterable {
            case timestamp = "时间戳"
            case sequence = "序号"
            case custom = "自定义"
        }
    }

    // MARK: - Private Properties
    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Keys
    private enum Keys {
        static let cameraSettings = "settings.camera"
        static let appPreferences = "settings.app"
        static let lastVersion = "app.lastVersion"
    }

    // MARK: - Initialization
    private init() {
        // 加载保存的设置
        self.cameraSettings = loadCameraSettings()
        self.appPreferences = loadAppPreferences()

        // 检查是否是首次启动
        checkFirstLaunch()
    }

    // MARK: - Public Methods

    /// 重置所有设置
    func resetAllSettings() {
        cameraSettings = CameraSettings()
        appPreferences = AppPreferences()

        // 清除UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
    }

    /// 导出设置
    func exportSettings() -> Data? {
        let exportData: [String: Any] = [
            "camera": encodeCameraSettings(cameraSettings),
            "preferences": encodeAppPreferences(appPreferences),
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]

        return try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    /// 导入设置
    func importSettings(from data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }

        // 导入相机设置
        if let cameraDict = json["camera"] as? [String: Any] {
            if let settings = decodeCameraSettings(cameraDict) {
                self.cameraSettings = settings
            }
        }

        // 导入应用偏好
        if let prefsDict = json["preferences"] as? [String: Any] {
            if let prefs = decodeAppPreferences(prefsDict) {
                self.appPreferences = prefs
            }
        }

        return true
    }

    // MARK: - Private Methods

    /// 检查首次启动
    private func checkFirstLaunch() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let lastVersion = defaults.string(forKey: Keys.lastVersion)

        if lastVersion == nil {
            // 首次启动
            appPreferences.showWelcome = true
        } else if lastVersion != currentVersion {
            // 版本更新
            // 可以在这里处理版本迁移逻辑
        }

        defaults.set(currentVersion, forKey: Keys.lastVersion)
    }

    /// 保存相机设置
    private func saveCameraSettings() {
        let dict = encodeCameraSettings(cameraSettings)
        defaults.set(dict, forKey: Keys.cameraSettings)
    }

    /// 加载相机设置
    private func loadCameraSettings() -> CameraSettings {
        guard let dict = defaults.dictionary(forKey: Keys.cameraSettings) else {
            return CameraSettings()
        }

        return decodeCameraSettings(dict) ?? CameraSettings()
    }

    /// 编码相机设置
    private func encodeCameraSettings(_ settings: CameraSettings) -> [String: Any] {
        return [
            "shootingMode": settings.shootingMode.rawValue,
            "iso": settings.exposure.iso,
            "gridType": settings.gridType.rawValue,
            "isHistogramVisible": settings.isHistogramVisible,
            "isLevelVisible": settings.isLevelVisible,
            "isInfoOverlayVisible": settings.isInfoOverlayVisible,
            "isProRAWEnabled": settings.isProRAWEnabled,
            "proRAWResolution": settings.proRAWResolution.rawValue
        ]
    }

    /// 解码相机设置
    private func decodeCameraSettings(_ dict: [String: Any]) -> CameraSettings? {
        var settings = CameraSettings()

        if let modeString = dict["shootingMode"] as? String,
           let mode = ShootingMode(rawValue: modeString) {
            settings.shootingMode = mode
        }

        if let iso = dict["iso"] as? Float {
            settings.exposure.iso = iso
        }

        if let gridString = dict["gridType"] as? String,
           let grid = GridType(rawValue: gridString) {
            settings.gridType = grid
        }

        if let histogram = dict["isHistogramVisible"] as? Bool {
            settings.isHistogramVisible = histogram
        }

        if let level = dict["isLevelVisible"] as? Bool {
            settings.isLevelVisible = level
        }

        if let info = dict["isInfoOverlayVisible"] as? Bool {
            settings.isInfoOverlayVisible = info
        }

        if let proRAW = dict["isProRAWEnabled"] as? Bool {
            settings.isProRAWEnabled = proRAW
        }

        if let resString = dict["proRAWResolution"] as? String,
           let res = CameraSettings.ProRAWResolution(rawValue: resString) {
            settings.proRAWResolution = res
        }

        return settings
    }

    /// 保存应用偏好
    private func saveAppPreferences() {
        let dict = encodeAppPreferences(appPreferences)
        defaults.set(dict, forKey: Keys.appPreferences)
    }

    /// 加载应用偏好
    private func loadAppPreferences() -> AppPreferences {
        guard let dict = defaults.dictionary(forKey: Keys.appPreferences) else {
            return AppPreferences()
        }

        return decodeAppPreferences(dict) ?? AppPreferences()
    }

    /// 编码应用偏好
    private func encodeAppPreferences(_ prefs: AppPreferences) -> [String: Any] {
        return [
            "showWelcome": prefs.showWelcome,
            "enableHaptic": prefs.enableHaptic,
            "enableSound": prefs.enableSound,
            "autoSaveToPhotos": prefs.autoSaveToPhotos,
            "saveLocation": prefs.saveLocation.rawValue,
            "fileNamingPattern": prefs.fileNamingPattern.rawValue,
            "keepOriginals": prefs.keepOriginals
        ]
    }

    /// 解码应用偏好
    private func decodeAppPreferences(_ dict: [String: Any]) -> AppPreferences? {
        var prefs = AppPreferences()

        if let showWelcome = dict["showWelcome"] as? Bool {
            prefs.showWelcome = showWelcome
        }

        if let haptic = dict["enableHaptic"] as? Bool {
            prefs.enableHaptic = haptic
        }

        if let sound = dict["enableSound"] as? Bool {
            prefs.enableSound = sound
        }

        if let autoSave = dict["autoSaveToPhotos"] as? Bool {
            prefs.autoSaveToPhotos = autoSave
        }

        if let locationString = dict["saveLocation"] as? String,
           let location = AppPreferences.SaveLocation(rawValue: locationString) {
            prefs.saveLocation = location
        }

        if let patternString = dict["fileNamingPattern"] as? String,
           let pattern = AppPreferences.FileNamingPattern(rawValue: patternString) {
            prefs.fileNamingPattern = pattern
        }

        if let keepOriginals = dict["keepOriginals"] as? Bool {
            prefs.keepOriginals = keepOriginals
        }

        return prefs
    }
}
