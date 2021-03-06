require 'net/http'
require 'webrick'
include WEBrick

class Tonka

	attr_accessor :options, :site_name, :action, :messages

	attr_reader :version

	def initialize(options=[])

		@version = "0.0.8";

		@options = options || ARGV
		if !@options[0].nil?

			parse_options(@options)

		else
			display_usage
		end
	end

	def serve(port)
		puts "Starting server: http://#{Socket.gethostname}:#{port}"
		server = HTTPServer.new(:Port=>port,:DocumentRoot=>Dir::pwd )
		trap("INT"){ server.shutdown }
		server.start
	end

	def make_directories
		if !Dir.exist? $SITE_NAME
			Dir.mkdir $SITE_NAME
			Dir.mkdir "#{$SITE_NAME}/stylesheets"
			puts "\t\tbuilt ".green+"#{$SITE_NAME}/stylesheets/"

			Dir.mkdir "#{$SITE_NAME}/javascripts"
			puts "\t\tbuilt ".green+"#{$SITE_NAME}/javascripts/"
		else
			puts "a '#{$SITE_NAME}' directory already exists!"
			display_usage
		end
	end

	def make_files
		Tonka::HTML.new(@options).render(@options)
	end

	def parse_options(options=[])

		@action = @options[0]

		case @action

		when "-v"

			puts @version

		when "build"
			#handles the 'build' command

			$SITE_NAME = @options[1] || 'sites'

			jquery = true if @options[2] == '-jquery'
			css_reset = true if @options[2] == '-jquery'

			make_directories
			make_files

			puts "\n\t\tthe construction of "+"#{$SITE_NAME}".green+" is now complete!"

		when "destroy"
			#handles the 'destroy' command

			$SITE_NAME = @options[1] || 'sites'
			if Dir.exist? $SITE_NAME
				system("rm -rf #{$SITE_NAME}")
				puts "\t\tdemolished ".red+"#{$SITE_NAME}"
			else
				"Oops! There is no directory called #{$SITE_NAME}!"
			end

		when "add"
			#handles the 'add' command

		when "serve"
			port_string = @options[1] || "2000"

			serve(port_string)
		else
			puts "Oops! I don't know that one."
			display_usage
		end

	end

	def display_usage
		usage_array = ["usage: tonka <action> SITE_NAME [-options] BODY_TEXT\n\n",

									 "The most common actions:\n\n",
									 "build\s\t\t\tbuilds a basic static site with the name passed in as SITE_NAME\n\n",
									 "destroy\s\t\t\tdestroys a previously built site with the name passed in as SITE_NAME\n\n",
									 "serve\s\t\t\tserves your files using WEBrick on port 2000 (a different port can be passed in as an argument)\n\n",
									 "The most common options:\n\n",
									 "-bootstrap \t adds Bootstrap front-end int your stylesheets, javascripts and index.html\n",
									 "-jquery \t\tadds jquery to index.html file.\n",
									 "-underscore \t\tadds underscore.js to the javascripts folder and the index.html file.\n",
									 "-backbone \t\tadds backbone.js, underscore.js, and jquery.js to the javascripts folder and the index.html file.\n",
									 "-handlebars \t\tadds handlebars.js to the javascripts folder and the index.html file.\n",
									 "-d3 \t\t\tadds d3.js to the javascripts folder and the index.html file.\n",
									 "-raphael \t\tadds raphael.js to the javascripts folder and the index.html file.\n",
									 "-angular \t\tadds angular.js to the javascripts folder and the index.html file. Also adds <html ng-app> at top of the index file.\n"
									 ]

		puts usage_array.join("")
	end

end

