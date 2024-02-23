//
//  MemoryProfiler.swift
//  nativeplugins
//
//  Created by Seunghyun Roh on 22/2/24.
//

import Foundation
import System

public struct MemoryProfiler
{
    public struct Stats {
        var free: UInt64
        var active: UInt64
        var inactive: UInt64
        var compressed: UInt64
        
        fileprivate func GetData() -> UInt64 {
            var data:UInt64 = 0
            
            data = data | (compressed << 48)
            data = data | (inactive << 32)
            data = data | (active << 16)
            data = data | free
            
            return data
        }
    }
    
    private static var shared = MemoryProfiler()
    
    private let HOST_VM_INFO64_COUNT = MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size

    private var _machHost: mach_port_t?
    
    public static func begin(machHost: mach_port_t) {
        shared._setMachHost(machHost: machHost)
    }
    
    public static func end() {
        
    }
    
    public static func readMemoryStats() -> UInt64 {
        
        if shared._machHost == nil {
            begin(machHost: mach_host_self())
        }
                
        let usage = shared._getVirtualMemoryStats64()
        let stats = Stats(free: usage.freeMem, active: usage.activeMem, inactive: usage.inactiveMem, compressed: usage.compressed)
        
        return stats.GetData()
    }

    public init() {
        //machHost = mach_port_t()
    }
    
    private mutating func _setMachHost(machHost: mach_port_t) {
        _machHost = machHost as mach_port_t?
    }
    
    private func _getVirtualMemoryStats64() -> (freeMem: UInt64, activeMem: UInt64, inactiveMem: UInt64, compressed: UInt64) {
        var size = mach_msg_type_number_t(HOST_VM_INFO64_COUNT)
        let buffer = vm_statistics64_t.allocate(capacity: 1)
        
        let result = buffer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics64(_machHost!,
                              HOST_VM_INFO64,
                              $0,
                              &size)
        }
        
        if result != KERN_SUCCESS {
        }

        let stats = buffer.move()
        buffer.deallocate()
        
        let freeSize = _rescaleUnit(unit: Unit.MB.rawValue, name: "free", size: Double(stats.free_count) * Double(vm_kernel_page_size))
        let activeSize = _rescaleUnit(unit: Unit.MB.rawValue, name: "active", size: Double(stats.active_count) * Double(vm_kernel_page_size))
        let inactiveSize = _rescaleUnit(unit: Unit.MB.rawValue, name: "inactive", size: Double(stats.inactive_count) * Double(vm_kernel_page_size))
        let compressed = _rescaleUnit(unit: Unit.MB.rawValue, name: "compressed", size: Double(stats.compressor_page_count) * Double(vm_kernel_page_size))
        
        //var wiredSize    = _rescaleUnit(size: Double(stats.wire_count) * Double(vm_kernel_page_size))
        return (freeSize, activeSize, inactiveSize, compressed)
    }
    
    private func _rescaleUnit(unit: Double, name: String, size: Double) -> UInt64 {
        return UInt64(size / unit)
    }
}
