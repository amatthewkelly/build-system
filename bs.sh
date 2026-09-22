#!/bin/bash

echo "hello, I am your bash script"

# run a daemon to check folder and pipe to python script
# TODO: switch from nohup to launchd for boot persistence
# as of now bs.sh will need to be run after each boot for folder watching
nohup fswatch -0 --event Updated --event Created --event Renamed \
	"/Users/aaronkelly/Library/Mobile Documents/com~apple~CloudDocs/writing/build-system" \
	| xargs -0 -n 1 -I {} sh -c '[ -f "{}" ] && python3 bs.py "{}"' \
	> logs.txt 2>&1 &


# end python script

# move newly created file to website project folder

# edit 'writing page to inc new hyperlink'
# recursively input to {{NEW LINK}} include new {{NEW LINK}} after

# call git stuff in website folder to commit and push new file

# move file to 'built' subfolder

# any errors are logged throughout

# end of script
