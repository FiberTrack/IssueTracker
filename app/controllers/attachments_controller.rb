class AttachmentsController < ApplicationController
  before_action :set_issue, only: [:create]
  before_action :set_attachment, only: [:destroy]

  def create
    @attachment = @issue.attachments.new(name: params[:attachment][:file].original_filename)

    if @attachment.save
      puts "Attachment saved successfully."
      begin
        s3_object = upload_to_s3(params[:attachment][:file])


        flash[:notice] = "Archivo subido correctamente."
      rescue => e
        puts "Error uploading to S3: #{e.message}"
        flash[:alert] = "Hubo un error al subir el archivo."
      end
    else
      puts "Error saving attachment: #{@attachment.errors.full_messages.join(', ')}"
      flash[:alert] = "Hubo un error al guardar el archivo en el sistema."
    end

    redirect_to issue_path(@issue)
  end


  def destroy_attachment(attachment)

    old_url = attachment.url
    if old_url.present?
      old_object_key = URI.parse(old_url).path[1..-1]
      s3 = Aws::S3::Resource.new
      bucket = s3.bucket("fibertracker-bucket")
      object = bucket.object(old_object_key)
      object.delete
    end

    attachment.destroy
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