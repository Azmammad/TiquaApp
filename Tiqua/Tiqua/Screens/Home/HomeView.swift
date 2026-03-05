//
//  HomeView.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 11.02.26.
//
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showSearch = false
    @State private var currentPostId: String?

    private var currentPost: Post? {
        guard let id = currentPostId else {
            return viewModel.filteredPosts.first
        }
        return viewModel.filteredPosts.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let searchHeight: CGFloat = 58
                let mapHeight: CGFloat = max(80, geo.size.height * 0.12)
                let spacing: CGFloat = 12
                let carouselHeight = geo.size.height - searchHeight - mapHeight - spacing * 2

                VStack(spacing: 0) {
                    searchButtonSection
                        .frame(height: searchHeight)

                    if viewModel.isLoading && viewModel.allPosts.isEmpty {
                        Spacer()
                        ProgressView().scaleEffect(1.4)
                        Spacer()
                    } else if viewModel.allPosts.isEmpty && !viewModel.isLoading {
                        emptyView
                    } else {
                        VStack(spacing: spacing) {
                            DiscoverCarouselSection(
                                posts: viewModel.filteredPosts,
                                currentPostId: $currentPostId
                            )
                            .frame(height: carouselHeight)

                            MapPlaceholderSection(
                                latitude: currentPost?.latitude,
                                longitude: currentPost?.longitude,
                                locationName: currentPost?.locationName
                            )
                            .frame(height: mapHeight)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Discover")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .task {
                await viewModel.loadPosts()
            }
            .fullScreenCover(isPresented: $showSearch) {
                SearchView(viewModel: viewModel)
            }
        }
    }

    private var searchButtonSection: some View {
        HStack(spacing: 10) {
            Button {
                showSearch = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text("Search users...")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            Menu {
                Button("All Countries") {
                    viewModel.selectedCountry = nil
                }
                ForEach(viewModel.availableCountries, id: \.self) { country in
                    Button(country) {
                        viewModel.selectedCountry = country
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(viewModel.selectedCountry != nil ? .accentColor : .primary)
                    .frame(width: 42, height: 42)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 52))
                .foregroundColor(.accentColor.opacity(0.4))

            Text("No posts yet")
                .font(.system(size: 20, weight: .bold))

            Text("Be the first to share a travel experience")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
