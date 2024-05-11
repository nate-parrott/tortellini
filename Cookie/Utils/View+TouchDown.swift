import SwiftUI

struct OnTouchDownModifier: ViewModifier {
    var atBottomOfScreen: Bool
    var haptics = true
    var enabled = true
    @Binding var touchDown: Bool
    var onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                VStack(spacing: 0) {
                    touchdownRegion
                    if hasNotch() && atBottomOfScreen {
                        touchUpRegion.frame(height: 5)
                    }
                }
            }
            .coordinateSpace(name: coordSpaceId)
            .onChange(of: touchDown) { newValue in
                if newValue, haptics {
                    Haptics.shared.performSoftHaptic()
                }
            }
    }

    private var coordSpaceId: String { "OnTouchDownModifier" }

    @ViewBuilder private var touchdownRegion: some View {
        Color.clear.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged({ gesture in
                    self.touchDown = gesture.dragDist < 100 && enabled
                }).onEnded({ _ in
                    guard enabled else { return }
                    if self.touchDown {
                        self.onTap()
                    }
                    self.touchDown = false
                }))
    }

    @ViewBuilder private var touchUpRegion: some View {
        Color.clear.contentShape(Rectangle())
            .onTapGesture {
                guard enabled else { return }
                if haptics {
                    Haptics.shared.performSoftHaptic()
                }
                self.onTap()
            }
    }
}

private extension DragGesture.Value {
    var dragDist: CGFloat {
        sqrt(pow(translation.width, 2) + pow(translation.height, 2))
    }
}

func hasNotch() -> Bool {
    UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0
}
