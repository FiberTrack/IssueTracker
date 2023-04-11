class UsersController < ApplicationController
  def index
    @users = User.all
    #@usuari = params[:usuari]
  end
end
