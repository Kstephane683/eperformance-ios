import SwiftUI

struct BrandMark: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("e").foregroundStyle(Brand.ink)
            Text("P").foregroundStyle(Brand.gold)
            Text("erformance").foregroundStyle(Brand.ink)
        }
        .font(.system(size: 24, weight: .semibold, design: .serif))
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).background(Brand.paper).overlay(RoundedRectangle(cornerRadius: 18).stroke(Brand.line, lineWidth: 1)).clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct FieldLabel: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(Brand.muted).frame(maxWidth: .infinity, alignment: .leading) }
}

struct PrimaryButton: View {
    let title: String
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 15)
        }
        .buttonStyle(.plain).foregroundStyle(Brand.ink).background(Brand.gold).clipShape(Capsule()).disabled(disabled).opacity(disabled ? 0.55 : 1)
    }
}

struct SectionTitle: View {
    let eyebrow: String; let title: String
    var body: some View { VStack(alignment: .leading, spacing: 7) { Text(eyebrow.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(1.6).foregroundStyle(Brand.gold); Text(title).font(.system(size: 34, weight: .semibold, design: .serif)).foregroundStyle(Brand.ink) } }
}
