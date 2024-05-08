import SwiftUI

struct StretchyHero<C: View>: View {
    var aspect: CGFloat = 1.6
    @ViewBuilder var content: () -> C

    var body: some View {
        Color.clear.aspectRatio(aspect, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    let overscroll: CGFloat = max(0, geo.frame(in: .scrollView(axis: .vertical)).minY)
                    let scale = (geo.size.height + overscroll) / max(geo.size.height, 1)

                    content()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .scaleEffect(scale, anchor: .bottom)
                }
            }
//            .padding(.top, -200)
//            .clipShape(Rectangle())
//            .padding(.top, 200)
            .ignoresSafeArea([.container], edges: .top)
//            .border(.blue, width: 2)
    }
}

struct EmojiView: View {
    var emoji: String
    var bgColor: Color = .clear

    @State private var size: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.15, style: .continuous)
            .fill(bgColor)
            .frame(both: size + 6)
            .overlay {
                Text(emoji)
                    .font(.system(size: floor(size * 0.72)))
            }
            .background {
                Text("M")
                    .opacity(0)
                    .measureSize { self.size = $0.height }
                    .accessibilityHidden(true)
            }
    }
}
