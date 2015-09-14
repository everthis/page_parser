require 'nokogiri'
require 'open-uri'

class PageParser
	def get
		# Fetch and parse HTML document
		@doc = Nokogiri::HTML(open('http://61.49.18.120/doctorsearch.aspx'))

		# Search for nodes by css
		@__VIEWSTATEGENERATOR = @doc.at_css('#__VIEWSTATEGENERATOR')["value"]

		@__EVENTVALIDATION = @doc.at_css('#__EVENTVALIDATION')["value"]

		@__VIEWSTATE = @doc.at_css('#__VIEWSTATE')["value"]

		puts @__EVENTVALIDATION

	end
end

10.times do
	PageParser.new.get
end