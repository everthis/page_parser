# app.rb
# encoding: utf-8

require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

set :environment, :development

set :foo, 'bar'

class LocationList < Hash
  def initialize(node_list)
    node_list.each {|key, value| self["#{key}"]="#{value}"}
  end
end

class PageParser
	@@url = 'http://61.49.18.120/doctorsearch.aspx'
	@@captchaUrl = 'http://61.49.18.120/pn.aspx'
	@@detailUrl = 'http://61.49.18.120/Detail.aspx?id='

	def pre_get

	end

	def get

		# Fetch and parse HTML document
		@doc = Nokogiri::HTML(open(@@url))

		# Search for nodes by css
		__VIEWSTATEGENERATOR = @doc.at_css('#__VIEWSTATEGENERATOR')["value"]

		__EVENTVALIDATION = @doc.at_css('#__EVENTVALIDATION')["value"]

		__VIEWSTATE = @doc.at_css('#__VIEWSTATE')["value"]

		returnObj = {
			"__VIEWSTATE": __VIEWSTATE,
		    "__VIEWSTATEGENERATOR": __VIEWSTATEGENERATOR,
		    "__EVENTVALIDATION": __EVENTVALIDATION,
		    "ctl00$ContentPlaceHolder1$ButtonSearch": "查询"
		}

	end

	def post
	end

	def get_captcha_img
		time_stamp = Time.now.to_f
	    file_name = "#{time_stamp}-image.gif"
	    open("images/" + file_name, 'wb') do |file|
	      file << open(@@captchaUrl).read
	    end
	    file_name
	end

	def check_existence
		if page.at_css('div.errorMsg')
		    puts 'Error message found on page'
		else
		    puts 'No error message found on page'
		end
	end

end

get '/foo' do
  headers 'Access-Control-Allow-Origin' => '*'
  # "foo is set to " + settings.foo
  obj = PageParser.new.get
  img_url = PageParser.new.get_captcha_img.to_s
  returnObj = obj.merge!("img_url": img_url)
  JSON.generate(returnObj)
end

get '/query' do
	headers 'Access-Control-Allow-Origin' => '*'
	__VIEWSTATE = params['__VIEWSTATE'].gsub(' ','+')
	__VIEWSTATEGENERATOR = params['__VIEWSTATEGENERATOR'].gsub(' ','+')
	__EVENTVALIDATION = params['__EVENTVALIDATION'].gsub(' ','+')

	name = params['name']
	org = params['org']
	cap = params['cap']
	pro = params['pro']

	uri = URI('http://61.49.18.120/doctorsearch.aspx')
	# puts uri
	params = {"__VIEWSTATE" => __VIEWSTATE,
			  "__VIEWSTATEGENERATOR" => __VIEWSTATEGENERATOR,
			  "__EVENTVALIDATION" => __EVENTVALIDATION,
			  "ctl00$ContentPlaceHolder1$txtName" => name,
			  "ctl00$ContentPlaceHolder1$checkcode" => cap,
			  "ctl00$ContentPlaceHolder1$txtZyUnit" => org,
			  "ctl00$ContentPlaceHolder1$ddlProvince" => pro,
			  "ctl00$ContentPlaceHolder1$ButtonSearch" => "查询"
	}
	uri.query = URI.encode_www_form(params)
	# puts uri

	res = Net::HTTP.get_response(uri)
	res_bo = res.body if res.is_a?(Net::HTTPSuccess)

	res_bo

end




