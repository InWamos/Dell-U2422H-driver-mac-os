import AppKit
import CDDC
import SwiftUI

private let vcpBrightness: UInt8 = 0x10

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

@MainActor @Observable
final class BrightnessModel {
    var brightness = 0.0
    var maximum = 100.0
    var reachable = true
    private let display = ExternalDisplay()
    private var pendingValue: Int?
    private var isWriting = false

    func refresh() async {
        let reading = await display.read(vcpBrightness)
        reachable = reading != nil
        guard let reading else { return }
        maximum = Double(reading.maximum)
        brightness = Double(reading.current)
    }

    /// Slider drags fire far faster than DDC can take writes, so only the latest value is sent.
    func setBrightness(_ value: Double) {
        brightness = value
        pendingValue = Int(value.rounded())
        guard !isWriting else { return }
        isWriting = true
        Task {
            while let value = pendingValue {
                pendingValue = nil
                await display.write(vcpBrightness, value)
            }
            isWriting = false
        }
    }
}

struct BrightnessView: View {
    let model: BrightnessModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dell U2422H").font(.headline)
            if model.reachable {
                HStack {
                    Image(systemName: "sun.min")
                    Slider(value: brightness, in: 0...model.maximum, step: 1)
                    Image(systemName: "sun.max")
                    Text("\(Int(model.brightness))%").monospacedDigit().frame(width: 40, alignment: .trailing)
                }
            } else {
                Text("Monitor not reachable over DDC/CI").foregroundStyle(.secondary)
            }
            Divider()
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding()
        .frame(width: 300)
        .task { await model.refresh() }
    }

    /// A closure setter, not `model.setBrightness`: Swift 6.3 crashes compiling the method-reference thunk.
    private var brightness: Binding<Double> {
        Binding(get: { model.brightness }, set: { model.setBrightness($0) })
    }
}

@main
struct U2422HControlApp: App {
    private let model = BrightnessModel()

    var body: some Scene {
        MenuBarExtra {
            BrightnessView(model: model)
        } label: {
            Image(nsImage: .dellWordmark)
        }
        .menuBarExtraStyle(.window)
    }
}
