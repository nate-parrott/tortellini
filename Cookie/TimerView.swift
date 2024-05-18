import SwiftUI

struct TimerPIP: View {
    var timer: InProgressTimer
    var expanded = false
    var mainTapAction: (() -> Void)?

    @State private var tick: Date?

    var body: some View {
        let kRadius: CGFloat = expanded ? 1.5 : 1

        main
        .background {
            Color.black
            Color.blue.opacity(0.1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12 * kRadius, style: .continuous))
        .padding(expanded ? 8 : 4)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16 * kRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16 * kRadius, style: .continuous)
                .stroke(LinearGradient(colors: [Color.white, Color.black], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                .opacity(0.2)
        }
        .overlay {
            if let mainTapAction {
                Color.white.opacity(0.01)
                    .onTapGesture(perform: mainTapAction)
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 10, y: 20)
        .onReceive(
            Timer.publish(every: 1, on: RunLoop.main, in: .common).autoconnect(),
            perform: { self.tick = $0 })
    }

    var mainFont: Font {
        if expanded {
            return .system(.largeTitle, design: .monospaced, weight: .medium)
        }
        return .system(.title2, design: .monospaced, weight: .medium)
    }

    var titleFont: Font {
        if expanded {
            return .title2
        }
        return .subheadline
    }

    @ViewBuilder var main: some View {
        VStack(alignment: .leading, spacing: expanded ? 10 : 6) {
            if timer.remainingSeconds == 0 {
                Text("Timer finished")
                    .foregroundStyle(.red)
                    .font(.system(.body, weight: .bold))
            }

            Text(timer.remainingTime)
                .monospacedDigit()
                .font(mainFont)

            Text(timer.original.asText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if expanded {
                controls
            }
        }
        .onChange(of: timer.remainingSeconds == 0, perform: { done in
            if done {
                AppStore.shared.model.focusedTimerId = self.timer.id
            }
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            // fake dependency
            if let tick { EmptyView() }
        }
        .colorScheme(.dark)
        .padding(expanded ? 16 : 10)
    }

    @ViewBuilder var controls: some View {
        HStack(spacing: 12) {
            if timer.isFinished {
                Button(action: done) {
                    Text("Done")
                }
                .buttonStyle(TimerPIPButtonStyle(bgColor: .red, fgColor: .white))
            } else {
                Button(action: done) {
                    Text("Stop")
                }
                .buttonStyle(TimerPIPButtonStyle(bgColor: .red, fgColor: .white))
            }

            if timer.isFinished && timer.remainingRepeats > 0 {
                Button(action: repeatAgain) {
                    Text("Repeat")
                }
                .buttonStyle(TimerPIPButtonStyle(bgColor: .blue))
            } else {
                Button(action: addOneMin) {
                    Text("+1 Minute")
                }
                .buttonStyle(TimerPIPButtonStyle())
            }
        }
    }

    func done() {
        AppStore.shared.modify { state in
            state.timers.removeAll(where: { $0.id == self.timer.id })
        }
    }

    func repeatAgain() {
        AppStore.shared.modify { state in
            guard let idx = state.timers.firstIndex(where: { $0.id == self.timer.id }) else {
                return
            }
            state.timers[idx].repeatedAlready += 1
            state.timers[idx].remainingSeconds = timer.original.seconds
        }
    }

    func addOneMin() {
        AppStore.shared.modify { state in
            guard let idx = state.timers.firstIndex(where: { $0.id == self.timer.id }) else {
                return
            }
            state.timers[idx].remainingSeconds += 60
        }
    }
}

struct TimerPIPButtonStyle: ButtonStyle {
    var bgColor: Color = Color.white.opacity(0.2)
    var fgColor: Color = Color.white

    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .font(.system(.body, weight: .bold))
            .foregroundStyle(fgColor)
            .padding(8)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(bgColor)
                    .opacity(configuration.isPressed ? 0.5 : 1)
            }
            .onChange(of: configuration.isPressed, perform: { value in
                if value {
                    Haptics.shared.performSelectionHaptic()
                }
            })
    }
}

extension InProgressTimer {
    static var stub: InProgressTimer {
        .init(id: "???", recipeId: "??", original: CookTimer(asText: "cook pasta for 10 minutes", seconds: 10 * 60), repeatedAlready: 0, started: Date.now)
    }

    static var stub2: InProgressTimer {
        .init(id: "???2", recipeId: "??2", original: CookTimer(asText: "cook pasta for 15 minutes", seconds: 10 * 60), repeatedAlready: 0, started: Date.distantPast)
    }
}

#Preview {
    VStack(spacing: 100) {
        TimerPIP(timer: .stub)
            .frame(width: 160)
        TimerPIP(timer: .stub, expanded: true)
            .frame(width: 300)
        TimerPIP(timer: .stub2, expanded: true)
            .frame(width: 300)
    }
    .padding(100)
}
