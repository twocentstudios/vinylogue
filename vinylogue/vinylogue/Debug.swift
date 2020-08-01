import Foundation

enum Debug {
    static func profile(name: String = String(UUID().uuidString.prefix(3)), _ block: () -> ()) {
        let start = mach_absolute_time()

        block()

        let elapsedMTU = mach_absolute_time() - start
        var timebase = mach_timebase_info()
        if mach_timebase_info(&timebase) == 0 {
            let elapsedNanoseconds = Double(elapsedMTU) * Double(timebase.numer) / Double(timebase.denom)
            let elapsedMilliseconds = elapsedNanoseconds * 1.0E-6
            print("\(name) - \(elapsedMilliseconds)ms")
        }
        else {
            print("\(name) - error)")
        }
    }

    static func profileStart() -> UInt64 {
        return mach_absolute_time()
    }

    static func profileEnd(start: UInt64, name: String = String(UUID().uuidString.prefix(3))) {
        let elapsedMTU = mach_absolute_time() - start
        var timebase = mach_timebase_info()
        if mach_timebase_info(&timebase) == 0 {
            let elapsedNanoseconds = Double(elapsedMTU) * Double(timebase.numer) / Double(timebase.denom)
            let elapsedMilliseconds = elapsedNanoseconds * 1.0E-6
            print("\(name) - \(elapsedMilliseconds)ms")
        }
        else {
            print("\(name) - error)")
        }
    }
}
