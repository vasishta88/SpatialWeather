import SwiftUI

struct WeatherDetailCard: View {
    let item: DetailItem
    let theme: WeatherTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: item.icon)
                .font(.headline)
                .foregroundStyle(theme.accent)

            Text(item.value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.leading)

            Text(item.title)
                .font(.caption)
                .foregroundStyle(theme.tertiaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.cardStroke, lineWidth: 1)
        )
    }
}
