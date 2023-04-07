require 'test_helper'

class S3Test < ActiveSupport::TestCase
  def test_s3
    require 'aws-sdk-s3'
    config = Rails.application.config_for(:storage)
    s3 = Aws::S3::Resource.new(
      access_key_id: config['access_key_id'],
      secret_access_key: config['secret_access_key'],
      session_token: config['session_token'],
      region: "us-east-1"
    )

    bucket_name = "fibertracker-bucket"
    bucket = s3.bucket(bucket_name)

    # Crea un archivo de prueba y súbalo al bucket
    object = bucket.object('test2.txt')
    object.put(body: 'Hola, mundo!')

    # Verifica que el archivo se pueda descargar desde la URL pública
    url = object.public_url
    response = Net::HTTP.get_response(URI.parse(url))
    assert_equal '200', response.code
  end
end
