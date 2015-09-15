require 'open-uri'
def captcha(index)
    file_name = "#{index}-image.gif"
    open("images/" + file_name, 'wb') do |file|
      file << open('http://61.49.18.120/pn.aspx').read
    end
end

1.upto(10) { |i| captcha i }

