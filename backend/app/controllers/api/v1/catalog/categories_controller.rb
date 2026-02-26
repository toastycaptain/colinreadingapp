class Api::V1::Catalog::CategoriesController < Api::V1::BaseController
  before_action :require_parent!

  def index
    rows = Book.active
      .where.not(category: [nil, ""])
      .group(:category)
      .order(Arel.sql("COUNT(*) DESC"), :category)
      .count

    render json: {
      data: rows.map do |category, count|
        {
          category: category,
          book_count: count,
        }
      end,
    }
  end
end
