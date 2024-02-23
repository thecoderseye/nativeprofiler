//
//  MainEntry.swift
//  nativeplugins
//
//  Created by Seunghyun Roh on 21/2/24.
//

import Foundation

@objc public class CpuStats : NSObject {
    
    @objc public var UserCpu: Int16
    @objc public var SystemCpu: Int16
    @objc public var IdleCpu: Int16
    @objc public var NiceCpu: Int16
    
    @objc public override init() {
        UserCpu = 0
        SystemCpu = 0
        IdleCpu = 0
        NiceCpu = 0
    }
    
    @objc public func UpdateStats(user: Int16, system: Int16, idle: Int16, nice: Int16) {
        UserCpu = user
        SystemCpu = system
        IdleCpu = idle
        NiceCpu = nice
    }
}

@_cdecl("__start_profiling__")
public func Begin() {
    
    ProfilerAssets.create()
    
    CpuProfiler.begin(machHost: ProfilerAssets.MacHost, deviceInfo: ProfilerAssets.DeviceInfo)
    MemoryProfiler.begin(machHost: ProfilerAssets.MacHost)
    GpuProfiler.begin()
}

@_cdecl("__stop_profiling__")
public func End() {
    CpuProfiler.end()
    GpuProfiler.end()
    MemoryProfiler.end()
}

@_cdecl("__read_device_info__")
public func ReadDeviceInfo() {
    let deviceInfo = ProfilerAssets.DeviceInfo
}

@_cdecl("__read_cpu_stats_32__")
public func ReadCpuStats32() -> UInt32 {
    return CpuProfiler.readCpuStats32()
}

@_cdecl("__read_gpu_stats__")
public func ReadGpuStats() -> Int {
    return GpuProfiler.readGpuStats()
}

@_cdecl("__read_vm_stats__")
public func ReadVmStats() -> UInt64 {
    let packedStats = MemoryProfiler.readMemoryStats()
    return packedStats
}

