import SwiftUI

struct StarRating: View {
    let rating: Float
    var onRate: ((Float) -> Void)?
    var starSize: CGFloat = 14
    var maxStars: Int = 6

    @State private var animateScale: [Bool] = []

    var body: some View {
        HStack(spacing: starSize * 0.15) {
            ForEach(0..<maxStars, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundColor(starColor(for: index))
                    .scaleEffect(index < animateScale.count && animateScale[index] ? 1.3 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: index < animateScale.count ? animateScale[index] : false)
                    .onTapGesture {
                        guard let onRate else { return }
                        let tapped = Float(index + 1)
                        let newRating: Float = (rating == tapped) ? tapped - 0.5 : tapped
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if index < animateScale.count {
                            animateScale[index] = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                if index < animateScale.count {
                                    animateScale[index] = false
                                }
                            }
                        }
                        onRate(newRating)
                    }
            }
        }
        .onAppear {
            if animateScale.count != maxStars {
                animateScale = Array(repeating: false, count: maxStars)
            }
        }
        .onChange(of: maxStars) {
            animateScale = Array(repeating: false, count: maxStars)
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Float(index) + 1
        if rating >= threshold {
            return Image(systemName: "star.fill")
        } else if rating >= threshold - 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }

    private func starColor(for index: Int) -> Color {
        Float(index) + 0.5 <= rating ? SSColors.accentAmber : SSColors.chromeFaint
    }
}
