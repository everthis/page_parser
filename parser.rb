# parser.rb
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'net/http'

class PageParser
	def get
		@url = 'http://61.49.18.120/doctorsearch.aspx'

		# Fetch and parse HTML document
		@doc = Nokogiri::HTML(open(@url))

		# Search for nodes by css
		@__VIEWSTATEGENERATOR = @doc.at_css('#__VIEWSTATEGENERATOR')["value"]

		@__EVENTVALIDATION = @doc.at_css('#__EVENTVALIDATION')["value"]

		@__VIEWSTATE = @doc.at_css('#__VIEWSTATE')["value"]

		puts @__EVENTVALIDATION


		uri = URI(@url)
		params = {"__VIEWSTATE" => @__VIEWSTATE,
				  "__VIEWSTATEGENERATOR" => @__VIEWSTATEGENERATOR,
				  "__EVENTVALIDATION" => @__EVENTVALIDATION,
				  "ctl00$ContentPlaceHolder1$ddlProvince" => 51,
				  "ctl00$ContentPlaceHolder1$txtName" => "李宁",
				  "ctl00$ContentPlaceHolder1$checkcode" => "puk76",
				  "ctl00$ContentPlaceHolder1$txtZyUnit" => "四川大学华西医院",
				  "ctl00$ContentPlaceHolder1$ButtonSearch" => "查询"
		}
		uri.query = URI.encode_www_form(params)

		res = Net::HTTP.get_response(uri)
		puts res.body if res.is_a?(Net::HTTPSuccess)

	end
end

# 2.times do
	PageParser.new.get
# end

