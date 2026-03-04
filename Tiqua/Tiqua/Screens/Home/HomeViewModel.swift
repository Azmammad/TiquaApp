//
//  HomeViewModel.swift
//  Tiqua
//
//  Created by Əzi Cəbrayılov on 25.02.26.
//
import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var allPosts: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCountry: String? = nil
    @Published var searchText: String = ""
    @Published var searchResults: [User] = []
    @Published var isSearching: Bool = false

    private let db = Firestore.firestore()
    private let userSearchService: UserSearchServiceProtocol
    private var searchCancellable: AnyCancellable?

    init(userSearchService: UserSearchServiceProtocol) {
        self.userSearchService = userSearchService
        observeSearch()
    }

    convenience init() {
        self.init(userSearchService: FirebaseUserSearchService())
    }

    var filteredPosts: [Post] {
        guard let country = selectedCountry, !country.isEmpty else {
            return allPosts
        }
        return allPosts.filter {
            ($0.countryDisplayName ?? "").localizedCaseInsensitiveContains(country)
        }
    }

    var availableCountries: [String] {
        let countries = allPosts.compactMap { $0.countryDisplayName }
        return Array(Set(countries)).sorted()
    }

    var isShowingSearchResults: Bool {
        !searchText.isEmpty
    }

    func loadPosts() async {
        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await db
                .collection("posts")
                .order(by: "createdAt", descending: true)
                .limit(to: 60)
                .getDocuments()

            let fetched = snapshot.documents.compactMap { decode(document: $0) }
            allPosts = fetched.shuffled()
        } catch {
            errorMessage = "Failed to load posts."
        }

        isLoading = false
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
    }

    private func observeSearch() {
        searchCancellable = $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(350), scheduler: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                Task { await self.performSearch(query: value) }
            }
    }

    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        do {
            searchResults = try await userSearchService.searchUsers(query: trimmed)
        } catch {
            searchResults = []
        }
        isSearching = false
    }

    private func decode(document: QueryDocumentSnapshot) -> Post? {
        let data = document.data()

        guard
            let id = data["id"] as? String,
            let ownerId = data["ownerId"] as? String,
            let username = data["username"] as? String,
            let imageURL = data["imageURL"] as? String,
            let timestamp = data["createdAt"] as? Timestamp
        else { return nil }

        return Post(
            id: id,
            ownerId: ownerId,
            username: username,
            imageURL: imageURL,
            caption: data["caption"] as? String,
            locationName: data["locationName"] as? String,
            countryName: data["countryName"] as? String,
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double,
            createdAt: timestamp.dateValue()
        )
    }
}
