import SwiftUI
import PuzzleAlarmCore

struct ChallengeHostView: View {
    @ObservedObject var model: ChallengeModel
    @State private var answer = ""
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let current = model.current {
                        if current.phase == .completed {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 64)).foregroundStyle(.green)
                            Text("You’re up!").font(.largeTitle.bold())
                            Text("All challenges are complete and this occurrence’s alarms have been cancelled.")
                            Button("Done") { model.dismissCompleted() }
                                .buttonStyle(.borderedProminent).accessibilityIdentifier("challenge.done")
                        } else if current.phase != .active {
                            Text("Finishing safely").font(.title.bold())
                            Text("Your answers are saved. Alarm cleanup must finish before this session is complete.")
                            Button("Retry cleanup") { Task { await model.refresh() } }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Text("Challenge \(current.challengeIndex + 1) of \(current.challengeCount)")
                                .font(.headline).foregroundStyle(.secondary)
                            ProgressView(value: Double(current.challengeIndex), total: Double(current.challengeCount))
                            challenge(current)
                        }
                    }
                    if let feedback = model.feedback { Text(feedback).foregroundStyle(.orange) }
                    if let error = model.errorMessage {
                        Text(error).foregroundStyle(.red)
                        Button("Retry") { Task { await model.refresh() } }
                    }
                    if model.busy { ProgressView("Saving progress") }
                }
                .padding(24)
                .frame(maxWidth: 580)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Wake up")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(model.busy)
            .onChange(of: identity) { _, _ in answer = "" }
            .task(id: identity) {
                while !Task.isCancelled {
                    guard let current = model.current,
                          case let .memory(_, digits, _, _, _, _) = current.content,
                          digits != nil else { return }
                    do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
                    await model.tick()
                }
            }
        }
    }

    @ViewBuilder
    private func challenge(_ displayed: ChallengeSnapshot) -> some View {
        switch displayed.content {
        case let .math(id, prompt, count, required):
            Text("Math").font(.largeTitle.bold())
            Text("\(count) of \(required) correct").foregroundStyle(.secondary)
            Text(prompt).font(.system(.largeTitle, design: .rounded).bold())
                .accessibilityIdentifier("challenge.math.prompt")
            answerField(label: "Your answer", displayed: displayed) {
                .submitMath(problemID: id, answer: $0)
            }
        case let .memory(id, digits, _, deadline, count, required):
            Text("Memory").font(.largeTitle.bold())
            Text("\(count) of \(required) rounds complete").foregroundStyle(.secondary)
            memoryInput(roundID: id, digits: digits, deadline: deadline, displayed: displayed)
        case .qr:
            Text("Scan your QR code").font(.largeTitle.bold())
            Text("Find the code you registered for this alarm.")
            #if DEBUG && targetEnvironment(simulator)
            if model.supportsPreview {
                Text("Simulated camera input for this preview").font(.callout).foregroundStyle(.secondary)
                Button("Simulate registered QR") { Task { await model.simulateQR(matches: true, expecting: displayed) } }
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("challenge.qr.correct")
                Button("Simulate another QR") { Task { await model.simulateQR(matches: false, expecting: displayed) } }
                    .buttonStyle(.bordered)
            } else {
                QRScannerView { payload in Task { await model.submit(.scanQR(payload: payload), expecting: displayed) } }
                    .frame(height: 320)
            }
            #else
            QRScannerView { payload in Task { await model.submit(.scanQR(payload: payload), expecting: displayed) } }
                .frame(height: 320)
            #endif
        case .waiting, .finished:
            ProgressView("Restoring challenge")
        }
    }

    private func memoryInput(roundID: UUID, digits: [Int]?, deadline: Date?, displayed: ChallengeSnapshot) -> some View {
        // Presentation hides at the absolute deadline independently of disk I/O.
        // An inactive app also omits digits from its rendered/accessibility tree.
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            if scenePhase != .active {
                Text("Paused")
            } else if let digits, let deadline, model.now < deadline {
                VStack(spacing: 16) {
                    Text("Remember these digits")
                    Text(digits.map(String.init).joined(separator: " "))
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.4).lineLimit(1)
                        .accessibilityIdentifier("challenge.memory.visible")
                    Text("The digits will hide automatically.").foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Enter the digits in the same order.")
                    answerField(label: "Remembered digits", displayed: displayed) { .submitMemory(roundID: roundID, answer: $0) }
                }
            }
        }
    }

    private func answerField(label: String, displayed: ChallengeSnapshot,
                             action: @escaping (String) -> ChallengeCommand.Action) -> some View {
        VStack(spacing: 16) {
            TextField(label, text: $answer)
                .keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder)
                .font(.title2).multilineTextAlignment(.center)
                .accessibilityIdentifier("challenge.answer")
                .submitLabel(.done)
                .onSubmit { send(action, displayed: displayed) }
            Button("Check answer") { send(action, displayed: displayed) }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("challenge.submit")
        }
    }

    private func send(_ action: (String) -> ChallengeCommand.Action, displayed: ChallengeSnapshot) {
        let command = action(answer)
        answer = ""
        Task { await model.submit(command, expecting: displayed) }
    }

    private var identity: String {
        guard let current = model.current else { return "none" }
        let item: String
        switch current.content {
        case let .math(id, _, _, _), let .memory(id, _, _, _, _, _): item = id.uuidString
        default: item = "other"
        }
        return "\(current.sessionID)-\(current.challengeIndex)-\(item)"
    }
}