class Tonka::HTML
	#CSS processing module
	attr_accessor :layout

	def initialize(options=[])
		@layout_arrays = []
		@layout_array_0 = ["<!DOCTYPE html>\n"]
		if options.include?("-angular")
			@layout_array_1 = ["<html ng-app>\n"]
		else
			@layout_array_1 = ["<html>\n"]
		end
		@layout_array_2 = ["<head>\n","\t<title>#{$SITE_NAME}</title>\n"]
		@link_array = add_css_files(options)
		@script_array = add_js_files(options)
		@layout_array_3 = ["</head>\n","<body>\n"]
		@script_array_2 = add_handlebars_template(options)
		@layout_array_4 = ["</body>\n","</html>"]
	end

	def render(options)
		@index_html = File.new("#{$SITE_NAME}/index.html","w")

		@layout = @layout_array_0.join("") + @layout_array_1.join("") + @layout_array_2.join("") + @link_array.join("") + @script_array.join("") + @layout_array_3.join("") + @script_array_2.join("") + @layout_array_4.join("")

		@index_html.puts @layout
		@index_html.close
		puts "\t\tbuilt ".green+"#{$SITE_NAME}/index.html"

	end

	def add_js_files(options)
		tags = []
		options.each do |option|
			library_name = option.gsub("-","")
			if library_name == "backbone" && !options.include?("jquery")
				jquery = Tonka::JS.new("jquery")
				tags << jquery.script_tag
			end
			if library_name == "backbone" && !options.include?("underscore")
				underscore = Tonka::JS.new("underscore")
				tags << underscore.script_tag
			end
			if library_name == "bootstrap" && !options.include?("jquery")
				jquery = Tonka::JS.new("jquery")
				tags << jquery.script_tag
			end
			Tonka::JS.libraries.each do |library|
				if library[library_name]
					js = Tonka::JS.new(library_name)
					tags << js.script_tag

				end
			end
		end
		tags << Tonka::JS.new("app").script_tag
		return tags
	end

	def add_css_files(options)
		tags = []
		options.each do |option|
			library_name = option.gsub("-","")
			Tonka::CSS.libraries.each do |library|
				if library[library_name]
					css = Tonka::CSS.new(library_name)
					tags << (css.link_tag + "\n")

				end
			end
		end
		tags << (Tonka::CSS.new("style").link_tag + "\n")
		return tags
	end

	def add_handlebars_template(options)
		tag = []
		handlebars_template = "\t<script id='template' type='text/x-handlebars-template'>\n \t</script>\n"

		options.each do |option|
			library_name = option.gsub("-","")
			if library_name == "handlebars"
				tag << handlebars_template
			end
		end

		return tag
	end



end

class Tonka::CSS
	#CSS processing module
	attr_accessor :layout, :link_tag, :libraries

	def self.libraries
		[
			{"bootstrap" => "http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"}
		]
	end

	def initialize(file_name, options=[])
		@link_tag = generate_file(file_name)
	end

	def generate_file(file_name)

		css_file = File.new("#{$SITE_NAME}/stylesheets/#{file_name}.css","w")
		if file_name == "style"
			css_file_content = "/*INSERT CSS*/"
		else
			uri = ''
			Tonka::CSS.libraries.each do |library|
				uri = library[file_name] if library[file_name]
			end
			css_file_content = Net::HTTP.get(URI(uri))
		end
		css_file.puts css_file_content
		css_file.close
		link_tag = "\t<link rel=\"stylesheet\" type=\"text/css\" href=\"stylesheets/#{file_name}.css\" />"
		puts "\t\tbuilt ".green+"#{$SITE_NAME}/stylesheets/#{file_name}.css"
		return link_tag
	end

end

class Tonka::JS
	#CSS processing module
	attr_accessor :layout, :script_tag, :libraries

	def self.libraries
		[
			{"jquery" => "http://code.jquery.com/jquery-1.11.1.min.js"},
			{"underscore" => "http://underscorejs.org/underscore-min.js"},
			{"backbone" => "http://backbonejs.org/backbone-min.js"},
			{"handlebars" => "http://builds.handlebarsjs.com.s3.amazonaws.com/handlebars-v1.3.0.js"},
			{"d3" => "http://d3js.org/d3.v3.min.js"},
			{"raphael" => "http://cdn.rawgit.com/DmitryBaranovskiy/raphael/master/raphael-min.js"},
			{"angular" => "http://ajax.googleapis.com/ajax/libs/angularjs/1.3.0-beta.13/angular.min.js"},
			{"bootstrap" => "http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"}
		]
	end

	def initialize(file_name,options=[])
		@script_tag = generate_file(file_name)
	end

	def generate_file(file_name)

		js_file = File.new("#{$SITE_NAME}/javascripts/#{file_name}.js","w")
		if file_name == "app"
			js_file_content = "console.log('feed me javascripts')"
		else
			uri = ''
			Tonka::JS.libraries.each do |library|
				uri = library[file_name] if library[file_name]
			end
			js_file_content = Net::HTTP.get(URI(uri))
		end
		js_file.puts js_file_content
		js_file.close
		script_tag = "\t<script src='javascripts/#{file_name}.js'></script>\n"
		puts "\t\tbuilt ".green+"#{$SITE_NAME}/javascripts/#{file_name}.js"
		return script_tag
	end



end

class String
	# text colorization
	def colorize(color_code)
		"\e[#{color_code}m#{self}\e[0m"
	end

	def red
		colorize(31)
	end

	def green
		colorize(32)
	end

	def yellow
		colorize(33)
	end

	def pink
		colorize(35)
	end
end
