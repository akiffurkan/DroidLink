import XCTest
@testable import DroidLink

final class ProtocolTests: XCTestCase {
    func testBatteryPayloadEncodingAndDecoding() throws {
        let payload = BatteryPayload(
            deviceId: "samsung-sm-a042f",
            deviceName: "Galaxy A04e",
            batteryLevel: 84,
            isCharging: true,
            chargingSource: .usb,
            temperature: 28.5,
            health: .good,
            voltage: 4100
        )
        
        let message = DroidMessage(type: .batteryUpdate, payload: payload)
        let encoder = JSONEncoder()
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        let decodedMessage = try decoder.decode(DroidMessage<BatteryPayload>.self, from: data)
        
        XCTAssertEqual(decodedMessage.type, .batteryUpdate)
        XCTAssertEqual(decodedMessage.payload.batteryLevel, 84)
        XCTAssertEqual(decodedMessage.payload.isCharging, true)
        XCTAssertEqual(decodedMessage.payload.deviceName, "Galaxy A04e")
        XCTAssertEqual(decodedMessage.payload.chargingSource, .usb)
    }
}
