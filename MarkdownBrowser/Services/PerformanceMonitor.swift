import Foundation
import os.log

/// A service for monitoring and logging performance metrics
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.markdownbrowser", category: "Performance")
    
    /// Performance metrics storage
    private var metrics: [String: [TimeInterval]] = [:]
    private let metricsQueue = DispatchQueue(label: "com.markdownbrowser.performancemonitor")
    
    /// Maximum number of metrics to store per operation
    private let maxMetricsPerOperation = 100
    
    /// Start tracking an operation
    func startOperation(_ name: String) -> PerformanceTracker {
        return PerformanceTracker(operationName: name, monitor: self)
    }
    
    /// Record a completed operation
    func recordOperation(_ name: String, duration: TimeInterval, metadata: [String: Any]? = nil) {
        metricsQueue.async {
            if self.metrics[name] == nil {
                self.metrics[name] = []
            }
            
            self.metrics[name]?.append(duration)
            
            // Keep only the most recent metrics
            if let count = self.metrics[name]?.count, count > self.maxMetricsPerOperation {
                self.metrics[name]?.removeFirst(count - self.maxMetricsPerOperation)
            }
        }
        
        // Log the operation
        let durationMs = duration * 1000
        var logMessage = "[\(name)] completed in \(String(format: "%.2f", durationMs))ms"
        
        if let metadata = metadata {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            logMessage += " - \(metadataString)"
        }
        
        logger.info("\(logMessage)")
        
        // Warn if operation took too long
        if durationMs > 500 {
            logger.warning("[\(name)] took longer than expected: \(String(format: "%.2f", durationMs))ms")
        }
    }
    
    /// Get statistics for an operation
    func getStatistics(for operation: String) -> PerformanceStatistics? {
        var stats: PerformanceStatistics?
        
        metricsQueue.sync {
            guard let metrics = self.metrics[operation], !metrics.isEmpty else {
                return
            }
            
            let sortedMetrics = metrics.sorted()
            let count = metrics.count
            let sum = metrics.reduce(0, +)
            let average = sum / Double(count)
            let median = count % 2 == 0 
                ? (sortedMetrics[count/2 - 1] + sortedMetrics[count/2]) / 2
                : sortedMetrics[count/2]
            let p95Index = Int(Double(count) * 0.95)
            let p95 = sortedMetrics[min(p95Index, count - 1)]
            
            stats = PerformanceStatistics(
                operationName: operation,
                sampleCount: count,
                average: average,
                median: median,
                min: sortedMetrics.first ?? 0,
                max: sortedMetrics.last ?? 0,
                p95: p95
            )
        }
        
        return stats
    }
    
    /// Clear all metrics
    func clearMetrics() {
        metricsQueue.async {
            self.metrics.removeAll()
        }
    }
    
    /// Log memory usage
    func logMemoryUsage(context: String) {
        let info = ProcessInfo.processInfo
        let physicalMemory = info.physicalMemory
        
        var memInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &memInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemoryMB = Double(memInfo.resident_size) / 1024 / 1024
            logger.info("[\(context)] Memory usage: \(String(format: "%.1f", usedMemoryMB))MB")
            
            if usedMemoryMB > 200 {
                logger.warning("[\(context)] High memory usage detected: \(String(format: "%.1f", usedMemoryMB))MB")
            }
        }
    }
}

/// A helper class for tracking operation performance
class PerformanceTracker {
    private let operationName: String
    private let startTime: Date
    private weak var monitor: PerformanceMonitor?
    private var metadata: [String: Any] = [:]
    
    init(operationName: String, monitor: PerformanceMonitor) {
        self.operationName = operationName
        self.startTime = Date()
        self.monitor = monitor
    }
    
    /// Add metadata to the operation
    func addMetadata(_ key: String, value: Any) {
        metadata[key] = value
    }
    
    /// Complete the operation and record metrics
    func complete() {
        let duration = Date().timeIntervalSince(startTime)
        monitor?.recordOperation(operationName, duration: duration, metadata: metadata)
    }
}

/// Performance statistics for an operation
struct PerformanceStatistics {
    let operationName: String
    let sampleCount: Int
    let average: TimeInterval
    let median: TimeInterval
    let min: TimeInterval
    let max: TimeInterval
    let p95: TimeInterval
    
    var summary: String {
        return """
        Performance Statistics for \(operationName):
        - Samples: \(sampleCount)
        - Average: \(String(format: "%.2f", average * 1000))ms
        - Median: \(String(format: "%.2f", median * 1000))ms
        - Min: \(String(format: "%.2f", min * 1000))ms
        - Max: \(String(format: "%.2f", max * 1000))ms
        - P95: \(String(format: "%.2f", p95 * 1000))ms
        """
    }
}

// MARK: - CSV-specific performance tracking

extension PerformanceMonitor {
    /// Track CSV parsing performance
    func trackCSVParsing(rowCount: Int, columnCount: Int) -> PerformanceTracker {
        let tracker = startOperation("CSV_Parse")
        tracker.addMetadata("rows", value: rowCount)
        tracker.addMetadata("columns", value: columnCount)
        tracker.addMetadata("cells", value: rowCount * columnCount)
        return tracker
    }
    
    /// Track CSV rendering performance
    func trackCSVRendering(rowCount: Int, columnCount: Int, htmlSize: Int) -> PerformanceTracker {
        let tracker = startOperation("CSV_Render")
        tracker.addMetadata("rows", value: rowCount)
        tracker.addMetadata("columns", value: columnCount)
        tracker.addMetadata("html_size_kb", value: htmlSize / 1024)
        return tracker
    }
    
    /// Track CSV file loading
    func trackCSVFileLoad(fileSize: Int64) -> PerformanceTracker {
        let tracker = startOperation("CSV_FileLoad")
        tracker.addMetadata("file_size_kb", value: fileSize / 1024)
        return tracker
    }
    
    /// Log CSV performance summary
    func logCSVPerformanceSummary() {
        if let parseStats = getStatistics(for: "CSV_Parse") {
            logger.info("\(parseStats.summary)")
        }
        
        if let renderStats = getStatistics(for: "CSV_Render") {
            logger.info("\(renderStats.summary)")
        }
        
        if let loadStats = getStatistics(for: "CSV_FileLoad") {
            logger.info("\(loadStats.summary)")
        }
    }
}