class UsersController < ApplicationController
	def create
		user = User.create params.require(:new_user).permit(:email, :password, :password_confirmation)

		user.secret_key = generate_key
		if user.save
			flash[:success] = "Welcome to the site, #{user.email}! This is your secret key: #{user.secret_key}"
      
      session[:email] = nil
      session[:user] = user

			redirect_to :view_lobbies
		else
			flash[:fail] = "Your #{user.errors.keys.first} #{user.errors.values.first[0]}."

			session[:email] = user.email

      redirect_to root_url
		end
	end

	def edit
	end

	def regenerate_key
		unless session[:user].nil?
    	session[:user].secret_key = generate_key
    	session[:user].save

    	flash[:success] = "This is your new secret key: #{session[:user].secret_key}!"
    end

    redirect_to root_url

	end

  def login
  	redirect_to root_url unless session[:user].nil?
  end

  def authenticate
  	user = User.find_by_email(params[:login][:email])

  	if user && user.authenticate(params[:login][:password])
  		flash[:success] = "Welcome back, #{user.email}!"

  		session[:user] = user

  		redirect_to :view_lobbies
  	else
  		flash[:fail] = "Your username/password combination are incorrect."

  		redirect_to root_url
  	end
  end

  def logout
  	session[:user] = nil

  	redirect_to root_url
  end

  def show
    redirect_to root_url unless !session[:user].nil?
    @user = User.find_by(email: session[:user][:email])
    @races = RaceSummary.where("uid = ?", @user.id).order("created_at").paginate(page: params[:page], per_page: 5)
  end

  private 

  def generate_key
  	o = [('a'..'z'), ('A'..'Z')].map { |i| i.to_a }.flatten
    (0...50).map { o[rand(o.length)] }.join
	end
end