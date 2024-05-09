import SwiftUI

enum Styling {
    static let padding: CGFloat = 22
    static let appBodyLineSpacing: CGFloat = 12
}

extension Font {
    static var appBody: Font {
        .system(.title3, design: .rounded, weight: .medium)
    }
}

struct RecipeView: View {
    var recipe: Recipe
    var parsed: ParsedRecipe

    var body: some View {
        VStack(spacing: 0) {
            FocusedScrollView(items: cells) { cell in
                Group {
                    switch cell {
                    case .header:
                        RecipeHeader(recipe: recipe, parsed: parsed)
                    case .step(let idx, let step):
                        StepView(idx: idx, step: step, generating: recipe.generating ?? false)
                    }
                }
                .font(.appBody)

                Spacer().frame(height: 150)
            }
            .lineSpacing(Styling.appBodyLineSpacing)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)

            Footer()
        }
    }

    enum Cell: Identifiable {
        case header
        case step(Int, Step)

        var id: String {
            switch self {
            case .header:
                return "header"
            case .step(let idx, _):
                return "step:\(idx)"
            }
        }
    }

    var cells: [Cell] {
        [.header] + parsed.steps.enumerated().map { Cell.step($0.0, $0.1) }
    }
}

struct RecipeHeroImage: View {
    var url: URL?

    var body: some View {
        StretchyHero {
            FillerGradient()
                .overlay {
                    AsyncImage(
                        url: url,
                        content: { $0.resizable().interpolation(.high).aspectRatio(contentMode: .fill).background(.white) }, 
                        placeholder: { EmptyView() }
                    )
                }
//                Image("SampleHeader")
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
        }
    }
}

private struct FillerGradient: View {
    var body: some View {
        LinearGradient(colors: [Color.white, Color.black], startPoint: .top, endPoint: .bottom)
            .opacity(0.5)
            .blendMode(.overlay)
            .background(.purple)
    }
}

struct RecipeHeader: View {
    var recipe: Recipe
    var parsed: ParsedRecipe

    var body: some View {
        VStack {
            RecipeHeroImage(url: recipe.image)

            VStack(spacing: 16) {
                Group {
                    Text(parsed.title)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .lineSpacing(6)
                        .padding(.top, 18)

                    if let description = parsed.description {
                        Text(description.cleanedUp)
                            .lineSpacing(4)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 6)

                if parsed.ingredients.count > 0 {
                    IngredientsUnit(ingredients: parsed.ingredients)
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, Styling.padding)
        }
        .multilineTextAlignment(.center)
    }
}

struct IngredientsUnit: View {
    var ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEachUnidentifiable(items: ingredients) { ing in
                Label(
                    title: { Text(ing.text.cleanedUp) },
                    icon: { EmojiView(emoji: ing.emoji) }
                )
            }
        }
        .lineLimit(nil)
        .multilineTextAlignment(.leading)
        .padding()
        .padding(.leading, -4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quinary)
        }
    }
}

struct StepView: View {
    var idx: Int // zero indexed
    var step: Step
    var generating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            (
                Text("\(idx + 1)  ").foregroundStyle(.tertiary)
                + Text(step.title)
            )
            .lineSpacing(3)
//            .bold()
            .font(.system(.title, design: .rounded, weight: .bold))

            if let formattedText = step.formattedText {
                FormattedTextView(parts: formattedText )
            } else {
                Text(step.text)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
                    .opacity(generating ? 0.5 : 1)
            }
        }
        .font(.appBody)
        .padding(.horizontal, Styling.padding)
    }
}

struct FormattedTextView: View {
    var parts: [Step.FormattedText]

    var body: some View {
        WrappingHStack(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0, fitContentWidth: false) {
            ForEachUnidentifiable(items: parts) { part in
                partView(part)
                    .padding(.bottom, Styling.appBodyLineSpacing)
            }
        }
    }

