class MoviesController < ApplicationController
  def index 
    page = params[:page] || 1
    per_page = params[:per_page] || 10

    title = params[:title]
    genre = params[:genre]

    query = Movie.all

    if title.present?
      query = query.where("title LIKE ?", "%#{title}%")
    end

    if genre.present?
      query = query.where(genre: genre)
    end

    @movies = query.page(page).per(per_page)

    render json: {
      movies: @movies,
      total_pages: @movies.total_pages,
      current_page: @movies.current_page,
      total_count: @movies.total_count
    }
  end

  def recommendations
    user = User.find_by(id: params[:user_id])
    
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    favorite_movies = user.favorites
    @recommendations = RecommendationEngine.new(favorite_movies).recommendations
    render json: @recommendations
  end

  def user_rented_movies
    user = User.find_by(id: params[:user_id])
    
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    @rented = user.rented
    render json: @rented
  end

  def rent
    user = User.find_by(id: params[:user_id])
    if user.nil?
      render json: { error: "User not found" }, status: :not_found
      return
    end

    movie = Movie.find_by(id: params[:id])
    if movie.nil?
      render json: { error: "Movie not found" }, status: :not_found
      return
    end

    if movie.available_copies <= 0
      render json: { error: "No copies available for rent" }, status: :unprocessable_entity
      return
    end

    movie.available_copies -= 1
    movie.save
    user.rented << movie
    render json: movie
  end
end