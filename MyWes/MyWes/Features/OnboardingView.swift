//
//  OnboardingView.swift
//  MyWes
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppSession.self) private var session

    private var primaryLabel: String {
        session.onboardStep < 2 ? "Continue" : "Get Started"
    }

    private var canAdvance: Bool {
        switch session.onboardStep {
        case 0: return session.selectedYear != nil
        case 1: return !session.selectedInterests.isEmpty
        default: return true
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProgressDots(count: 3, activeIndex: session.onboardStep)
                .padding(.bottom, 28)

            Group {
                switch session.onboardStep {
                case 0:
                    yearStep
                case 1:
                    interestsStep
                default:
                    orgsStep
                }
            }

            Spacer(minLength: 16)

            if let authError = session.authError {
                Text(authError)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.cardinal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 10) {
                if session.onboardStep > 0 {
                    Button {
                        session.onboardBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .frame(width: 50, height: 50)
                            .background(Theme.background)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.buttonRadius, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(session.isCompletingOnboarding)
                }

                PrimaryButton(
                    title: primaryLabel,
                    isEnabled: canAdvance,
                    isLoading: session.isCompletingOnboarding
                ) {
                    session.onboardContinue()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 70)
        .padding(.bottom, 24)
        .background(Theme.background.ignoresSafeArea())
    }

    private var yearStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What's your class year?")
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 6)

            Text("We'll tailor events and deadlines to you.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.secondaryText)
                .padding(.bottom, 24)

            FlowLayout(spacing: 10) {
                ForEach(MockData.classYears, id: \.self) { year in
                    SelectionChip(title: year, isSelected: session.selectedYear == year) {
                        session.selectedYear = year
                    }
                }
            }
        }
    }

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What are you into?")
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 6)

            Text("Pick a few — you can change these later.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.secondaryText)
                .padding(.bottom, 24)

            FlowLayout(spacing: 10) {
                ForEach(MockData.interests, id: \.self) { interest in
                    SelectionChip(
                        title: interest,
                        isSelected: session.selectedInterests.contains(interest)
                    ) {
                        session.toggleInterest(interest)
                    }
                }
            }
        }
    }

    private var orgsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Follow a few organizations")
                .font(Typography.headlineMedium)
                .foregroundStyle(Theme.ink)
                .padding(.bottom, 6)

            Text("Get their events and updates on your Home feed.")
                .font(Typography.bodySmall)
                .foregroundStyle(Theme.secondaryText)
                .padding(.bottom, session.engagementError == nil ? 20 : 12)

            if session.engagementError != nil {
                EngagementErrorCaption()
                    .padding(.bottom, 12)
            }

            VStack(spacing: 10) {
                CatalogStatusView(
                    catalog: session.catalog,
                    emptyMessage: "No organizations to follow yet.",
                    overlayPadding: 0
                ) {
                    ForEach(session.catalog.onboardingOrganizations) { org in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Theme.blueAccent.opacity(0.25))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(org.name.prefix(1)))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(org.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)

                                Text(org.category)
                                    .font(Typography.caption)
                                    .foregroundStyle(Theme.secondaryText)
                            }

                            Spacer(minLength: 8)

                            FollowButton(isFollowing: session.followedOrgIDs.contains(org.id)) {
                                session.toggleFollow(org.id)
                            }
                        }
                        .padding(12)
                        .cardChrome()
                    }
                }
            }
        }
    }
}

/// Simple wrapping layout for chips without external dependencies.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight), frames)
    }
}

#if DEBUG
#Preview {
    OnboardingView()
        .environment(AppSession.preview())
}
#endif
