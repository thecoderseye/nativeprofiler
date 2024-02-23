//
//  GpuProfiler.swift
//  nativeplugins
//
//  Created by Seunghyun Roh on 22/2/24.
//

import Foundation
import Metal

public struct GpuProfiler {

    private static let shared = GpuProfiler()
    private static let device = MTLCreateSystemDefaultDevice()
    
    public static func begin() {
    }
    
    public static func end() {
        
    }
    
    public init() {

    }
    
    public static func readGpuStats() -> Int {
        //Total amount of memory in bytes that GPU device is using for all of its resources
        //The current size in bytes of all resources allocated by this device
        let allocatedMemory = device!.currentAllocatedSize / Int(Unit.MB.rawValue)
        return allocatedMemory
    }
}
