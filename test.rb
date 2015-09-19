require 'uri'
require 'net/http'
url = "http://61.49.18.120/doctorsearch.aspx"
r = Net::HTTP.get_response(URI.parse(url).host, URI.parse(url).path)
puts r["Set-Cookie"]
puts r.body