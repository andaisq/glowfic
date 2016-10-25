require "spec_helper"

RSpec.describe FavoritesController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end

    it "has no posts when no favorites" do
      login
      get :index
      expect(assigns(:posts)).to be_empty
    end

    context "it only shows favorites" do
      let (:user) { create(:user) }
      let (:user_post) { create(:post, user: user) }
      let (:post) { create(:post) }
      let (:board) { create(:board, creator: user) }
      let (:board_post) { create(:post, board: board) }
      let (:board_user_post) { create(:post, board: board, user: user) }

      it "shows user's post when user is favorited" do
        favorite = create(:favorite, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, board_user_post])
      end

      it "shows post when post is favorited" do
        favorite = create(:favorite, favorite: post)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post])
      end

      it "shows board posts when board is favorited" do
        favorite = create(:favorite, favorite: board)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([board_post, board_user_post])
      end

      it "shows both post and user post when post and user are favorited" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post, user_post, board_user_post])
      end

      it "shows both post and board post when post and board are favorited" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: board)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([post, board_post, board_user_post])
      end

      it "shows user and board posts when board and user are favorited" do
        favorite = create(:favorite, favorite: user)
        favorite = create(:favorite, user: favorite.user, favorite: board)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, board_post, board_user_post])
      end

      it "does not duplicate posts if both a user post and user are favorited" do
        favorite = create(:favorite, favorite: user_post)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([user_post, board_user_post])
      end

      it "does not duplicate posts if both a board post and board are favorited" do
        favorite = create(:favorite, favorite: board_post)
        favorite = create(:favorite, user: favorite.user, favorite: board)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([board_post, board_user_post])
      end

      it "handles all three types simultaneously" do
        favorite = create(:favorite, favorite: post)
        favorite = create(:favorite, user: favorite.user, favorite: board)
        favorite = create(:favorite, user: favorite.user, favorite: user)
        login_as(favorite.user)
        get :index
        expect(assigns(:posts)).to match_array([board_post, board_user_post, user_post, post])
      end
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "favorites a user" do
      user = create(:user)
      fav = create(:user)
      login_as(user)
      post :create, user_id: fav.id
      expect(Favorite.between(user, fav)).not_to be_nil
      expect(response).to redirect_to(favorites_url)
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a post" do
      user = create(:user)
      fav = create(:post)
      login_as(user)
      post :create, post_id: fav.id
      expect(Favorite.between(user, fav)).not_to be_nil
      expect(response).to redirect_to(favorites_url)
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end

    it "favorites a board" do
      user = create(:user)
      board = create(:board)
      login_as(user)
      post :create, board_id: board.id
      expect(Favorite.between(user, board)).not_to be_nil
      expect(response).to redirect_to(favorites_url)
      expect(flash[:success]).to eq("Your favorite has been saved.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid favorite" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(favorites_url)
      expect(flash[:error]).to eq("Favorite could not be found.")
    end

    it "requires your favorite" do
      login
      delete :destroy, id: create(:favorite, favorite: create(:user)).id
      expect(response).to redirect_to(favorites_url)
      expect(flash[:error]).to eq("That is not your favorite.")
    end

    it "destroys board favorite" do
      favorite = create(:favorite, favorite: create(:board))
      login_as(favorite.user)
      delete :destroy, id: favorite.id
      expect(response).to redirect_to(board_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end

    it "destroys post favorite" do
      favorite = create(:favorite, favorite: create(:post))
      login_as(favorite.user)
      delete :destroy, id: favorite.id
      expect(response).to redirect_to(post_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end

    it "destroys user favorite" do
      favorite = create(:favorite, favorite: create(:user))
      login_as(favorite.user)
      delete :destroy, id: favorite.id
      expect(response).to redirect_to(user_url(favorite.favorite))
      expect(flash[:success]).to eq("Favorite removed.")
    end
  end
end