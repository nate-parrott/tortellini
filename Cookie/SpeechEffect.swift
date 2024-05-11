import SwiftUI

struct SpeechEffect: ViewModifier {
    var strength: Double = 1
    let startDate = Date()

    func body(content: Content) -> some View {
        TimelineView(.animation) { context in
            content
                .layerEffect(
                    ShaderLibrary.speechEffect(.float(strength), .float(startDate.timeIntervalSinceNow)
                    ),
                    maxSampleOffset: .init(width: 1, height: 100))
        }
    }
}


#Preview {
    RecipeView(recipe: .stub, parsed: Recipe.stub.parsed!)
}
