require 'test_helper'
require 'mocha/minitest'  

class MoviesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @movie = movies(:inception)
    @user = users(:john)
  end

  test "should get index" do
    get movies_url, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 3, json_response['movies'].length
    assert_equal 1, json_response['current_page']
  end

  test "should filter movies by title" do
    get movies_url(title: "Inception"), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['movies'].length
    assert_equal "Inception", json_response['movies'][0]['title']
  end

  test "should filter movies by genre" do
    get movies_url(genre: "Action"), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['movies'].length
    assert_equal "The Matrix", json_response['movies'][0]['title']
  end

  test "should get recommendations for user" do
    RecommendationEngine.any_instance.stubs(:recommendations).returns([movies(:godfather)])

    get recommendations_movies_url(user_id: @user.id), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal "The Godfather", json_response[0]['title']
  end

  test "should handle missing user in recommendations" do
    get recommendations_movies_url(user_id: -1), as: :json
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "User not found", json_response['error']
  end

  test "should get user rented movies" do
    get user_rented_movies_movies_url(user_id: @user.id), as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal 1, json_response.length
    assert_equal "The Matrix", json_response[0]['title']
  end

  test "should handle missing user in user_rented_movies" do
    get user_rented_movies_movies_url(user_id: -1), as: :json
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "User not found", json_response['error']
  end

  test "should rent a movie" do
    movie_to_rent = movies(:godfather)

    assert_difference('Rental.count', 1) do
      assert_difference('movie_to_rent.reload.available_copies', -1) do
        get rent_movie_url(movie_to_rent.id, user_id: @user.id), as: :json
      end
    end

    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal movie_to_rent.id, json_response['id']

    assert_includes @user.reload.rented, movie_to_rent
  end

  test "should not rent a movie with no copies available" do
    movie_no_copies = movies(:inception)
    movie_no_copies.update(available_copies: 0)

    get rent_movie_url(movie_no_copies.id, user_id: @user.id), as: :json
    assert_response :unprocessable_entity

    json_response = JSON.parse(response.body)
    assert_equal "No copies available for rent", json_response['error']
  end

  test "should handle missing user in rent action" do
    get rent_movie_url(@movie.id, user_id: -1), as: :json
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "User not found", json_response['error']
  end

  test "should handle missing movie in rent action" do
    get rent_movie_url(-1, user_id: @user.id), as: :json
    assert_response :not_found

    json_response = JSON.parse(response.body)
    assert_equal "Movie not found", json_response['error']
  end
end
