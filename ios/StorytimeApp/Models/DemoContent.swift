import Foundation

enum DemoContent {
    static let demoChild = ChildProfileDTO(
        id: -1,
        name: "Demo Kid",
        avatarURL: nil,
        createdAt: nil,
        updatedAt: nil
    )

    static let howToBook = BookDTO(
        id: -101,
        title: "How To Use Storytime",
        author: "Storytime Team",
        description: "A guided walkthrough of the read-aloud experience for parents and kids.",
        category: "How To",
        ageMin: 3,
        ageMax: 12,
        language: "en",
        coverImageURL: nil,
        addedAt: "2026-02-27T00:00:00Z",
        status: "ready",
        publisher: BookDTO.PublisherSummaryDTO(id: -1, name: "Storytime"),
        videoAsset: BookDTO.VideoAssetSummaryDTO(processingStatus: "ready", durationSeconds: 180)
    )

    static let howToCategory = CatalogCategoryDTO(category: "How To", bookCount: 1)

    static let howToPlaybackURL = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"
    )!
}
