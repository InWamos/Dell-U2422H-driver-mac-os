import CDDC
import Foundation

// usage: ddc get <vcp-hex> | ddc set <vcp-hex> <value>
let args = CommandLine.arguments.dropFirst()
guard let command = args.first, let code = args.dropFirst().first.flatMap({ UInt8($0, radix: 16) }) else {
    FileHandle.standardError.write("usage: ddc get <vcp-hex> | ddc set <vcp-hex> <value>\n".data(using: .utf8)!)
    exit(2)
}
guard let display = ddc_open_external_display() else {
    FileHandle.standardError.write("no external display\n".data(using: .utf8)!)
    exit(1)
}
defer { ddc_close(display) }

switch command {
case "get":
    var current: UInt16 = 0, maximum: UInt16 = 0
    guard ddc_get_vcp(display, code, &current, &maximum) else { print("read failed"); exit(1) }
    print("\(current)/\(maximum)")
case "set":
    guard let value = args.dropFirst(2).first.flatMap({ UInt16($0) }), ddc_set_vcp(display, code, value) else {
        print("write failed"); exit(1)
    }
default:
    exit(2)
}
