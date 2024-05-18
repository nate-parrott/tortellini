import SwiftUI

struct TimerOverlay: View {
    @State private var snapshot = Snapshot(timers: [])
    @Namespace private var namespace

    struct Snapshot: Equatable {
        var timers: [InProgressTimer]
        var focusedTimerId: String?

        func timersBeneath(timer: InProgressTimer) -> Int {
            // Count how many timers exist at the same pos
            var count = 0
            for t in self.timers {
                if t == timer {
                    break
                }
                if t.unitPos == timer.unitPos {
                    count += 1
                }
            }
            return count
        }
    }

    var body: some View {
        floatingTimers
        .padding()
//        .overlay(alignment: .topLeading) {
//            Button(action: createFakeDate) {
//                Text("Setup")
//            }
//        }
        .overlay {
            if let focusedId = snapshot.focusedTimerId, let timer = snapshot.timers.first(where: { $0.id == focusedId }) {
                Color.black.edgesIgnoringSafeArea(.all)
                    .opacity(0.7)
                    .onTapGesture {
                        focusTimer(nil)
                    }

                TimerPIP(timer: timer, expanded: true)
                    .matchedGeometryEffect(id: timer.id, in: namespace)
                    .padding(40)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1), value: snapshot.focusedTimerId)
        .onReceive(AppStore.shared.publisher.map { Snapshot(timers: $0.timers, focusedTimerId: $0.focusedTimerId) }) { self.snapshot = $0 }
    }

    @ViewBuilder var floatingTimers: some View {
        GeometryReader { geo in
            ForEach(snapshot.timers) { timer in
                floatingTimer(timer: timer, bounds: geo.size)
            }
        }
    }

    @ViewBuilder func floatingTimer(timer: InProgressTimer, bounds: CGSize) -> some View {
        let index = snapshot.timers.firstIndex(of: timer)!
        let zIndex: Double = Double(index)
        let offset = CGFloat(snapshot.timersBeneath(timer: timer))

        if timer.id != snapshot.focusedTimerId {
            FloatingPuck(
                unitPos: timer.unitPos,
                extraOffset: CGPoint(x: offset * 10, y: offset * 10),
                didDragToUnitPos: { AppStore.shared.model.timers[index].unitPos = $0 }) {
                    TimerPIP(timer: timer, mainTapAction: { focusTimer(timer.id) })
                        .frame(width: 160)
                        .matchedGeometryEffect(id: timer.id, in: namespace)
                }
                .zIndex(zIndex)
        }
    }

    func focusTimer(_ id: String?) {
        AppStore.shared.model.focusedTimerId = id
    }

    func createFakeDate() {
        AppStore.shared.modify { state in
            state.timers = [
                InProgressTimer(id: UUID().uuidString, recipeId: "?", original: .init(asText: "Test Timer", seconds: 120), repeatedAlready: 0, started: Date()),
                InProgressTimer(id: UUID().uuidString, recipeId: "?", original: .init(asText: "Test Timer with very long long long name", seconds: 50), repeatedAlready: 0, started: Date()),
            ]
        }
    }
}

struct FloatingPuck<V: View>: View {
    var unitPos: CGPoint
    var extraOffset: CGPoint = .zero
    var didDragToUnitPos: (CGPoint) -> Void
    @ViewBuilder var view: () -> V

    @State private var translation: CGPoint?
    @State private var itemSize: CGSize?

    var body: some View {
        GeometryReader { geo in
            let rect = self.rect(bounds: geo.size)
            let dragging = translation != nil

            view()
                .measureSize { itemSize = $0 }
                .position(x: rect.midX, y: rect.midY)
                .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.1), value: [unitPos, translation, extraOffset])
//                .scaleEffect(dragging ? 1.1 : 1)
                .gesture(DragGesture().onChanged({ val in
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)) {
                        self.translation = CGPoint(x: val.translation.width, y: val.translation.height)
//                    }
                }).onEnded({ val in
                    let endPosUnit = curPosInUnitCoords(bounds: geo.size)
                    var endUnitPos = CGPoint(
                        x: endPosUnit.x < 0.5 ? 0 : 1,
                        y: endPosUnit.y < 0.5 ? 0 : 1
                    )
                    if abs(val.velocity.width) > 2000 {
                        endUnitPos.x = val.velocity.width > 0 ? 1 : 0
                    }
                    if abs(val.velocity.height) > 2000 {
                        endUnitPos.y = val.velocity.height > 0 ? 1 : 0
                    }

                    self.translation = nil
                    self.didDragToUnitPos(endUnitPos)
                }))
        }
    }

    func rect(bounds: CGSize) -> CGRect {
        let size: CGSize = itemSize ?? .init(width: 100, height: 100)
        let origin = CGPoint(
            x: lerp(x: unitPos.x, a: 0, b: bounds.width - size.width) + (translation?.x ?? 0) + extraOffset.x,
            y: lerp(x: unitPos.y, a: 0, b: bounds.height - size.height) + (translation?.y ?? 0) + extraOffset.y
        )
        return CGRect(origin: origin, size: size)
    }

    func curPosInUnitCoords(bounds: CGSize) -> CGPoint {
        guard let translation, let size = itemSize else {
            return unitPos
        }
        let maxXTranslation = max(1, bounds.width - size.width)
        let maxYTranslation = max(1, bounds.height - size.height)
        return CGPoint(
            x: unitPos.x + translation.x / maxXTranslation,
            y: unitPos.y + translation.y / maxYTranslation
        )
    }
}

extension InProgressTimer {
    var alignment: Alignment {
        switch (unitPos.x, unitPos.y) {
        case (0, 0): return .topLeading
        case (1, 0): return .topTrailing
        case (1, 1): return .bottomTrailing
        case (0, 1): return .bottomLeading
        default: return .bottomLeading
        }
    }
}

#Preview {
    TimerOverlay()
}
