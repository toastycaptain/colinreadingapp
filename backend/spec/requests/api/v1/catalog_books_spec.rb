require "rails_helper"

RSpec.describe "Catalog API", type: :request do
  let(:parent) { create(:user, role: :parent) }
  let(:publisher) { create(:publisher) }

  describe "GET /api/v1/catalog/books" do
    it "filters by category and paginates results" do
      create(:book, publisher: publisher, category: "Science", title: "Planet A")
      create(:book, publisher: publisher, category: "Science", title: "Planet B")
      create(:book, publisher: publisher, category: "Fairy Tales", title: "Story C")

      get "/api/v1/catalog/books", params: {
        category: "Science",
        page: 1,
        per_page: 1,
      }, headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["category"]).to eq("Science")
      expect(json.dig("pagination", "total_count")).to eq(2)
    end

    it "filters by age" do
      create(:book, publisher: publisher, category: "Science", age_min: 2, age_max: 4)
      create(:book, publisher: publisher, category: "Science", age_min: 7, age_max: 9)

      get "/api/v1/catalog/books", params: { age: 3 }, headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["age_min"]).to eq(2)
    end
  end

  describe "GET /api/v1/catalog/books/:id" do
    it "returns book details" do
      book = create(:book, publisher: publisher, category: "Adventure")
      create(:video_asset, :ready, book: book, duration_seconds: 321)

      get "/api/v1/catalog/books/#{book.id}", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(book.id)
      expect(json["category"]).to eq("Adventure")
      expect(json.dig("video_asset", "duration_seconds")).to eq(321)
    end
  end

  describe "GET /api/v1/catalog/categories" do
    it "returns categories with counts" do
      create(:book, publisher: publisher, category: "Science")
      create(:book, publisher: publisher, category: "Science")
      create(:book, publisher: publisher, category: "Adventure")

      get "/api/v1/catalog/categories", headers: auth_headers_for(parent)

      expect(response).to have_http_status(:ok)
      categories = json.fetch("data")
      science = categories.find { |row| row["category"] == "Science" }
      adventure = categories.find { |row| row["category"] == "Adventure" }

      expect(science["book_count"]).to eq(2)
      expect(adventure["book_count"]).to eq(1)
    end
  end
end
