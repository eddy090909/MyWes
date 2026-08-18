//
//  EventDetailView.swift
//  MyWes
//

import SwiftUI

struct EventDetailView: View {
    let eventID: UUID
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    private var event: Event? {
        session.catalog.event(id: eventID)
    }

    private var host: Organization? {
        event.flatMap { session.catalog.organization(id: $0.orgID) }
    }

    private var isSaved: Bool {
        session.isSaved(eventID)
    }

    var body: some View {
        Group {
            if let event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header(event)

                        VStack(alignment: .leading, spacing: 0) {
                            Text(event.title)
                                .font(.system(size: 22, weight: .heavy))
                                .foregroundStyle(Theme.ink)
                                .padding(.bottom, 14)

                            VStack(alignment: .leading, spacing: 8) {
                                metaRow(systemImage: "calendar", text: "\(event.dateLabel) · \(event.time)")
                                metaRow(systemImage: "mappin.and.ellipse", text: event.location)

                                if let host {
                                    NavigationLink(value: AppRoute.organization(host.id)) {
                                        HStack(spacing: 4) {
                                            Text("Hosted by \(host.name)")
                                                .font(.system(size: 14, weight: .semibold))
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                        }
                                        .foregroundStyle(Theme.cardinal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 18)

                            saveButton
                                .padding(.bottom, session.engagementError == nil ? 20 : 8)

                            if session.engagementError != nil {
                                EngagementErrorCaption()
                                    .padding(.bottom, 20)
                            }

                            Text(event.description)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.ink.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                        .padding(.bottom, 40)
                    }
                }
                .background(Theme.background.ignoresSafeArea())
            } else {
                CatalogItemStatusView(
                    catalog: session.catalog,
                    title: "Event unavailable",
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func header(_ event: Event) -> some View {
        ZStack(alignment: .topLeading) {
            eventPlaceholderColor(for: event.category)
                .frame(height: 180)
                .overlay(alignment: .bottomLeading) {
                    Text(event.category)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.leading, 16)
                        .padding(.bottom, 14)
                }

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.85))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .padding(.top, 16)
            .padding(.leading, 16)
        }
    }

    private func metaRow(systemImage: String, text: String) -> some View {
        Label {
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink.opacity(0.8))
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private var saveButton: some View {
        Button {
            session.toggleSaveEvent(eventID)
        } label: {
            Text(isSaved ? "Saved" : "Save")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSaved ? Theme.ink : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSaved ? Theme.background : Theme.cardinal)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSaved ? Theme.border : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Saved" : "Save event")
    }
}

#Preview {
    NavigationStack {
        EventDetailView(eventID: MockData.IDs.evt1)
            .appDestinations()
    }
    .environment(AppSession.preview())
}