    @ViewBuilder private func partView(_ part: Step.FormattedText) -> some View {
        switch part {
        case .plain(let string):
            ForEachUnidentifiable(items: string.cleanedUp.splittingButKeepingSpaces) { word in
                Text(word)
            }
        case .bold(let string):
            ForEachUnidentifiable(items: string.cleanedUp.splittingButKeepingSpaces) { word in
                Text(word).bold()
            }
        case .ingredient(let ingredient):
            ForEach(ingredient.text.cleanedUp.splittingButKeepingSpaces.identifiableByIndices) { tuple in
                Text(tuple.item)
                    .foregroundStyle(.purple)
            }
            if let missingInfo = ingredient.missingInfo?.nilIfEmpty?.cleanedUp {
                let text = " (" + missingInfo + ")"
                ForEach(text.splittingButKeepingSpaces.identifiableByIndices) {
                    Text($0.item)
                        .foregroundStyle(.purple)
                }
            }

            Text(ingredient.emoji)
        case .timer(let cookTimer):
            ForEach(cookTimer.asText.splittingButKeepingSpaces.identifiableByIndices) { tuple in
                Group {
                    if tuple.index == 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.fill")
                            Text(tuple.item)
                        }
                    } else {
                        Text(tuple.item)
                    }
                }
                .foregroundStyle(.blue)
            }
        }
    }
}

//extension Step {
//    var formattedTextBySplittingWords: [Step.FormattedText] {
//        (formattedText ?? [])
//            .flatMap { item in
//                if case let .plain(text) = item {
//                    return text.splittingButKeepingSpaces
//                        .map { Step.FormattedText.plain(String($0)) }
//                }
//                return [item]
//            }
//    }
//}

extension String {
    var splittingButKeepingSpaces: [String] {
        let parts = components(separatedBy: " ")
        var out = [String]()
        for (idx, item) in parts.enumerated() {
            if idx + 1 < parts.count {
                out.append(item + " ")
            } else {
                out.append(item)
            }
        }
        return out
    }
}

extension Ingredient {
    var titleText: Text {
        var text = Text(self.text)
        if let details = self.missingInfo?.nilIfEmptyOrJustWhitespace {
            text = text + Text(" (\(details))")
                .foregroundStyle(.secondary)
        }
        return text
    }
}

//struct InlineTimer: View {
//    var timer: CookTimer
//    var body: some View {
//
//        Button(action: startTimer, label: {
//            HStack {
//                Image(systemName: "timer")
//                    .foregroundStyle(.tint)
//                Text(timer.asText)
//            }
//        })
//        .buttonStyle(InlineButtonStyle())
//    }
//
//    private func startTimer() {
//        // TODO
//    }
//}
//
//struct InlineIngredient: View {
//    var ingredient: Ingredient
//    var body: some View {
//        Button(action: {}, label: {
//            HStack(spacing: 2) {
//                Text(ingredient.emoji)
//
//                ingredient.titleText
//            }
//            .padding(.trailing, 4)
//        })
//        .buttonStyle(InlineButtonStyle())
//    }
//}
//
//struct InlineButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        let scale: CGFloat = configuration.isPressed ? 0.9 : 1
//        configuration.label
//            .fontWeight(.medium)
//            .padding(.vertical, 3)
//            .background {
//                RoundedRectangle(cornerRadius: 4, style: .continuous)
//                    .fill(.quinary)
//            }
//            .padding(4)
//            .contentShape(Rectangle())
//            .padding(-4)
//            .padding(.vertical, -3)
//            .scaleEffect(scale)
//            .animation(.bouncy, value: scale)
//    }
//}

struct FocusedScrollView<Item: Identifiable, V: View>: View {
    var items: [Item]
    @ViewBuilder var view: (Item) -> V

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 40) {
                ForEach(items) { item in
                    view(item)
                }
            }
        }
        .ignoresSafeArea([.container], edges: .top)
    }
}

#Preview {
    RecipeView(recipe: .stub, parsed: Recipe.stub.parsed!)
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
}
