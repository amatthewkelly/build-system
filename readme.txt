this is a build system for my personal site. 

i have a static site hosted on github pages. the pages are written in pure html and each reference a css file. id like to come up with a system where i save a plain text document in a folder and it automatically builds a page around it. that is, generates the boilerplate according to my site's template, puts the saved text in to <p> tags as appropriate, generates a <p> tag at the top for a date, and then saves it in the site folder. I'd kind of like to write some of this in bash, perhaps have jobs that run and check the folder for new text documents to build into pages. all in bash could be fun, i'd also maybe use python for the actual generating boiler plate. I've never built anything like this, but i made my site by hand. this seems like a fun next step.

workflow wise there will be a folder for writing/text that will be periodically scanned.

then there will be the location of the python script that puts the text into the boilerplate plus the text plus the correct title and other html references
i should probably have an htmp template in the same folder as the python script
and a css template... no hmm i think i will use the same css file for each, this can just live on the webpage.... but a copy should be in the build system just for testing purposes

so i need to know how to
1. run a daemon to check folder - fswatch? 
2. call a python script within the bash script
3. open a file in the python script.
4. break the contents by paragraph
5. create a copy of the html template. open (?) (edit?) it with: 
- paragraphs in tags - date - url - page title
- title will be taken from the first line of the file. url will be the same as the filename. date will be taken from the computer system.
6. python script saves file with correct name and closes itself
- html filename will be same as text file
7. bash script moves new file into my website project in the correct folder
8. bash script calls git stuff in website folder to push it to repo
9. script closes
0. errors are logged in text file in build-system folder

** bonus: i just have it continually monitor a folder with all my website files and builds and pushes new stuff and updates old stuff as everything changes
misc. i will also want error handling around the file opening/editing

edge cases for bash script are 
- folder is empty 
- folder has files other than text files (ignore them, send alert also?)

general notes

- yes bash should wait for each file to finish before continuing.....perhaps tho if there is an error it marks it as incomplete and moves onto the next one. although i dont anticipate dumping more than one file at a time into the folder this is a good edge case
- new paragraphs will be line breaks
- text that has html like qualities ...... first version should not handle this case. but perhaps important to escape them
- no accomodation for naming collisions in initial version
- commits could be a chron job actually.... stage them then batch. cleaner than lots of automated pushes in the repo history. instant is fine for the first version tho. 
- retry push three times then flag if fails. i dont want this in the first version. i want a basic working pipeline first
- preferred logging..... i think i'd like logging to happen to a text file in the build system folder i can check on my own
- re first line: i want to default to the first line in the file being the title. this will be on the user (me). although i do want to make a template file that examples my own specs for text input into the folder
paragraphs demarcated by single line break in text file
- placeholders in html template like {{TITLE}}, {{DATE}}, {{CONTENT}}) so python can find and replace 
- bash and python log errors in same file
