import SwiftUI

enum Styling {
    static let padding: CGFloat = 18
    static let appBodyLineSpacing: CGFloat = 10
}

extension Font {
    static var appBody: Font {
        .system(.body, design: .rounded, weight: .medium)
    }
}

struct RecipeView: View {
    var recipe: Recipe
    var parsed: ParsedRecipe

    @StateObject private var voiceAssistant = VoiceAssistant()

    var body: some View {
        VStack(spacing: 0) {
            FocusedScrollView(items: cells) { cell in
                Group {
                    switch cell {
                    case .header:
                        RecipeHeader(recipe: recipe, parsed: parsed)

                    case .step(let idx, let step):
                        StepView(idx: idx, step: step, generating: recipe.generating ?? false, recipeId: recipe.id)
                            .frame(maxWidth: 650, alignment: .leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.appBody)
            }
            .lineSpacing(Styling.appBodyLineSpacing)
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            .overlay {
                TimerOverlay()
            }
            .overlay(alignment: .bottom) {
                voiceActivityOverlay
            }

            Footer()
        }
        .onReceive(AppStore.shared.publisher.map(\.voiceAssistantActive).removeDuplicates(), perform: { active in
            voiceAssistant.listening = active
        })
        .onAppear {
            AppStore.shared.modify { $0.lastActiveRecipe = recipe.id }
        }
        .onDisappear {
            voiceAssistant.listening = false
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

    @MainActor
    @ViewBuilder private var voiceActivityOverlay: some View {
        if voiceAssistant.recognizedSpeech || voiceAssistant.responding {
            ZStack {
                if voiceAssistant.recognizedSpeech {
                    BigIcon(name: "waveform.path", color: .blue)
                } else if voiceAssistant.responding {
                    BigIcon(name: "waveform.and.magnifyingglass", color: .green)
                }
            }
            .modifier(ScalePulsingModifier())
        }
    }
}

private struct BigIcon: View {
    var name: String
    var color: Color = .blue

    var body: some View {
        let bg = RoundedRectangle(cornerRadius: 16, style: .continuous)
        FillerGradient(color: color)
            .overlay {
                Image(systemName: name)
                    .font(.system(size: 50))
            }
            .foregroundColor(.white)
            .frame(both: 90)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .background {
                bg.fill(color)
                    .overlay {
                        bg.fill(Color.black.opacity(0.5))
                    }
                    .blur(radius: 15)
                    .opacity(0.1)
            }
            .padding(30)
            .allowsHitTesting(false)
    }
}

struct RecipeHeroImage: View {
    var url: URL?

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            // ipad
            Color.clear.aspectRatio(1.6, contentMode: .fit)
                .overlay {
                    main
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
                .frame(maxWidth: 750)
                .padding()
                .padding(.top, 30)
        } else {
            StretchyHero {
                main
            }
        }
    }

    @ViewBuilder var main: some View {
        FillerGradient()
            .overlay {
                AsyncImage(
                    url: url,
                    content: { $0.resizable().interpolation(.high).aspectRatio(contentMode: .fill).background(.white) },
                    placeholder: { EmptyView() }
                )
            }
    }
}

private struct FillerGradient: View {
    var color = Color.purple

    var body: some View {
        LinearGradient(colors: [Color.white, Color.black], startPoint: .top, endPoint: .bottom)
            .opacity(0.5)
            .blendMode(.overlay)
            .background(color)
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
                        .frame(maxWidth: 650)

                    if let description = parsed.description {
                        Text(description.cleanedUp)
                            .lineSpacing(4)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 400)
                    }
                }
                .padding(.horizontal, 6)

                if parsed.ingredientGroups.count > 0 {
                    IngredientsUnit(groups: parsed.ingredientGroups)
                        .frame(maxWidth: 650)
                        .padding(.top, 12)
                }
            }
            .padding(.horizontal, Styling.padding)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

struct IngredientsUnit: View {
    var groups: [ParsedRecipe.IngredientGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEachUnidentifiable(items: groups) { group in
                if let name = group.name, groups.count > 1 {
                    Text(name)
                        .foregroundStyle(.secondary)
                }
                ForEachUnidentifiable(items: group.ingredients) { ing in
                    Label(
                        title: { Text(ing.text.cleanedUp) },
                        icon: { EmojiView(emoji: ing.emoji) }
                    )
                }
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
    var recipeId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            (
                Text("\(idx + 1)  ").foregroundStyle(.tertiary)
                + Text(step.title)
            )
            .lineSpacing(3)
//            .bold()
            .font(.system(.title, design: .rounded, weight: .bold))

            if let formattedText = step.formattedText {
                FormattedTextView(parts: formattedText, recipeId: recipeId)
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
    var recipeId: String

    @State private var showingMissingInfoForIngredient: Ingredient?

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
                    .textTap {
                        tapped(ingredient: ingredient)
                    }
//                    .modifier(IngredientPopoverOnTap(ingredient: ingredient))
            }
            if let missingInfo = ingredient.missingInfo?.nilIfEmpty?.cleanedUp, showingMissingInfoForIngredient == ingredient {
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
                                .textTap {
                                    tapped(timer: cookTimer)
                                }
                        }
                    } else {
                        Text(tuple.item)
                            .textTap {
                                tapped(timer: cookTimer)
                            }
                    }
                }
                .foregroundStyle(.blue)
            }
        }
    }

    func tapped(timer: CookTimer) {
        AppStore.shared.modify { state in
            if let existing = state.timers.first(where: { $0.original == timer }) {
                state.focusedTimerId = existing.id
            } else {
                state.timers.append(InProgressTimer(id: UUID().uuidString, recipeId: recipeId, original: timer, repeatedAlready: 0, started: Date()))
            }
        }
    }

    private func tapped(ingredient: Ingredient) {
        if ingredient.missingInfo != nil {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.snappy) {
                if showingMissingInfoForIngredient == ingredient {
                    showingMissingInfoForIngredient = nil
                } else {
                    showingMissingInfoForIngredient = ingredient
                }
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
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

struct ScalePulsingModifier: ViewModifier {
    @State private var scale: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                scale = 0.95
            }
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
//            .modifier(SpeechEffect())
            Spacer().frame(height: 150)
        }
        .ignoresSafeArea([.container], edges: .top)
    }
}

struct IngredientPopoverOnTap: ViewModifier {
    var ingredient: Ingredient

    @State private var showPopover = false

    func body(content: Content) -> some View {
        content
            .overlay {
                Color.white.opacity(0.01)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let alert = UIAlertController(title: ingredient.text, message: ingredient.missingInfo ?? "No additional info", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: .default))
                        UIApplication.shared.showAlert(alert)
//                        showPopover = true
                    }
                    .padding(-5)
            }
//            .popover(isPresented: $showPopover, content: {
//                HStack {
//                    EmojiView(emoji: ingredient.emoji)
//                    Text(ingredient.text)
//                    if let missingInfo = ingredient.missingInfo {
//                        Text(missingInfo).foregroundStyle(.secondary)
//                    }
//                }
//                .padding()
//            })
    }
}

extension View {
    @ViewBuilder
    func textTap(_ block: @escaping () -> Void) -> some View {
        self
            .overlay {
                Color.white.opacity(0.01)
                    .contentShape(Rectangle())
//                    .border(.red)
                    .onTapGesture {
                        block()
                    }
                    .padding(.vertical, -8)
                    .padding(.horizontal, -4)
            }
    }
}

#Preview {
//    BigIcon(name: "waveform.and.magnifyingglass")
//        .modifier(ScalePulsingModifier())
    RecipeView(recipe: .stub, parsed: Recipe.stub.parsed!)
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
}
