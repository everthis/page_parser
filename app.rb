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
	@@url = 'http://zgcx.nhfpc.gov.cn/doctorsearch.aspx'
	@@captchaUrl = 'http://zgcx.nhfpc.gov.cn/pn.aspx'
	@@detailUrl = 'http://zgcx.nhfpc.gov.cn/Detail.aspx'

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

	def get_detail(data)

		puts data['url_path']

		# Fetch and parse HTML document
		url = "http://zgcx.nhfpc.gov.cn/Detail.aspx?" + data['url_path']  + "&v=" + data['v']
		uri = URI(url)

		req = Net::HTTP::Get.new(uri)
		req['Cookie'] = data['cookie']

		res = Net::HTTP.start(uri.hostname, uri.port) {|http|
		  http.request(req)
		} 
		@doc = Nokogiri::HTML(res.body)

		# Search for nodes by css
		@doc.at_css('table').to_s

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

		# uri = URI('http://zgcx.nhfpc.gov.cn/doctorsearch.aspx')
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

		uri = URI.parse("http://zgcx.nhfpc.gov.cn/doctorsearch.aspx")
		http = Net::HTTP.new(uri.host, uri.port)
		post_path = uri.path

		post_data = URI.encode_www_form(post_param)
		
		post_headers = {
			'Host' => 'zgcx.nhfpc.gov.cn',
			'Pragma' => 'no-cache',
			'Cache-Control' => 'no-cache',
			'Connection' => 'keep-alive',
		    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
		    'Origin' => 'http://zgcx.nhfpc.gov.cn',
		    'Upgrade-Insecure-Requests' => '1',
		    'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36',
		    'Content-Type' => 'application/x-www-form-urlencoded',
		    'DNT' => '1',
		    'Referer' => 'http://zgcx.nhfpc.gov.cn/doctorsearch.aspx',
			'Accept-Encoding' => 'gzip, deflate',
			'Accept-Language' => 'en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4,zh-TW;q=0.2',
		    'Cookie' => param_cookie
		}

		res, data = http.post(post_path, post_data, post_headers)
	end

	def detail

	end

	def get_captcha_img(cookie_param)
		time_stamp = Time.now.to_f
	    file_name = "#{time_stamp}-image.gif"
	    # actual_image_url = @@captchaUrl + params['t']
	    actual_image_url = @@captchaUrl
	    open("images/" + file_name, 'wb') do |file|
	      file << open(actual_image_url, "Cookie" => cookie_param).read
	    end
	    file_name
	end

	def check_alert(container)
		first_script = container.css('script').first

		if first_script.attribute('type')
			nil
		else
			first_script.text			
		end
	end

	def check_existence(container, target)

		if result = container.at_css(target)
		    result
		else
			nil
		end
	end


	def process_link(doc, data)
		doc.css('a').each do |item|
			item.name = "span"
			original_href = item['href']
			item.attribute('href').remove
			item['data-href'] = original_href
			item['data-cookie'] = data
		end
	end

end

get '/init' do
  headers \
	    "Access-Control-Allow-Origin"   => "*"

  obj = PageParser.new.get
  img_url = PageParser.new.get_captcha_img(obj[:cookie].split(',')[0]).to_s
  returnObj = obj.merge!("img_url": img_url)
  JSON.generate(returnObj)
end

get '/captcha' do
  headers \
  	    "Access-Control-Allow-Origin"   => "*"

  obj = {}
  img_url = PageParser.new.get_captcha_img(params['cookie']).to_s
  returnObj = obj.merge!("img_url": img_url)
  JSON.generate(returnObj)
end

get '/query' do
	headers \
	    "Access-Control-Allow-Origin"   => "*"

	cookie = params['cookie']
	response = PageParser.new.post(params)
	res_bo = response.body if response.is_a?(Net::HTTPSuccess)
	# parse returned data
	html_doc = Nokogiri::HTML(res_bo)

	# query result types: 
	# 0: alert
	# 1: nothing found
	# 2: found
	# 3: else
	alert = PageParser.new.check_alert(html_doc)
	nothing_found = PageParser.new.check_existence(html_doc, 'div[style="color: Red;"]')
	found = PageParser.new.check_existence(html_doc, 'table')
	query_obj = {}
	if alert
		query_obj['type'] = 0
		query_obj['content'] = alert
	elsif nothing_found
		query_obj['type'] = 1
		query_obj['content'] = nothing_found
	elsif found
		query_obj['type'] = 2
		query_obj['content'] = found
		PageParser.new.process_link(found, cookie)
	else
		query_obj['type'] = 3
		query_obj['content'] = "something unexpected happened."
	end
	query_obj['cookie'] = cookie
	JSON.generate(query_obj)
end

get '/detail' do
	headers \
	    "Access-Control-Allow-Origin"   => "*"
	data = {}
	data['cookie'] = params['cookie']
	data['url_path'] = params['url_path']
	data['v'] = params['v']
	PageParser.new.get_detail(data)

end




