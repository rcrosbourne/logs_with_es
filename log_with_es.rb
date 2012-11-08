require "yajl"
require "tire"
require 'rubygems'
require 'socket' #get the hostname and ip of the node
require 'digest/md5' #generate and id
require 'json'

class ApplicationLog
	attr_reader  :log_source, :log_filename, :log_datetime, :log_channel, :log_type, :log_message, :id, :type
	def initialize(attributes = {})
		@attributes = attributes
		@attributes.each_pair { |name,value| instance_variable_set :"@#{name}", value}
	end
	def self.type
		'applicationlog'
	end
	def to_indexed_json
		@attributes.to_json
	end
	def self.search(text)
		unless text.empty?
			Tire.search('applicationlog', from: "0", size: "100") do
				query do
    				string "log_message:#{text}*"
  				end
			end.results
		end
	end
	def self.load_file(file_name)
		log_array = Array.new()
		#check if file exists
		if File::exists?( file_name )
			if !File.zero?(file_name)
				#open and parse file
				if File.readable?(file_name)
					name = File::basename(file_name)
					line_number = 0
					IO.foreach(file_name){|line| 
						log_array << log_from_line(line,name)						
						line_number += 1
						#puts "#{line_number}====>#{line}"
						if line_number % 100000 == 0
							#store index every 1000000 records
							puts "Import Log into ES #{line_number}"
							import_into_es(log_array)
							log_array = Array.new()
						end
					}
					puts "Import Log into ES"
					import_into_es(log_array)
				else
					puts "Unable to read file #{filename}"
				end
			else
				puts "File cannot be zero bytes"
			end

		else
			puts "File doesnt exist" 
		end
		#if it does 
		#open and parse file
		#for each line get the object
		#add object to array
		#import index when file is done read
		#exit
	end
	private
	 def self.log_from_line(line,name)
	 	line.strip!
	 	name.strip!
	 	log_source 		= "#{Socket.gethostname};#{Socket.ip_address_list[1].ip_address}"
	 	log_filename 	= name.empty? ? "Unknown" : name
	 	line_array 		= Array.new()
	 	line_array 		= line.split(/\s/)
	 	log_datetime 	= line_array[0..1].join(' ')
	 	log_channel 	= line_array[2].to_s
	 	log_message 	= line_array[3..-1].join(' ')
	 	log_type 		= "info"
	 	if line_array.grep(/success/i)
	 		log_type = "success"
	 	elsif line_array.grep (/failure/i)
	 		log_type = "error"
	 	end
	 	id = Digest::MD5.hexdigest("#{log_source}_#{log_datetime}_#{log_message}")
	 	log = ApplicationLog.new log_source: log_source,
							  log_filename: log_filename,
							  log_datetime: log_datetime,
							  log_channel: log_channel,
							  log_type: log_type,
							  log_message: log_message,
							  type: ApplicationLog.type,
							  id: id
		log	
	 end
	 def self.import_into_es(log_array)
	 	#create mappings
	 	Tire.index 'applicationlog' do
	 		delete	 			
  			import log_array
  			refresh
		end
	 end
end
#puts "Into the void"
ARGV.each do |file|
	ApplicationLog.load_file(file)
end
#results = ApplicationLog.search("338180103")
#p results.size
#ApplicationLog.search("338180103").each do |app|
#	puts JSON.pretty_generate(JSON.parse(app.to_indexed_json))
	#puts app.to_indexed_json
#end
