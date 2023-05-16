require 'aws-sdk-s3'
require 'users_controller.rb'
class AttachmentsController < ApplicationController
  before_action :set_issue, only: [:create]
  before_action :set_attachment, only: [:destroy]
  before_action -> { authenticate_api_key(request.headers['Authorization'].present?) }, only: [:create, :destroy_attachment]
 rescue_from ActiveRecord::RecordNotFound, with: :issue_not_found


def issue_not_found
    render json: { error: 'Issue not found' }, status: :not_found
end


def authenticate_api_key(verify_key = true)
  if verify_key
    @authenticated_user = UsersController.new.authenticate_api_key(request)
    if @authenticated_user == :unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end


  def index
    @issue = Issue.find(params[:issue_id])
    @attachments = @issue.attachments.select(:id, :name, :url)
    render json: @attachments
  end



  def create
    if request[:file].nil?
      puts "Peticio UI"
      @attachment = @issue.attachments.new(name: params[:attachment][:file].original_filename)
    else
      puts "Peticio API"
      @attachment = @issue.attachments.new(name: request.params[:file].original_filename)
    end

    if @attachment.save
      puts "Attachment saved successfully."
      begin

      if request[:file].nil?
         puts "Peticio UI segona part"
       s3_object = upload_to_s3(params[:attachment][:file])
      else
        puts "Peticio API segona part"
       s3_object = upload_to_s3(request.params[:file])
      end

        flash[:notice] = "Archivo subido correctamente."

      rescue => e
        puts "Error uploading to S3: #{e.message}"
        flash[:alert] = "Hubo un error al subir el archivo."
      end
    else
      puts "Error saving attachment: #{@attachment.errors.full_messages.join(', ')}"
      flash[:alert] = "Hubo un error al guardar el archivo en el sistema."
    end

    #redirect_to issue_path(@issue)
     respond_to do |format|
      if request[:file].nil?
      format.html { redirect_to issue_path(@issue)}
      else
      format.json {  render json: { message: "Attachment uploaded successfully" }, status: :ok  }
      end
    end
  end




  def destroy_attachment(id = nil)
  attachment_id = id || params[:id]
    attachment = Attachment.find(attachment_id)
    old_url = attachment.url
    if old_url.present?
      old_object_key = URI.parse(old_url).path[1..-1]
      s3 = Aws::S3::Resource.new
      bucket = s3.bucket("fibertracker-bucket")
      object = bucket.object(old_object_key)
      object.delete
    end
    attachment.destroy

    if id.nil?
      respond_to do |format|
        format.json {  render json: { message: "Attachment deleted successfully" }, status: :ok  }
      end
    end
end


  private


  def set_issue
    @issue = Issue.find(params[:issue_id])
  end

  def set_attachment
    @attachment = Attachment.find(params[:id])
    @issue = @attachment.issue
  end



  def upload_to_s3(file)
    require 'aws-sdk-s3'

    config = Rails.configuration.x

    s3 = Aws::S3::Resource.new(
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      session_token: config.session_token, # si aplica
      region: "us-east-1"
    )

    bucket_name = "fibertracker-bucket"
    bucket = s3.bucket(bucket_name)

    # Upload the file to the S3 bucket
    object = bucket.object(file.original_filename)
    object.upload_file(file.path) # You can remove 'acl: public-read' if you don't want the file to be publicly accessible
    @attachment.update(url: object.public_url)

  end

  def delete_from_s3(file_key)
    require 'aws-sdk-s3'

    config = Rails.configuration.x

    s3 = Aws::S3::Resource.new(
      access_key_id: config.access_key_id,
      secret_access_key: config.secret_access_key,
      session_token: config.session_token, # si aplica
      region: "us-east-1"
    )

    bucket_name = "fibertracker-bucket"
    bucket = s3.bucket(bucket_name)

    # Delete the file from the S3 bucket
    object = bucket.object(file_key)
    object.delete
  end

end