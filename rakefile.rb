require "rake/clean"
require 'yaml'
# Load the yaml configuration in:
$config=YAML.load_file("./rakeconfig.yml")
desc %{default task is to draft the slides as a pdf. Change by pointing default to "brownbag:reveal.rmd" or "brownbag:reveal.md"}
# task :default=>["clobber"]
# set dependency based on yaml configuration.
task :default =>if $config["markdown_format"]=="html";["brownbag:installhtml","clobber"] ;else;["brownbag:installpdf","clobber"]; end
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


	# get the md files and exclude files mentioned in the config.yaml and any files with the term pandoc in the name:
	my_md_files=FileList[Dir.glob("./*.md", File::FNM_CASEFOLD)]
	# Get exclude patterns from the config.yml, pass them here to identify files not to be touched by rake:
	$config["excludes"].each do |t| 
		my_md_files=my_md_files.exclude(Regexp.new(t))
	end

	my_md_files= my_md_files - my_rmd_files.ext("md")
	puts my_md_files.class
	puts my_rmd_files.class

	task :installpdf => my_md_files.ext('pdf')
	task :installpdf => my_rmd_files.ext('pdf')
	task :installhtml => my_rmd_files.ext('html')
	task :installhtml => my_md_files.ext('html')

	namespace :installhtml do
	my_md_files.each do |t|
		file t.ext("html")=>t do |outfile|
			proc_and_move(outfile,1,0,1)
		end
	end
	my_rmd_files.each do |t|
		file t.ext("html")=>t do |outfile|
			proc_and_move(outfile,1,1,1)
		end
	end
	end

	namespace :installpdf do
		my_md_files.each do |t|
			file t.ext("pdf")=>t do |outfile|
				proc_and_move(outfile,2,0,1)
			end
		end
		my_rmd_files.each do |t|
			file t.ext("pdf")=>t do |outfile|
				proc_and_move(outfile,2,1,1)
			end
		end
	end
	my_reveal_location=FileList[$config["relative_reveal_location"]].pathmap("%{/$,}p")
	define_method(:proc_and_move) do |t,*args|
		unless args[0]==2
			if args[1]==1
				# script that runs knitr on rmd for pandoc files
				system %{#{REVEAL_SCRIPT_TO_RUN.sub("@input_file",t.source).sub("@output_file",t.name.ext("md"))}	}
			end
			if args[2]==1
				# now we process the knit md's via pandoc and the revealjs template
				system %{pandoc -f markdown -t revealjs --template="#{$config["reveal_template_location"]}" #{t.source} -o #{$config["reveal_html_output_path"]}#{t.name.pathmap('%f')} --mathjax --metadata=reveal_path=#{my_reveal_location}}
			end
			return
		end
		if args[1]==1
		# script that runs knitr on rmd for pandoc files
		puts "other#{t.name},#{t.source}"
		system %{#{SCRIPT_TO_RUN.sub("@input_file",t.source).sub("@output_file",t.name.ext("md"))}}
		end
		if args[2]==1
			# add options to pass to pandoc here:
			sh %Q{echo "\\usefonttheme{professionalfonts}">>pkg_insert.tmp}
			sh %Q{echo "\\usepackage{unicode-math}">>pkg_insert.tmp}
			sh %Q{echo "\\setmathfont{xits-math.otf}">>pkg_insert.tmp}
			sh %Q{pandoc #{t.source.ext("md")} -f markdown  -t beamer --slide-level=2  -o #{t.name.ext('tex')} -V theme:Amsterdam -s --biblatex --bibliography="/s/dissandprojects.bib" --template=class_presentation.beamer --toc  --include-in-header=pkg_insert.tmp}
			sh %Q{latexmk -pdf -quiet -xelatex #{t.name.ext()} }
			system %Q{latexmk -c #{t.name.ext('')}}
			# Put clean here too so that we ensure it's run when latex is run and only after latex finishes.
			desc %{Be careful with clean here, because it will remove tex files}
			CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*\.(snm|out\.ps|nav|vrb|run\.xml|tex|tmp|blg|toc|log|aux|bbl|fls|fdb_latexmk))/=~t end])
			CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*(blx.bib))/=~t end])
		end
	end


	CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*\.(snm|out\.ps|nav|vrb|run\.xml|tex|tmp|blg|toc|log|aux|bbl|fls|fdb_latexmk))/=~t end])
	CLEAN.include(FileList[Dir.glob("*").find_all do |t| /(.*(blx.bib))/=~t end])
end
