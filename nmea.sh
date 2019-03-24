#####
# Freifunk GPS Coordinates Updater
# Usage:
# ./nmea.sh USB PATH_TO_DEVICE
# ./nmea.sh NET IP_ADDRESS PORT
#####

lat_old=0
lon_old=0

# convert NMEA0183 to Decimal minutes
DecMin_conv() {
	local dataset=$1
	local coord=$2
	local direction=$3

	# get minutes from $dataset
	# cut: get coordinates string from line
	# sed1: delete dot
	# sed2: grep first seven numbers
	minutes=$(echo $dataset | cut -d',' -f$coord | sed -e 's/\.//g' -e 's/.*\(.\{6\}\)$/\1/')
	# make integer and convert minutes
	minutes_calc=$((`expr $(echo $minutes) + 0` * 1000 / 600))
	# get degrees from $dataset
	# cut: get degree string from line
	# sed1: delete dot
	# sed2: delete last seven numbers
	# sed3: delete leading zero
	degree=$(echo $dataset | cut -d',' -f$coord | sed -e 's/\.//g' -e 's/.\{6\}$//' -e 's/^0*//')
	# get direction from $dataset
	# cut: get direction letter from $dataset
	# sed1: replace W with negative sign
	# sed2: delete E
	# sed3: replace S with negative sign
	# sed4: delete N
	dir=$(echo $dataset | cut -d',' -f$direction | sed -e 's/W/-/g' -e 's/E//g' -e 's/S/-/g' -e 's/N//g')
	
	# return coordinate string and cut to six numbers after the decimal sign
	echo "$dir$degree."$(echo $minutes_calc | sed -e 's/.*\(.\{6\}\)$/\1/')
}

# update coordinates in Freifunk Franken Monitoring
update_FFM() {
	local lat=$1
	local lon=$2

	# compare old and new coordinates shorten by last three numbers
	if [ $(echo $lat | sed -e 's/.\{3\}$//') != $(echo $lat_old | sed -e 's/.\{3\}$//') ] || [ $(echo $lon | sed -e 's/.\{3\}$//') != $(echo $lon_old | sed -e 's/.\{3\}$//') ]; then
		# write new coordinates to UCI and commit
		uci -q set "fff.system.latitude=$lat"
		uci -q set "fff.system.longitude=$lon"
		uci -q commit
		# set old coordinates for further checks
		lat_old="$lat"
		lon_old="$lon"
		echo "Updated Coordinates: $lat $lon"
	fi
}

# parse NMEA datasets from Target
nmea_parse() {
	local dataset=$1

	case "$dataset" in
	\$GPGGA*)
		update_FFM $(DecMin_conv "$dataset" "3" "4") $(DecMin_conv "$dataset" "5" "6")
	;;
	\$GNGGA*)
		update_FFM $(DecMin_conv "$dataset" "3" "4") $(DecMin_conv "$dataset" "5" "6")
	;;
	esac
}

case "$1" in
	USB*)
		cat -v $2 | while read LINE; do nmea_parse "$LINE"; done
	;;
	NET*)
		nc $2 $3 | while read LINE; do nmea_parse "$LINE"; done
	;;
	*)
		echo "Usage:"
		echo "./nmea.sh USB PATH_TO_DEVICE"
		echo "./nmea.sh NET IP_ADDRESS PORT"
	;;
esac
