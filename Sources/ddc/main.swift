import CDDC
import Foundation

let usage = "usage: ddc get <vcp-hex> | ddc set <vcp-hex> <value>"

func fail(_ message: String, status: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(status)
}

let args = CommandLine.arguments.dropFirst()
guard let command = args.first, let code = args.dropFirst().first.flatMap({ UInt8($0, radix: 16) }) else {
    fail(usage, status: 2)
}
guard let display = ddc_open_external_display() else { fail("no external display") }

switch command {
case "get":
    var current: UInt16 = 0
    var maximum: UInt16 = 0
    guard ddc_get_vcp(display, code, &current, &maximum) else { fail("read failed") }
    print("\(current)/\(maximum)")
case "set":
    guard let value = args.dropFirst(2).first.flatMap({ UInt16($0) }) else { fail(usage, status: 2) }
    guard ddc_set_vcp(display, code, value) else { fail("write failed") }
default:
    fail(usage, status: 2)
}
