# parser.rb
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'net/http'

class PageParser
	@@url = 'http://61.49.18.120/doctorsearch.aspx'
	@@captchaUrl = 'http://61.49.18.120/pn.aspx'
	@@detailUrl = 'http://61.49.18.120/Detail.aspx?id='
	def get

		# Fetch and parse HTML document
		@doc = Nokogiri::HTML(open(@@url))

		# Search for nodes by css
		@__VIEWSTATEGENERATOR = @doc.at_css('#__VIEWSTATEGENERATOR')["value"]

		@__EVENTVALIDATION = @doc.at_css('#__EVENTVALIDATION')["value"]

		@__VIEWSTATE = @doc.at_css('#__VIEWSTATE')["value"]

		# POST to get response
		uri = URI(@@url)
		puts uri
		params = {"__VIEWSTATE" => @__VIEWSTATE,
				  "__VIEWSTATEGENERATOR" => @__VIEWSTATEGENERATOR,
				  "__EVENTVALIDATION" => @__EVENTVALIDATION,
				  "ctl00$ContentPlaceHolder1$txtName" => "李宁",
				  "ctl00$ContentPlaceHolder1$checkcode" => "puk76",
				  "ctl00$ContentPlaceHolder1$txtZyUnit" => "四川大学华西医院",
				  "ctl00$ContentPlaceHolder1$ddlProvince" => 51,
				  "ctl00$ContentPlaceHolder1$ButtonSearch" => "查询"
		}
		uri.query = URI.encode_www_form(params)
		puts uri.query
		res = Net::HTTP.get_response(uri)
		res_bo = res.body if res.is_a?(Net::HTTPSuccess)
		puts res['Set-Cookie']
		cookie = res.response['set-cookie'].split('; ')[0]
		puts cookie
		# parse returned data
		html_doc = Nokogiri::HTML(res_bo)
		puts html_doc.at_css('#ctl00_ContentPlaceHolder1_lblTitle').text

	end

	def get_captcha_img(index)
	    file_name = "#{index}-image.gif"
	    open("images/" + file_name, 'wb') do |file|
	      file << open(@@captchaUrl).read
	    end
	end

	def check_existence
		if page.at_css('div.errorMsg')
		    puts 'Error message found on page'
		else
		    puts 'No error message found on page'
		end
	end

end

1.times do
	PageParser.new.get
end

