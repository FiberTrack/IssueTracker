require 'issues_controller.rb'

class UsersController < ApplicationController
  before_action :authenticate_api_key, only: %i[new_issue]

  def index
    @users = User.all
  end

  def new_issue
    issue_controller = IssuesController.new
    issue_controller.create
  end

def update_avatar(avatar)
  require 'aws-sdk-s3'

     # Obtener la URL de la imagen anterior y eliminar el objeto S3 asociado

  old_avatar_url = current_user.avatar_url
  if old_avatar_url.present?
    old_object_key = URI.parse(old_avatar_url).path[1..-1]
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("fibertracker-bucket")
    object = bucket.object(old_object_key)
    object.delete
  end

  # Obtener el archivo subido por el usuario
  file = avatar

  # Generar un nombre único para el archivo
  filename = SecureRandom.hex(10) + File.extname(file.original_filename)

  # Subir el archivo al bucket de S3
  s3 = Aws::S3::Resource.new
  bucket = s3.bucket("fibertracker-bucket")
  object = bucket.object(filename)
  object.upload_file(file.tempfile)

  # Actualizar la URL de la imagen en la base de datos del usuario
  current_user.update_attribute(:avatar_url, object.public_url)

end



def visualize
  @user = User.find(params[:usuari_id])
end

def update_profile

  biog = params[:bio]
  avatar = params[:avatar]

  if avatar.present?
    update_avatar(avatar)
  end

  if biog.present?
    current_user.update_attribute(:bio, biog)
  end

  redirect_to root_path
end

def authenticate_api_key
    user = User.find_by(api_key: request.headers['api_key'])
    if user.nil?
      render json: { error: 'API key inválida' }, status: :unauthorized
    end
end


end

