# README
* Last Updated 11-25-2014 02:41 

This is a basic template for creating a reveal.js presentation that can be deployed in two different ways. 

## Git Structure:

There are 3 notable subtrees in this project, each of which is based on my fork of other notable repos:
- trcook/reveal.js -- my fork of reveal.js -- forked from hakimel/reveal.js
  - Located at /reveal.js
- trcook/Reveal.js-TOC-Progress  -- forked from e-gor/Reveal.js-TOC-Progress
  - Located at /reveal.js/plugin/Reveal.js-TOC-Progress
  - note: subdirs symlinked to /reveal.js/plugin/
- trcook/Reveal.js-Title-Footer  -- forked from e-gor/Reveal.js-Title-Footer
  - Located at /reveal.js/plugin/Reveal.js-Title-Footer
  - note: subdirs symlinked to /reveal.js/plugin/



# Installation: 
* At the moment, the easiest way is to run the following from term:
	git clone http://github.com/trcook/revealtemplate


* (optional): run grunt:
* from the root of the repo: 

```{bash}	
cd reveal.js
npm install
```

You may need to link some files after installing submodules: 
* from root of git repo:
	cd ./reveal.js/plugins
	ln -s ./Reveal.js-TOC-Progress/plugin/toc-progress/ ./
	ln -s ./Reveal.js-Title-Footer/plugin/Title-Footer/ ./



# Configuration

open rakeconfig.yml and configure as appropriate. Settings are commented and should be straightforward. They are set at usable defaults. 




# Editing:


* Create a md or rmd file (depending on how you setup rakeconfig.yml). 
* to generate: 
	* run rake reveal
* to generate as a pdf: 
	* run rake (probably needs configuring, look at the rakefile task definition for brownbag:install)

* alternatively, you could the md into the reveal.js/index.html using the proscribed way of feeding an md into reveal. I don't like doing it this way since I usually want to preprocess with pandoc to get citations etc. The file ./reveal.js/index.html is set up to do this out of the box and read from the file talk.md. It will seperate in a particular way based on this in the html: 

```{html}
<section data-markdown="../my_talk.md"  data-separator="^\n\n\n"  
         data-vertical="^---"  
         data-notes="^Note:"  ></section>  
```


* you need to pick one method or another, they won't both work since the syntax is slightly different between the two methods:



# remotes to add
There are a few handy remotes to add to cloned repo. I can't figure out how to get these to come with the repo when it's cloned, so they have to be added manually:

```{sh}
git remote add revealjs https://www.github.com/trcook/revealjs.git -t with-format 
git remote add revealtoc https://www.github.com/trcook/Reveal.js-TOC-Progress.git 
git remote add revealfooter https://www.github.com/trcook/Reveal.js-Title-Footer.git 
```
