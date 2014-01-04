require 'minitest/autorun'
require 'net/http'

describe 'connecting to port 80' do
  it 'redirects to https' do
    response = Net::HTTP.get_response(URI('http://localhost/'))
    "301".must_equal response.code, response.body
    'https://localhost/'.must_equal(response['location'])
  end
end
