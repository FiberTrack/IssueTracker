class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def update_avatar
    require 'aws-sdk-s3'

     # Obtener la URL de la imagen anterior y eliminar el objeto S3 asociado
  old_avatar_url = current_user.avatar_url
  if old_avatar_url.present?
    old_object_key = URI.parse(old_avatar_url).path[1..-1]
    s3 = Aws::S3::Resource.new(region: "us-east-1")
    bucket = s3.bucket("fibertracker-bucket")
    object = bucket.object(old_object_key)
    object.delete
  end

  # Obtener el archivo subido por el usuario
   file = params[:avatar]

  # Generar un nombre único para el archivo
  filename = SecureRandom.hex(10) + File.extname(file.original_filename)

  # Subir el archivo al bucket de S3
  s3 = Aws::S3::Resource.new(region: "us-east-1")
  bucket = s3.bucket("fibertracker-bucket")
  object = bucket.object(filename)
  object.upload_file(file.tempfile)

  # Actualizar la URL de la imagen en la base de datos del usuario
  current_user.update_attribute(:avatar_url, object.public_url)

  redirect_to root_path
end

end
