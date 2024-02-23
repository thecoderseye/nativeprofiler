//
//  ProfilerAssets.swift
//  nativeplugins
//
//  Created by Seunghyun Roh on 23/2/24.
//

import Foundation

public enum Unit : Double {
    case Byte = 1
    case KB = 1024
    case MB = 1048576 //KB x 1024
    case GB = 1073741824 //MB x 1024
}

public struct ProfilerAssets {
    
    private static var shared = ProfilerAssets()
    
    private let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info_t>.size/MemoryLayout<integer_t>.size

    private let _machHost = mach_host_self()
    public static var MacHost: mach_port_t {
        get {
            return shared._machHost
        }
    }
    
    private var _hostBasicInfo: host_basic_info?
    public static var DeviceInfo : host_basic_info {
        get {
            return shared._hostBasicInfo!
        }
    }
    
    public static func create() {
        shared._createHostInfo()
    }
    
    private var _physicalCoresCount: Int?
    public static var PhysicalCoresCount: Int {
        get {
            return shared._physicalCoresCount!
        }
    }
    
    private var _logicalCoresCount: Int?
    public static var LogicalCoresCount: Int {
        get {
            return shared._logicalCoresCount!
        }
    }
    
    
    private var _physicalMemory: Int?
    public static var PhysicalMemory: Int {
        get {
            return shared._physicalMemory!
        }
    }
    
    public init() {
        _hostBasicInfo = host_basic_info()
    }
    
    private mutating func _createHostInfo() {
                
        var size = mach_msg_type_number_t(HOST_BASIC_INFO_COUNT)
        let buffer = host_basic_info_t.allocate(capacity: 1)
        
        let result = buffer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_info(_machHost, HOST_BASIC_INFO, $0, &size)
        }

        if result != KERN_SUCCESS {
        }
        
        _hostBasicInfo = buffer.move()
        
        _physicalCoresCount = Int(_hostBasicInfo!.physical_cpu)
        _logicalCoresCount = Int(_hostBasicInfo!.logical_cpu)
        _physicalMemory = Int(_hostBasicInfo!.max_mem)
        
        buffer.deallocate()
    }
    
}
