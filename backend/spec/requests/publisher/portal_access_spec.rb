require "rails_helper"

RSpec.describe "Publisher portal access", type: :request do
  let(:publisher_one) { create(:publisher, name: "Publisher One") }
  let(:publisher_two) { create(:publisher, name: "Publisher Two") }

  let(:owner_user) { create(:publisher_user, publisher: publisher_one, role: :owner) }

  describe "GET /publisher/books" do
    it "scopes books to current publisher" do
      own_book = create(:book, publisher: publisher_one, title: "Own Book")
      create(:book, publisher: publisher_two, title: "Other Book")

      sign_in owner_user
      get "/publisher/books"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(own_book.title)
      expect(response.body).not_to include("Other Book")
    end
  end

  describe "GET /publisher/statements/:id" do
    it "blocks access to another publisher statement" do
      payout_period = create(:payout_period)
      foreign_statement = create(:publisher_statement, payout_period: payout_period, publisher: publisher_two)

      sign_in owner_user
      get "/publisher/statements/#{foreign_statement.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /publisher/exports" do
    it "prevents read-only users from creating exports" do
      read_only_user = create(:publisher_user, publisher: publisher_one, role: :read_only)

      sign_in read_only_user

      expect do
        post "/publisher/exports", params: { export_type: "analytics_daily" }
      end.not_to change(DataExport, :count)

      expect(response).to have_http_status(:found)
      expect(response).to redirect_to("/publisher")
    end
  end
end
