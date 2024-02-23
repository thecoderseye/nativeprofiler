//
//  CpuProfiler.swift
//  nativeplugins
//
//  Created by Seunghyun Roh on 22/2/24.
//

import Foundation
import System

public struct CpuProfiler
{
    public struct Stats {
        var UserCpu: UInt32
        var SystemCpu: UInt32
        var IdleCpu: UInt32
        var NiceCpu: UInt32
        
        fileprivate func GetData() -> UInt32 {
            var data:UInt32 = 0
            
            data = data | (NiceCpu << 24)
            data = data | (IdleCpu << 16)
            data = data | (SystemCpu << 8)
            data = data | UserCpu
            
            return data
        }
    }
    
    private static var shared = CpuProfiler()

    private let HOST_BASIC_INFO_COUNT = MemoryLayout<host_basic_info_t>.size/MemoryLayout<integer_t>.size
    private let HOST_LOAD_INFO_COUNT = MemoryLayout<host_load_info_data_t>.size / MemoryLayout<integer_t>.size
    private let HOST_CPU_LOAD_INFO_COUNT = MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
    
    private var _deviceInfo: host_basic_info?
    private var _machHost: mach_port_t?
    private var _previousCpuLoad: host_cpu_load_info?

    public static func begin(machHost: mach_port_t, deviceInfo: host_basic_info) {
        
        shared._machHost = machHost
        shared._deviceInfo = deviceInfo
        shared._previousCpuLoad = shared.GetCpuLoadInfo()
    }
    
    public static func end() {
    }
    
    public static func readCpuStats32() -> UInt32 {

        let previous = shared._previousCpuLoad!
        let cpuLoadInfo = shared.GetCpuLoadInfo()

        let userDeltaTicks = Double(cpuLoadInfo.cpu_ticks.0 - previous.cpu_ticks.0)
        let systemDeltaTicks  = Double(cpuLoadInfo.cpu_ticks.1 - previous.cpu_ticks.1)
        let idleDeltaTicks = Double(cpuLoadInfo.cpu_ticks.2 - previous.cpu_ticks.2)
        let niceDeltaTicks = Double(cpuLoadInfo.cpu_ticks.3 - previous.cpu_ticks.3)
        
        let totalTicks = systemDeltaTicks + userDeltaTicks + niceDeltaTicks + idleDeltaTicks

        var userCpu: UInt32 = 0
        var systemCpu: UInt32 = 0
        var idleCpu: UInt32 = 0
        var niceCpu: UInt32 = 0
        
        if totalTicks > 0 {
            userCpu = UInt32(userDeltaTicks / totalTicks * 100.0)
            systemCpu  = UInt32(systemDeltaTicks  / totalTicks * 100.0)
            idleCpu = UInt32(idleDeltaTicks / totalTicks * 100.0)
            niceCpu = UInt32(niceDeltaTicks / totalTicks * 100.0)
        }
        
        shared._previousCpuLoad = cpuLoadInfo
        
        let stats = Stats(UserCpu: userCpu, SystemCpu: systemCpu, IdleCpu: idleCpu, NiceCpu: niceCpu)
        return stats.GetData()
    }
    
    
    public init() {
    }
    
    private func GetCpuLoadInfo() -> host_cpu_load_info {
        var size = mach_msg_type_number_t(HOST_CPU_LOAD_INFO_COUNT)
        let buffer = host_cpu_load_info_t.allocate(capacity: 1)
        
        let result = buffer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
            host_statistics(_machHost!, HOST_CPU_LOAD_INFO,
                                      $0,
                                      &size)
        }
        
        let cpuLoadInfo = buffer.move()
        buffer.deallocate()
        
        //todo: check result and do a proper error handling
        if result != KERN_SUCCESS {
        }
        
        return cpuLoadInfo
    }
}
