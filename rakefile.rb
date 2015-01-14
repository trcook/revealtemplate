require "rake/clean"
require 'yaml'

# Load the yaml configuration in:
$config=YAML.load_file("./rakeconfig.yml")

# set dependency based on yaml configuration.
task :reveal =>if $config["markdown_format"]=="md";"brownbag:revealmd" ;else;"brownbag:revealrmd"; end


desc %{default task is to draft the slides as a pdf. Change by pointing default to "brownbag:reveal.rmd" or "brownbag:reveal.md"}
task :default=>["brownbag:install","clobber"]

%{clobber is run with every pass of the rake file (if needed). It also puts out the files to be cleaned.}
task :clobber do puts CLEAN end
	


namespace :brownbag do

### THE SCRIPT TO RUN -- MAKE SURE IT'S NOT INDENTED -- script goes bretween EOS's @input_file and @output_file are replaced with input and output files.
SCRIPT_TO_RUN =<<EOS
Rscript -e 'require(knitr);options("revealout"="n");render_markdown();knit("@input_file", output="@output_file")'
EOS

REVEAL_SCRIPT_TO_RUN=<<EOS
Rscript -e 'require(knitr);options("revealout"="y");render_markdown();knit("@input_file", output="@output_file")'
EOS

	my_rmd_files=FileList[Dir.glob("./*.rmd", File::FNM_CASEFOLD)]

	my_revealmd_md_files=FileList[Dir.glob("./*.md", File::FNM_CASEFOLD)]
	#: this needs to exclude pandoc extensions. this is crucial.


	# Get exclude patterns from the config.yml, pass them here to identify files not to be touched by rake:
	$config["excludes"].each do |t| 
		my_revealmd_md_files=my_revealmd_md_files.exclude(Regexp.new(t))
	end

	# Remainder of configuration for md files when processed from rmd or for pandoc to pdf
	puts "my_revealmd_md_files are #{my_revealmd_md_files}"
	my_reveal_md_files=my_rmd_files.ext("md")
	my_pandoc_md_files=my_reveal_md_files.pathmap("%d/pandoc_%f")

	# setup target (output) files.
	out_file=my_pandoc_md_files.pathmap("%{pandoc_,}n.pdf")
	out_file=FileList[File.expand_path(out_file.to_s,$config["pdf_output_path"])]
	puts out_file

	# strip trailing / from paths and put relative location of reveal.js in a variable.
	my_reveal_location=FileList[$config["relative_reveal_location"]].pathmap("%{/$,}p")

	desc %{Build RMD files;}
	task :install
	task :install=>my_pandoc_md_files
	task :install=>[out_file]

	desc %{Builds reveal md variant of slides.rmd}
	file my_reveal_md_files=>my_rmd_files

	
	task :revealrmd=>my_reveal_md_files

	# define file processing for default task ("brownbag:install")
	namespace :install do
		# setup rule that points to the right rmd for each of my_pandoc_md_files
		rule (%r{pandoc_.*\.md}) => lambda{|objfile| my_rmd_files.find{objfile.pathmap("%{pandoc_,}n")}} do |t|
			puts "#{t.source}#{t.name}"
	 		proc_and_move(t)
		end
	end

	# define rmd file handling for rmd files.
	namespace :revealrmd do
		# technically, this skips a step and uses proc_and_move to get from rmd all the way to html. That is fine since the .md files are never directly edited in this context. TODO It should be changed later because it is confusing (we'd expect '.html' here as the rule target.)
		rule ".md" =>".rmd" do |t|
			puts "#{t.source}#{t.name}"
	 		proc_and_move(t,1)
		end
	end

	task :revealmd=>my_revealmd_md_files.ext("html")


	namespace :revealmd do
		rule ".html"=>".md"  do |t|
			puts "#{t.name} running revealmd"
			system %{pandoc -f markdown -t revealjs --template="#{$config["reveal_template_location"]}" #{t.source} -o #{t.name} --mathjax --metadata=reveal_path=#{my_reveal_location}} 
		end
	end

	# rule that points to correct pandoc_*.md file for each of the desired output pdf's
	rule ".pdf" =>->(objfile){objfile.pathmap("%{,pandoc_}n.md")} do |t|
		# add options to pass to pandoc here:
		sh %Q{echo "\\usefonttheme{professionalfonts}">>pkg_insert.tmp}
		sh%Q{echo "\\usepackage{unicode-math}">>pkg_insert.tmp}
		sh %Q{echo "\\setmathfont{xits-math.otf}">>pkg_insert.tmp}
		sh %Q{pandoc #{t.source.ext("md")} -f markdown  -t beamer --slide-level=2  -o #{t.name.ext('tex')} -V theme:Amsterdam -s --biblatex --bibliography="/s/dissandprojects.bib" --template=class_presentation.beamer --toc  --include-in-header=pkg_insert.tmp}
		sh %Q{latexmk -pdf -quiet -xelatex #{t.name.ext()} }
		system %Q{latexmk -c #{t.name.ext('')}}
		# Put clean here too so that we ensure it's run when latex is run and only after latex finishes.
		desc %{Be careful with clean here, because it will remove tex files}
		CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*\.(snm|out\.ps|nav|vrb|run\.xml|tex|tmp|blg|toc|log|aux|bbl|fls|fdb_latexmk))/=~t end])
		CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*(blx.bib))/=~t end])
	end

	CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*\.(snm|out\.ps|nav|vrb|run\.xml|tex|tmp|blg|toc|log|aux|bbl|fls|fdb_latexmk))/=~t end])
	CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*(blx.bib))/=~t end])

	define_method(:proc_and_move) do |t,*args|
		unless args.empty?
			# script that runs knitr on rmd for pandoc files
			system %{#{REVEAL_SCRIPT_TO_RUN.sub("@input_file",t.source).sub("@output_file",t.name)}	}

			# now we process the knit md's via pandoc and the revealjs template
			system %{pandoc -f markdown -t revealjs --template="#{$config["reveal_template_location"]}" #{t.name} -o #{$config["reveal_html_output_path"]} --mathjax --metadata=reveal_path=#{my_reveal_location}}
			return
		end

		# script that runs knitr on rmd for pandoc files
		puts "other#{t.name},#{t.source}"
		system %{#{SCRIPT_TO_RUN.sub("@input_file",t.source).sub("@output_file",t.name)}}
		end
end
