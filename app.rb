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
		
		uri = URI(@@url)

		req = Net::HTTP::Get.new(uri)
		req['User-Agent'] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36"

		res = Net::HTTP.start(uri.hostname, uri.port) {|http|
		  http.request(req)
		} 
		
		# cookie = res.response['set-cookie'].split('; ')[0]
		cookie = res.response['set-cookie'].split(',').join(';')

		@doc = Nokogiri::HTML(res.body)

		# Search for nodes by css
		__VIEWSTATEGENERATOR = @doc.at_css('#__VIEWSTATEGENERATOR')["value"]

		__EVENTVALIDATION = @doc.at_css('#__EVENTVALIDATION')["value"]

		__VIEWSTATE = @doc.at_css('#__VIEWSTATE')["value"]

		returnObj = {
			"__VIEWSTATE": __VIEWSTATE,
		    "__VIEWSTATEGENERATOR": __VIEWSTATEGENERATOR,
		    "__EVENTVALIDATION": __EVENTVALIDATION,
		    "cookie": cookie
		}

	end

	def post(params)
		__VIEWSTATE = params['__VIEWSTATE'].gsub(' ','+')
		__VIEWSTATEGENERATOR = params['__VIEWSTATEGENERATOR'].gsub(' ','+')
		__EVENTVALIDATION = params['__EVENTVALIDATION'].gsub(' ','+')

		name = params['name']
		org = params['org']
		cap = params['cap']
		pro = params['pro']
		param_cookie = params['cookie']

		# uri = URI('http://61.49.18.120/doctorsearch.aspx')
		# puts uri
		post_param = {"__VIEWSTATE" => __VIEWSTATE,
				  "__VIEWSTATEGENERATOR" => __VIEWSTATEGENERATOR,
				  "__EVENTVALIDATION" => __EVENTVALIDATION,
				  "ctl00$ContentPlaceHolder1$ddlProvince" => pro,
				  "ctl00$ContentPlaceHolder1$txtName" => name,
				  "ctl00$ContentPlaceHolder1$txtZyUnit" => org,
				  "ctl00$ContentPlaceHolder1$checkcode" => cap,
				  "ctl00$ContentPlaceHolder1$ButtonSearch" => "查询"
		}

		uri = URI.parse("http://61.49.18.120/doctorsearch.aspx")
		http = Net::HTTP.new(uri.host, uri.port)
		post_path = uri.path

		puts post_path

		post_data = URI.encode_www_form(post_param)
		
		puts param_cookie.inspect

		post_headers = {
			'Host' => '61.49.18.120',
			'Pragma' => 'no-cache',
			'Cache-Control' => 'no-cache',
			'Connection' => 'keep-alive',
		    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
		    'Origin' => 'http://61.49.18.120',
		    'Upgrade-Insecure-Requests' => '1',
		    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36',
		    'Content-Type' => 'application/x-www-form-urlencoded',
		    'DNT' => '1',
		    'Referer' => 'http://61.49.18.120/doctorsearch.aspx',
			'Accept-Encoding' => 'gzip, deflate',
			'Accept-Language' => 'en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4,zh-TW;q=0.2',
		    'Cookie' => param_cookie
		}

		res, data = http.post(post_path, post_data, post_headers)


	end

	def get_captcha_img(cookie_param)
		puts cookie_param
		time_stamp = Time.now.to_f
	    file_name = "#{time_stamp}-image.gif"
	    # actual_image_url = @@captchaUrl + params['t']
	    actual_image_url = @@captchaUrl
	    open("images/" + file_name, 'wb') do |file|
	      file << open(actual_image_url, "Cookie" => cookie_param).read
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

get '/init' do
  headers \
	    "Access-Control-Allow-Origin"   => "*"

  obj = PageParser.new.get
  puts obj
  img_url = PageParser.new.get_captcha_img(obj[:cookie].split(',')[0]).to_s
  returnObj = obj.merge!("img_url": img_url)
  JSON.generate(returnObj)
end

get '/captcha' do
  headers \
  	    "Access-Control-Allow-Origin"   => "*"

  obj = {}
  puts params
  img_url = PageParser.new.get_captcha_img(params['cookie']).to_s
  returnObj = obj.merge!("img_url": img_url)
  JSON.generate(returnObj)
end

get '/query' do
	headers \
	    "Access-Control-Allow-Origin"   => "*"

	response = PageParser.new.post(params)

	res_bo = response.body if response.is_a?(Net::HTTPSuccess)

	# parse returned data
	html_doc = Nokogiri::HTML(res_bo)

	puts res_bo

	first_script = html_doc.css('script').first.text
	puts first_script
	first_script

end




