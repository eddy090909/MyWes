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
    var isLoading: Bool = false
    let action: () -> Void

    private var canTap: Bool { isEnabled && !isLoading }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(Typography.button)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canTap ? Theme.cardinal : Theme.border)
            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
        }
        .disabled(!canTap)
        .buttonStyle(.plain)
    }
}

struct FollowButton: View {
    var isFollowing: Bool
    var isWide: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isFollowing ? "Following" : "Follow")
                .font(.system(size: isWide ? 15 : 12.5, weight: .bold))
                .foregroundStyle(isFollowing ? Theme.ink : .white)
                .padding(.horizontal, isWide ? 0 : 14)
                .frame(maxWidth: isWide ? .infinity : nil)
                .frame(height: isWide ? 44 : 30)
                .background(isFollowing ? Theme.background : Theme.cardinal)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isFollowing ? Theme.border : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFollowing ? "Following" : "Follow")
        .accessibilityAddTraits(.isButton)
    }
}

struct EngagementErrorCaption: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        if let message = session.engagementError {
            Text(message)
                .font(Typography.caption)
                .foregroundStyle(Theme.cardinal)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isStaticText)
        }
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

struct SectionHeader<Trailing: View>: View {
    let title: String
    var trailing: Trailing

    init(title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Typography.sectionTitle)
                .foregroundStyle(Theme.ink)
            Spacer()
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

/// Soft, per-category accent for events: a muted tint plus an SF Symbol.
struct EventCategoryStyle {
    let tint: Color
    let symbol: String

    init(_ category: String) {
        switch category {
        case "Arts": tint = Color(red: 0.55, green: 0.33, blue: 0.62); symbol = "paintpalette.fill"
        case "Athletics": tint = Color(red: 0.16, green: 0.50, blue: 0.42); symbol = "figure.run"
        case "Academic": tint = Theme.blueAccent; symbol = "book.fill"
        case "Social": tint = Color(red: 0.80, green: 0.45, blue: 0.16); symbol = "person.3.fill"
        case "Dining": tint = Theme.cardinal; symbol = "fork.knife"
        default: tint = Color(red: 0.36, green: 0.42, blue: 0.48); symbol = "person.2.fill"
        }
    }
}

/// Category pill: tinted icon and label on a light wash of the same tint.
struct EventCategoryTag: View {
    let category: String

    var body: some View {
        let style = EventCategoryStyle(category)
        Label(category, systemImage: style.symbol)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(style.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(style.tint.opacity(0.10))
            .clipShape(Capsule())
    }
}

/// Month/day tile used on event cards and rows.
struct EventDateTile: View {
    let event: Event
    var size: CGFloat = 44

    var body: some View {
        VStack(spacing: 0) {
            Text(event.monthLabel)
                .font(.system(size: size * 0.24, weight: .bold))
                .foregroundStyle(Theme.cardinal)
            Text(event.dayNumber)
                .font(.system(size: size * 0.42, weight: .heavy))
                .foregroundStyle(Theme.ink)
        }
        .frame(width: size, height: size)
        .background(Theme.savedBannerBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityHidden(true)
    }
}

func organizationPlaceholderColor(for category: String) -> Color {
    switch category {
    case "Media", "Community", "Campus Services":
        return Theme.blueAccent
    default:
        return Theme.cardinal
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                EventDateTile(event: event)
                Spacer(minLength: 8)
                EventCategoryTag(category: event.category)
            }

            Text(event.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.time)
                    .font(Typography.captionEmphasized)
                    .foregroundStyle(Theme.ink.opacity(0.8))
                Text(event.location)
                    .font(Typography.captionEmphasized)
                    .foregroundStyle(Theme.secondaryText)
            }
            .lineLimit(1)
        }
        .padding(12)
        .frame(width: 220, alignment: .leading)
        .cardChrome()
        .accessibilityElement(children: .combine)
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
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
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
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

#if DEBUG
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
#endif
