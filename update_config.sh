
###########################################################################################################
#
#	The api should be used this way
#	$TRACKING_KEY
#	${key as found in `files` associative array} [value set automatically]
# To use this bash file invoke [file].sh major minor suffix
# e.g bash file.sh 1 2 '-alpha'
#
##########################################################################################################

declare -A files=( [version:]='pubspec.yaml' [flutterVersionName=]='android/app/build.gradle' )

TRACKING_KEY=xCfg_version

alpha=`echo $1 | egrep -o '[[:alpha:]]+'`
if [[ -n $alpha ]]; then
	echo `tput setaf 3`To use this bash file invoke [file].sh major minor suffix `tput sgr0`
	echo e.g `tput setaf 4;tput bold`\.\/bash file.sh 1 2 `tput setaf 2`\'-alpha\'`tput sgr0`
	exit 0
else

major=$1
minor=$2
suffix=$3

retVal=''
if [ -z $major ]; then major=0 ; fi
if [ -z $minor ]; then minor=0 ; fi
if [ -z $suffix ]; then suffix='' ; fi

#######################################
# Searches for the lowest version value based on the git rev-list command
# and updates the files in the files global variable having the $TRACKING_VARIABLE
# string followed by the line with the version to be updated.
# GLOBALS:
#   TRACKING_KEY
# ARGUMENTS:
#   $1 the file path in the workspace
#		$2 the variable in the desired config file to be assigned to
# OUTPUTS:
#   Simply updates the specified $1 file
# RETURN:
#   0 if print succeeds, non-zero on error.
#######################################
function search_and_replace_version_argument(){
	local found
	local line
	local replacement
	local argSurround
	found=`cat $1 | grep -o $TRACKING_KEY`
	if [[ $found -ne $TRACKING_KEY ]]; then echo `tput setaf 1` the queried tracking key was not found. Queried key `tput bold` \'$TRACKING_KEY\'  `tput sgr0`;
	else
		line=`grep -on $TRACKING_KEY $1 | egrep -ow '^[[:digit:]]+'`
		let line+=1 
		compute_version
		replacement=$retVal
		# Check for the surround argument in the file match
		argSurround=`egrep -o "$TRACKING_KEY\s+.*\bsurround\s+.{1}" $1 | egrep -o '.$'`
		if [ -n $argSurround ]; then replacement="$argSurround$replacement$argSurround" ; fi
		replacement="$2 $replacement"
		sed -i.original "${line}s/.*/${replacement}/" $1
	fi
}


function compute_version(){
	local branch
	local commits
	branch=`git branch | grep -o '[^\*]*'`
	commits=`git rev-list --count $branch`
	retVal=${major}.${minor}.${commits}${suffix}
}

for key in ${!files[@]}
	do
		search_and_replace_version_argument "${files[$key]}" $key
	done
	tput setaf 2
	echo done!
	echo Set version queries by \"$TRACKING_KEY\" to \"$retVal\"
	tput sgr0
fi
