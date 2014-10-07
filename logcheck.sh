#!/bin/bash
########################################
# logcheck.sh
# 
# Copies daily sections from system logfiles and stores or emails them
#
# 7 Oct 2014	SMB 	Initial version
########################################

# Setup variables

# Current date, in http log format
# [Ddd Mmm DD hh:mm:ss YYYY]
# We're looking for "[Ddd Mmm DD" only

DATE=`date +'%m.%d.%y'`
LOGDATE="[`date +'%a %b %d'`"
MAX_LOGS=5 # Keep 5 days' worth
EVIDENCE="\{\ \:\;\}\;"
HOSTNAME=`hostname`
FILENAME="$DATE.log"
EFILES=0
DFILES=0

######
# Functions
######

usage () 
{
	echo "Usage: $0 -l <logfile location> -o <output location, or email address>\n"
        exit 0
}

count_files ()
{ # Used to count amount of existing files and how many we need to remove in the logrotate function
	EFILES=`ls -tr $OUTPUT` # Create an array of filenames, sorted in order of oldest first
        NUM_FILES=${EFILES[@]} # $NUM_FILES is the number of files in the $OUTPUT directory, counted by
# the array we created above. 
        DFILES=(($NUM_FILES - $MAX_FILES)) # DFILES is the number of files we need to delete to have 
# $MAX_FILES amount of files in $OUTPUT. If EFILES has 7 files listed, then DFILES will be 2.
	return 0;
}

get_args ()
{ # Find out how we were invoked
	if [$# -lt 1] # if no arguments provided to the script
	then
		echo
		echo "Usage: $0 -l <logfile location> -o <output location, or email address>\n"
	fi
	
	# Parse out command line flags and args

	while getopts ":l:o:h" OPT
	do
		case $OPT in
			l) # -l was detected, put the logfile location in a variable
				LOGFILE=$OPTARG
			;;
			
			o) # -o was detected, put the output location in another variable
				if grep -q "\@" $OPTARG # the argument to -o is an email address
					then
						EMAIL=$OPTARG
					else
						OUTPUT="${OPTARG}/${HOSTNAME}/"
				fi
			;;
			*) # Help requested
				usage
			;;
		esac
	done
	return 0;
}

extract_logs () 
{ # This part will scan the logs looking for BASH exploits, and record them in a file or email
	if [ -z $OUTPUT ] #if the output variable is not set, then email logs
	then
		egrep $EVIDENCE $LOGFILE >> `mailx -s "bash exploits found on `hostname`" $EMAIL`
	else # $OUTPUT is defined, meaning that an email address was not found so it must be a filename
		if [ -x $OUTPUT ] #if the directory doesn't exist, create it
		then
			mkdir -p $OUTPUT
		fi
		rotate_logs
		egrep $EVIDENCE $LOGFILE >> "$OUTPUT/$FILENAME"
	fi
}

rotate_logs ()
{ 
	count_files
	if [ $DFILES -ge 0 ] 
# If there are $MAX_FILES, or more, of files in the log directory.  We'll need to delete at least one 
# (DFILES=0) or more (DFILES>0)
	then

# We're going to step through the $EFILES array up to the number of $DFILES, pull a filename from 
# the EFILES array by index number, and then delete that file.
		while [$DFILES -ge 0] # $DFILES is at least 0
		do
			for((i=0; i <= $DFILES; i++)) # Step through $DFILES amount of elements
			{	
				rm "$OUTPUT/${EFILES[$i]}" # use absolute pathname
			}
			count_files; # Recheck file counts to either stay in the loop or exit it.
		done
	else
		# Less than max amount of files present; go ahead and write one by returning to extract_logs.
		return 0;
	fi
	return 1;
}



#######
# Main section
######

get_args # Figure out what we need to do
extract_logs	# filter for evidence, and either email it or write it to a directory defined in $OUTPUT


