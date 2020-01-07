import Flutter
import UIKit


public class SwiftGetIpPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "get_ip", binaryMessenger: registrar.messenger())
    let instance = SwiftGetIpPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let ip =  getWiFiAddress()
    result(ip)
  }

  // Return IP address of WiFi interface (en0) as a String, or `nil`
  public func getWiFiAddress() -> String? {
        var address : String?
        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if  name == "en0" {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                        address = String(cString: hostname)
                        if addrFamily == UInt8(AF_INET) {
                            if address != nil && !(address!).isEmpty {
                                var netmaskName = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                                getnameinfo(interface.ifa_netmask, socklen_t(interface.ifa_netmask.pointee.sa_len),
                                            &netmaskName, socklen_t(netmaskName.count),
                                            nil, socklen_t(0), NI_NUMERICHOST)
                                if let netmask = String.init(validatingUTF8:netmaskName) {
                                    let inverted_netmask = bitwise(op:~, net1: netmask)
                                    let broadcast = bitwise(op:|, net1: address!, net2: inverted_netmask)
                                    address = address! + "," + broadcast
                                }
                            }
                        }
                    }
                }
            }
        }
        freeifaddrs(ifaddr)

        return address

  }

  private func bitwise(op: (UInt8,UInt8) -> UInt8, net1: String, net2: String) -> String {
      let net1numbers = toInts(networkString: net1)
      let net2numbers = toInts(networkString: net2)
      var result = ""
      for i in 0..<net1numbers.count {
          result += "\(op(net1numbers[i],net2numbers[i]))"
          if i < (net1numbers.count-1) {
              result += "."
          }
      }
      return result
  }

  private func bitwise(op: (UInt8) -> UInt8, net1: String) -> String {
      let net1numbers = toInts(networkString: net1)
      var result = ""
      for i in 0..<net1numbers.count {
          result += "\(op(net1numbers[i]))"
          if i < (net1numbers.count-1) {
              result += "."
          }
      }
      return result
  }

  private func toInts(networkString: String) -> [UInt8] {
      return networkString.split(separator: ".").map({ UInt8($0)! })
  }
}
