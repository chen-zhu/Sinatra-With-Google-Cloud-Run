require 'sinatra'
require 'google/cloud/storage'
require 'json'
#Sinatra Doc: https://github.com/sinatra/sinatra#conditions

# redirect with 302 returned. 
get '/' do
  redirect "/files/", 302
end

# Read the files list from the GCS and echo out as json string
# name of file object is normally separted out two consecutive digits 
# of the hex digest
get '/files' do
	storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
	bucket = storage.bucket 'cs291_project2', skip_lookup: true
	all_files = bucket.files 
	SHA256_list = Array[]
	all_files.all do |file|
		file_name_parsed = file.name.gsub("/", "")
		if (!file_name_parsed.match?(/^[A-Fa-f0-9]{64}$/)) 
			next
		end
  		SHA256_list << file_name_parsed
  	end

  	SHA256_list.sort
  	
  	#status 200
  	#body SHA256_list.to_json
  	return Array[200, SHA256_list.to_json] #use explicit return here!
end

# retrieve file content from the Google Cloud Storage by provided Digest.
get '/files/:digest' do
	digest = params['digest']

	# 1. Validate digest by using Regex Match here!
	if (!digest.match?(/^[A-Fa-f0-9]{64}$/)) 
		return Array[422, "Digest Not Valid\n"]
	end
	
	# 2. parse the digest into file object name/path
	digest.insert(4, "/")
	digest.insert(2, "/")

	# 3. file lookup.
	# https://googleapis.dev/ruby/google-cloud-storage/latest/Google/Cloud/Storage/Bucket.html#file-instance_method
	storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
	bucket = storage.bucket 'cs291_project2', skip_lookup: true
	file_lookup = bucket.file digest, skip_lookup: false

	if file_lookup.nil? 
		return Array[404, "Hey the file is not found!\n"]
	end

	original_content_type = file_lookup.content_type
	
	# download file to StringIO
	# https://googleapis.dev/ruby/google-cloud-storage/latest/Google/Cloud/Storage/File.html#download-instance_method
	downloaded = file_lookup.download
	downloaded.rewind
	
	# response with 200 code with Content-Type as header and data as Body!
	return Array[200, {"Content-Type" => original_content_type}, downloaded.read]
end

post '/files' do
	require 'stringio'
	require 'digest'

	# 1. check file query!
	file_params = params["file"]
	if file_params.nil?
		return Array[422, "No File Parameter\n"]
	end

	#file_name = file_params["filename"]
	file_type = file_params["type"]
	temp_file = file_params["tempfile"]
	
	# 2. check the file size!
	size = temp_file.size()
	if (size > 1024 * 1024) 
		return Array[422, "Oversized File!\n"]
	end

	digest = Digest::SHA256.hexdigest temp_file.read
	#temp_digest = digest
	return_digest = Array[Digest::SHA256.hexdigest temp_file.read] #hummm weird. it somehow has 'pass by reference'
	digest.insert(4, "/")
	digest.insert(2, "/")

	# Process File! 
	# https://ruby-doc.org/stdlib-2.6.5/libdoc/stringio/rdoc/StringIO.html
	# https://googleapis.dev/ruby/google-cloud-storage/latest/Google/Cloud/Storage/Bucket.html#create_file-instance_method
	storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
	bucket = storage.bucket 'cs291_project2', skip_lookup: true
	# 3. If file exists, return!
	file_lookup = bucket.file digest, skip_lookup: false
	if file_lookup
		return Array[409, "Digest Code Already Exists\n"]
	end

	# 4. If file not exists, perform upload!
	# content: tempfile, path: digest, 
	bucket.create_file file_params["tempfile"], digest, content_type: file_type

	return Array[200, return_digest.to_json]
end

delete '/files/:digest' do
	# https://googleapis.dev/ruby/google-cloud-storage/latest/Google/Cloud/Storage/File.html#delete-instance_method
	digest = params['digest']

	# 1. Validate digest by using Regex Match here!
	if (!digest.match?(/^[A-Fa-f0-9]{64}$/)) 
		return Array[422, "Digest Not Valid\n"]
	end
	
	# 2. parse the digest into file object name/path
	digest.insert(4, "/")
	digest.insert(2, "/")

	# 3. file lookup.
	# https://googleapis.dev/ruby/google-cloud-storage/latest/Google/Cloud/Storage/Bucket.html#file-instance_method
	storage = Google::Cloud::Storage.new(project_id: 'cs291-f19')
	bucket = storage.bucket 'cs291_project2', skip_lookup: true
	file_lookup = bucket.file digest, skip_lookup: false
	if(file_lookup)
		file_lookup.delete
	end
	#DELETE should be idempotent!!!! 
	return Array[200, ""]
end





