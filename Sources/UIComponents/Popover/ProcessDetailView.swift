import SwiftUI
import MonitorEngine

public struct ProcessDetailView: View {
    let sample: ProcessSample
    let processKiller: ProcessKiller

    @State private var selectedPID: Int32?
    @State private var showKillConfirmation = false

    public init(sample: ProcessSample, processKiller: ProcessKiller = SignalProcessKiller()) {
        self.sample = sample
        self.processKiller = processKiller
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Processes")
                    .font(MetricFonts.panelTitle)
                    .foregroundColor(MetricColors.process)
                Spacer()
                Text("\(sample.totalProcessCount) total")
                    .font(MetricFonts.panelDetail)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Name").frame(width: 120, alignment: .leading)
                Text("CPU%").frame(width: 50, alignment: .trailing)
                Text("Memory").frame(width: 60, alignment: .trailing)
                Text("").frame(width: 24)
            }
            .font(MetricFonts.panelDetail)
            .foregroundColor(.secondary)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(sample.topProcesses) { proc in
                        HStack {
                            Text(proc.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(width: 120, alignment: .leading)
                            Text(String(format: "%.1f", proc.cpuPercent))
                                .frame(width: 50, alignment: .trailing)
                            Text(ByteFormatter.format(proc.memoryBytes))
                                .frame(width: 60, alignment: .trailing)
                            Button(action: {
                                selectedPID = proc.pid
                                showKillConfirmation = true
                            }) {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.plain)
                            .frame(width: 24)
                        }
                        .font(MetricFonts.panelDetail)
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .alert("Silivue — Kill Process?", isPresented: $showKillConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Kill", role: .destructive) {
                if let pid = selectedPID {
                    _ = processKiller.terminate(pid: pid)
                }
            }
        } message: {
            if let pid = selectedPID, let proc = sample.topProcesses.first(where: { $0.pid == pid }) {
                Text("Are you sure you want to terminate \(proc.name)?")
            }
        }
    }
}
