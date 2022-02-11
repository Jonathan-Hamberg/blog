#!/bin/sh

# Call getopt to validate the provided input.
# : means the parameter is required
options=$(getopt -o a --long album:,help -- "$@")

# Verify that the parameters are in the correct format.
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}

readable_duration()
{
	# Get the number of milliseconds.
    ms=$1
	# Get the number of seconds.
    s=$(($ms/1000))
	# Get the number of minutes.
    m=$(($s/60))
	# Get the number of hours.
    h=$(($m/60))

	# Modulus the milliseconds in a second.
    ms=$(($ms%1000))
	# Modulus the seconds in a minute.
    s=$(($s%60))
	# Modulus the minutes in an hour.
    m=$(($m%60))

	# Print the format that make the must sense for the duration.
    if [ $1 -lt 1000 ]; then
        printf "$ms""ms" $ms
    elif [ $1 -lt 10000 ]; then
        printf "%1.1f""s" $s
    elif [ $1 -lt 60000 ]; then
        printf "%d""s" $s
    elif [ $1 -lt 3600000 ]; then
        printf "%d:%02d""m" $m $s
    else
        printf "%d:%02d""h" $h $m
    fi
}

# Get the current time in milliseconds since the Epoch.
get_time_ms()
{
	echo $(($(date +%s%N)/1000000))
}

help()
{
    echo cdripper --album name
}

artist=""
album=""

echo $options
eval set -- "$options"
while true; do
    case "$1" in
    -a|--album)
        shift;
        album=$1
        ;;
    -h|--help)
        help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

# Get rid of trailing / if presesnt.
album=$(echo $album | sed -e 's#/$##')

# Make sure the destination directory is present.
mkdir -p $album

# Find the next available disk number.
for i in $(seq -f "%02g" 1 99)
do
    if [ ! -f "$album/Disk$i.mp3" ]; then
        diskNumber=$i
        break
    fi
done

# Print what was found to the console.
echo "$album/Disk$diskNumber"

rip_start=$(get_time_ms)

# Rip the audio cd into the current directory.
cdparanoia 1- Disk$diskNumber.wav

rip_stop=$(get_time_ms)

# Check to see if the CD was present in the optical media drive.
if [ $? -ne 0 ]; then
    echo "cdparanoia could not read cd."
    exit 1
fi

# TODO(jrh) add query phase to check to see if CD is present in optical media 
# drive and to print the CD TOC to the user.

# Eject the disk from the drive.
eject

#oggFile=$album/Disk$diskNumber.ogg
mp3File=$album/Disk$diskNumber.mp3
#flacFile=$album/Disk$diskNumber.flac

transcode_start=$(get_time_ms)

# Convert disk to flac.
#sox Disk$diskNumber.wav $flacFile &

# Convert disk to ogg.
#sox Disk$diskNumber.wav $oggFile &

# Convert disk to MP3
sox Disk$diskNumber.wav $mp3File & 

wait

# Delete the raw disk audio.
rm Disk$diskNumber.wav

transcode_stop=$(get_time_ms)

echo Rip Time: $(readable_duration $(($rip_stop - $rip_start)))
echo Transcode Time: $(readable_duration $(($transcode_stop - $transcode_start)))

# Report success.
exit 0
