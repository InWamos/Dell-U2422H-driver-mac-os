import AppKit
import CDDC
import ServiceManagement
import SwiftUI

private let vcpBrightness: UInt8 = 0x10
private let vcpContrast: UInt8 = 0x12

// ponytail: DDC calls block a cooperative-pool thread for up to ~1 s; move to a dedicated thread if UI ever stalls.
/// Serialises DDC traffic; reopens the display once if the handle went stale (sleep, replug).
actor ExternalDisplay {
    private var handle: DDCDisplayRef?

    func read(_ code: UInt8) -> (current: Int, maximum: Int)? {
        withHandle { display in
            var current: UInt16 = 0
            var maximum: UInt16 = 0
            return ddc_get_vcp(display, code, &current, &maximum) ? (Int(current), Int(maximum)) : nil
        }
    }

    func write(_ code: UInt8, _ value: Int) {
        _ = withHandle { ddc_set_vcp($0, code, UInt16(value)) ? true : nil }
    }

    private func withHandle<T>(_ operation: (DDCDisplayRef) -> T?) -> T? {
        for _ in 0..<2 {
            if handle == nil { handle = ddc_open_external_display() }
            guard let display = handle else { return nil }
            if let result = operation(display) { return result }
            ddc_close(display)
            handle = nil
        }
        return nil
    }
}

/// One VCP feature of the monitor (brightness, contrast, ...), mirrored for a slider.
@MainActor @Observable
final class VCPControl {
    var value = 0.0
    var maximum = 100.0
    var reachable = true
    private let code: UInt8
    private let display: ExternalDisplay
    private var pendingValue: Int?
    private var isWriting = false

    init(code: UInt8, display: ExternalDisplay) {
        self.code = code
        self.display = display
    }

    func refresh() async {
        let reading = await display.read(code)
        reachable = reading != nil
        guard let reading else { return }
        maximum = Double(reading.maximum)
        value = Double(reading.current)
    }

    /// Slider drags fire far faster than DDC can take writes, so only the latest value is sent.
    func set(_ newValue: Double) {
        value = newValue
        pendingValue = Int(newValue.rounded())
        guard !isWriting else { return }
        isWriting = true
        Task {
            while let next = pendingValue {
                pendingValue = nil
                await display.write(code, next)
            }
            isWriting = false
        }
    }
}

/// "Launch at login", backed by the system list in System Settings > General > Login Items.
@MainActor @Observable
final class LoginItem {
    private(set) var isEnabled = false

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func set(_ enabled: Bool) {
        let service = SMAppService.mainApp
        if enabled { try? service.register() } else { try? service.unregister() }
        if service.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        refresh()
    }
}

struct VCPSlider: View {
    let control: VCPControl
    let label: String
    let lowIcon: String
    let highIcon: String

    var body: some View {
        HStack {
            Image(systemName: lowIcon).accessibilityHidden(true)
            Slider(value: binding, in: 0...control.maximum, step: 1).accessibilityLabel(label)
            Image(systemName: highIcon).accessibilityHidden(true)
            Text("\(Int(control.value))%").monospacedDigit().frame(width: 40, alignment: .trailing)
        }
    }

    /// A closure setter, not `control.set`: Swift 6.3 crashes compiling the method-reference thunk.
    private var binding: Binding<Double> {
        Binding(get: { control.value }, set: { control.set($0) })
    }
}

struct ControlsView: View {
    let brightness: VCPControl
    let contrast: VCPControl
    let loginItem: LoginItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dell U2422H").font(.headline)
            if brightness.reachable {
                VCPSlider(control: brightness, label: "Brightness", lowIcon: "sun.min", highIcon: "sun.max")
            }
            if contrast.reachable {
                VCPSlider(
                    control: contrast,
                    label: "Contrast",
                    lowIcon: "circle.lefthalf.filled",
                    highIcon: "circle.righthalf.filled"
                )
            }
            if !brightness.reachable && !contrast.reachable {
                Text("Monitor not reachable over DDC/CI").foregroundStyle(.secondary)
            }
            Divider()
            Toggle("Launch at login", isOn: launchAtLogin)
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 300)
        .task {
            loginItem.refresh()
            await brightness.refresh()
            await contrast.refresh()
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(get: { loginItem.isEnabled }, set: { loginItem.set($0) })
    }
}

@main
struct U2422HControlApp: App {
    private let brightness: VCPControl
    private let contrast: VCPControl
    private let loginItem = LoginItem()

    init() {
        let display = ExternalDisplay()  // shared: one actor serialises all DDC traffic
        brightness = VCPControl(code: vcpBrightness, display: display)
        contrast = VCPControl(code: vcpContrast, display: display)
    }

    var body: some Scene {
        MenuBarExtra {
            ControlsView(brightness: brightness, contrast: contrast, loginItem: loginItem)
        } label: {
            Image(nsImage: .dellWordmark).accessibilityLabel("Dell U2422H")
        }
        .menuBarExtraStyle(.window)
    }
}
