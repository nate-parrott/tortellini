import SwiftUI

struct Footer: View {
    @State private var voiceAssistantActive = false

    var body: some View {
        VoiceAssistantButton(active: .init(get: { voiceAssistantActive }, set: { AppStore.shared.model.voiceAssistantActive = $0 }))
            .onReceive(AppStore.shared.publisher.map(\.voiceAssistantActive).removeDuplicates()) { voiceAssistantActive = $0 }
            .padding()
            .background {
                Color.black.ignoresSafeArea(edges: .all)
            }
    }
}

struct VoiceAssistantButton: View {
    @Binding var active: Bool
    @State private var touchDown = false

    var body: some View {
        HStack {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 24))


            Group {
                if active {
                    Text("Say ") + Text(" “Hey, Tortellini”")
                } else {
                    Text("Voice Assistant")
                }
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50)
        .foregroundStyle(.white)
        .background(FooterButtonBackdrop(highlightColor: active ? Color.red : nil))
        .compositingGroup()
        .opacity(touchDown ? 0.95 : 1)
        .scaleEffect(touchDown ? 0.98 : 1)
        .modifier(OnTouchDownModifier(atBottomOfScreen: true, touchDown: $touchDown, onTap: { active.toggle() }))
    }
}

//
//struct Footer: View {
//    struct Snapshot: Equatable {
//        var timers = [InProgressTimer]()
//        var voiceAssistantActive = false
//    }
//
//    @State private var snapshot = Snapshot()
//    @State private var width: CGFloat?
//    @State private var showingVoiceDebug = false
//
//    var body: some View {
//        ScrollView(.horizontal) {
//            HStack(spacing: 12) {
//                Button(action: { AppStore.shared.model.voiceAssistantActive.toggle() }, label: {
//                    AssistantMuteView(active: snapshot.voiceAssistantActive, isOnlyItem: footerItemsCount == 1)
//                })
//                .buttonStyle(FooterButtonStyle(footerItemsCount: footerItemsCount, highlightColor: snapshot.voiceAssistantActive ? Color.red : nil))
//
//                ForEach(snapshot.timers) { timer in
//                    Button(action: { editTimer(timer) }, label: {
//                        TimerView(timer: timer)
//                    })
//                }
//            }
//            .padding([.horizontal, .top], 12)
//            .frame(width: footerItemsCount <= 2 ? width : nil)
//        }
//        .measureSize { self.width = $0.width }
//        .background {
//            Color.black.edgesIgnoringSafeArea(.all)
//        }
//        .buttonStyle(FooterButtonStyle(footerItemsCount: footerItemsCount))
//        .scrollIndicators(.never)
//        .onReceive(AppStore.shared.publisher.map { Snapshot(timers: $0.timers /*+ [.stub, .stub2] */, voiceAssistantActive: $0.voiceAssistantActive) }, perform: { snapshot in
//            self.snapshot = snapshot
//        })
//        .onChange(of: snapshot.voiceAssistantActive) { newValue in
//            if newValue {
//                showingVoiceDebug = true
//            }
//        }
////        .sheet(isPresented: $showingVoiceDebug) {
////            VoiceAssistantDebug()
////        }
//    }
//
//    private var footerItemsCount: Int {
//        snapshot.timers.count + 1 // +1 for voice
//    }
//
//    private func editTimer(_ timer: InProgressTimer) {
//        // todo
//    }
//}
//
//struct TimerView: View {
//    var timer: InProgressTimer
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(timer.original.asText)
//                .font(.system(.caption, weight: .medium))
//                .opacity(0.8)
//
//            Text("1:23")
//                .monospacedDigit()
//                .font(.system(.body, design: .monospaced))
//        }
//    }
//}
//
//struct AssistantMuteView: View {
//    var active: Bool
//    var isOnlyItem: Bool
//
//    var body: some View {
//        HStack {
//            Image(systemName: "mic.circle.fill")
//                .font(.system(size: 24))
//
//
//            Group {
//                if active {
//                    if isOnlyItem {
//                        Text("Say ") + Text(" “Hey, Chef”")
//                    } else {
//                        Text("Say ") + Text(" “Hey, Chef...”")
//                    }
//                } else {
//                    Text("Voice Assistant")
//                }
//            }
//            .font(.system(size: 18, weight: .semibold, design: .rounded))
//        }
//    }
//}
//

private struct FooterButtonBackdrop: View {
    var highlightColor: Color?

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

        ZStack {
            shape
                .fill(Color.white.opacity(0.25))

            if let highlightColor {
                shape.fill(highlightColor)

                shape.fill(LinearGradient(colors: [Color.white, Color.black], startPoint: .top, endPoint: .bottom))
                    .blendMode(.overlay)
                    .opacity(0.5)
            }
        }
    }
}

//struct FooterButtonStyle: ButtonStyle {
//    var footerItemsCount: Int
//    var highlightColor: Color?
//
//    func makeBody(configuration: Configuration) -> some View {
//        let scale = configuration.isPressed ? 0.9 : 1
//        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
//
//        configuration.label
//            .padding(.leading, 14)
//            .padding(.vertical, 6)
//            .padding(.trailing, 12)
////            .fixedSize(horizontal: footerItemsCount , vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
////            .frame(width: footerItemsCount <= 2 ? nil : 200, height: 50, alignment: .leading)
//            .frame(height: 60)
//            .frame(maxWidth: footerItemsCount <= 2 ? .infinity : nil, alignment: .leading)
//            .foregroundStyle(.white)
//            .font(.system(.body, design: .rounded, weight: .medium))
//            .multilineTextAlignment(.leading)
//            .background {
//                shape
//                    .fill(Color.white.opacity(0.25))
//
//                if let highlightColor {
//                    shape.fill(highlightColor)
//
//                    shape.fill(LinearGradient(colors: [Color.white, Color.black], startPoint: .top, endPoint: .bottom))
//                        .blendMode(.overlay)
//                        .opacity(0.5)
//                }
//            }
////            .scaleEffect(scale)
////            .animation(.bouncy, value: scale)
//    }
//}
//
//extension InProgressTimer {
//    static var stub: InProgressTimer {
//        .init(id: "???", recipeId: "??", original: CookTimer(asText: "cook pasta for 10 minutes", seconds: 10 * 60), repeatedAlready: 0, started: Date.distantPast)
//    }
//
//    static var stub2: InProgressTimer {
//        .init(id: "???2", recipeId: "??2", original: CookTimer(asText: "cook pasta for 15 minutes", seconds: 10 * 60), repeatedAlready: 0, started: Date.distantPast)
//    }
//}
//
//#Preview {
//    VStack(spacing: 0) {
//        Color.blue
//        Footer()
//    }
//}
