//
//  Components.swift
//  MyWes
//

import SwiftUI

// MARK: - Card chrome

struct CardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.background)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardChrome() -> some View {
        modifier(CardChrome())
    }
}

// MARK: - Logo

struct AppLogoMark: View {
    var size: CGFloat = 76
    var cornerRadius: CGFloat = Theme.logoRadiusLarge

    var body: some View {
        Text("W")
            .font(.system(size: size * 0.45, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.cardinal)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isEnabled ? Theme.cardinal : Theme.border)
                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

struct FollowButton: View {
    var isFollowing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(isFollowing ? Theme.ink : .white)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(isFollowing ? Theme.background : Theme.cardinal)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isFollowing ? Theme.border : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .emailAddress
    var textContentType: UITextContentType? = .emailAddress
    var usesMonospacedDigits: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)? = nil
    var focus: FocusState<Bool>.Binding? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(Typography.label)
                .foregroundStyle(Theme.secondaryText)
                .tracking(0.4)

            TextField(placeholder, text: $text)
                .font(usesMonospacedDigits
                      ? .system(size: 22, weight: .semibold, design: .rounded).monospacedDigit()
                      : Typography.body)
                .kerning(usesMonospacedDigits ? 6 : 0)
                .foregroundStyle(Theme.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
                .onSubmit { onSubmit?() }
                .applyFocus(focus)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.fieldRadius, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
    }
}

private extension View {
    @ViewBuilder
    func applyFocus(_ binding: FocusState<Bool>.Binding?) -> some View {
        if let binding {
            focused(binding)
        } else {
            self
        }
    }
}

// MARK: - Chips & progress

struct SelectionChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? Theme.cardinal : Theme.background)
                .clipShape(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                        .stroke(isSelected ? Theme.cardinal : Theme.border, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ProgressDots: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == activeIndex ? Theme.cardinal : Theme.border)
                    .frame(width: index == activeIndex ? 22 : 16, height: 5)
            }
        }
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var trailingLabel: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.ink)
            Spacer()
            if let trailingLabel {
                Text(trailingLabel)
                    .font(Typography.label)
                    .foregroundStyle(Theme.cardinal.opacity(0.55))
            }
        }
    }
}

// MARK: - Status

struct StatusBadge: View {
    var isOpen: Bool

    var body: some View {
        Text(isOpen ? "Open" : "Closed")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(isOpen ? Theme.success : Theme.cardinal)
    }
}

// MARK: - Home cards

struct EventCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(bannerColor)
                    .frame(height: 74)

                Text(event.category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(event.dateLabel) · \(event.location)")
                    .font(Typography.captionEmphasized)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(width: 200, alignment: .leading)
        .cardChrome()
    }

    private var bannerColor: Color {
        switch event.category {
        case "Academic", "Community":
            return Theme.blueAccent
        default:
            return Theme.cardinal
        }
    }
}

struct DiningStatusCard: View {
    let location: DiningLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(location.name)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)

            StatusBadge(isOpen: location.isOpen)

            Text(location.hoursText)
                .font(Typography.captionEmphasized)
                .foregroundStyle(Theme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .cardChrome()
    }
}

struct QuestionRow: View {
    let question: Question

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(question.title)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)

            Text("▲ \(question.voteCount) · \(question.answerCount) answers · \(question.topic)")
                .font(Typography.captionEmphasized)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .cardChrome()
    }
}

struct OrgUpdateRow: View {
    let update: OrgUpdate

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.blueAccent.opacity(0.25))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(update.orgName.prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(update.orgName)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                Text(update.updateText)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .cardChrome()
    }
}

#Preview("Components") {
    ScrollView {
        VStack(spacing: 16) {
            AppLogoMark()
            PrimaryButton(title: "Continue") {}
            SelectionChip(title: "2027", isSelected: true) {}
            ProgressDots(count: 3, activeIndex: 1)
            EventCard(event: MockData.events[0])
            DiningStatusCard(location: MockData.diningLocations[0])
            QuestionRow(question: MockData.questions[0])
        }
        .padding()
    }
}
