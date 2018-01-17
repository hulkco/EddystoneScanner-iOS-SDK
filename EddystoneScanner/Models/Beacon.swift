//
//  Beacon.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 27/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import Foundation
import CoreBluetooth

/// Main Beacon class
public class Beacon {
    
    public let identifier: UUID
    public let beaconID: BeaconID
    public let txPower: Int
    public var rssi: Int
    public var lastSeen: Date = Date()
    
    public var eddystoneURL: URL?
    
    public var telemetry: Telemetry?
    
    private init(identifier: UUID, beaconID: BeaconID, txPower: Int, rssi: Int) {
        self.identifier = identifier
        self.beaconID = beaconID
        self.txPower = txPower
        self.rssi = rssi
    }
    
    /**
     Failable convinience initialiser to create a Beacon object with Eddystone UID/EID packet
     
     - Parameter frameData: The frameData.
     - Parameter telemetry: The telemetry data obtained from Beacon.telemetryDataForFrame. Optional.
     - Parameter rssi: The RSSI value of the beacon.
     */
    convenience internal init?(identifier: UUID, frameData: Data?, rssi: Int) {
        guard let frameData = frameData, frameData.count > 1 else {
            return nil
        }
        
        let frameBytes = Array(frameData) as [UInt8]
        
        let frameByte = frameBytes[0]
        guard (frameByte == Eddystone.EddystoneUIDFrameTypeID ||
            frameByte == Eddystone.EddystoneEIDFrameTypeID) else {
            debugPrint("Unexpected non UID/EID Frame passed to the initialiser.")
            return nil
        }
        
        let txPower = Int(Int8(bitPattern:frameBytes[1]))
        
        let beaconID: BeaconID
        if frameByte == Eddystone.EddystoneUIDFrameTypeID {
            if frameBytes.count < 18 {
                debugPrint("Frame Data for UID Frame unexpectedly truncated.")
            }
            beaconID = BeaconID(beaconType: .eddystone,
                                    beaconID: Array(frameBytes[2..<18]))
        } else {
            if frameBytes.count < 10 {
                debugPrint("Frame Data for EID Frame unexpectedly truncated.")
            }
            beaconID = BeaconID(beaconType: .eddystoneEID,
                                    beaconID: Array(frameBytes[2..<10]))
        }
        
        self.init(identifier: identifier, beaconID: beaconID, txPower: txPower, rssi: rssi)
    }
    
    /**
     Update the beacon object with changable data
     
     - Parameter telemetryData: Telemetry Data from the beacon.
     - Parameter eddystoneURL: The eddystoneURL of the beacon.
     - Parameter rssi: The current RSSI value of the beacon.
     */
    internal func updateBeacon(telemetryData: Data?, eddystoneURL: URL?, rssi: Int) {
        if let telemetryData = telemetryData {
            self.telemetry = Telemetry(tlmFrameData: telemetryData)
        }
        self.eddystoneURL = eddystoneURL
        self.rssi = rssi
        self.lastSeen = Date()
    }
}

extension Beacon: CustomStringConvertible {
    // MARK: CustomStringConvertible protocol requirements
    public var description: String {
        return self.beaconID.description
    }
}

extension Beacon: Equatable {
    // MARK: Equatable protocol requirements
    public static func == (lhs: Beacon, rhs: Beacon) -> Bool {
        return lhs.beaconID == rhs.beaconID
    }
}

extension Beacon: Hashable {
    // MARK: Hashable protocol requirements
    public var hashValue: Int {
        get {
            return self.description.hashValue
        }
    }
}

