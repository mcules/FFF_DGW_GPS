#####
# Freifunk GPS Coordinates Updater
# Usage:
# ./nmea.sh USB PATH_TO_DEVICE
# ./nmea.sh NET IP_ADDRESS PORT
#####

lat_old=0
lon_old=0

DezMin_Calc() {
	local dataset=$1
	local coord=$2
	local direction=$3

	minutes=$(echo $dataset | cut -d',' -f$coord | sed -e 's/\.//g' -e 's/.*\(.\{7\}\)$/\1/')
	minutes_calc=$((`expr $(echo $minutes) + 0` * 1000 / 600))
	degree=$(echo $dataset | cut -d',' -f$coord | sed -e 's/\.//g' -e 's/.\{7\}$//' -e 's/^0*//')
	dir=$(echo $dataset | cut -d',' -f$direction | sed -e 's/W/-/g' -e 's/E//g' -e 's/S/-/g' -e 's/N//g')

	echo "$dir$degree."$(echo $minutes_calc | sed -e 's/.*\(.\{6\}\)$/\1/')
}

DezMin_parse() {
	local dataset=$1

	update_FFM $(DezMin_Calc "$dataset" "3" "4") $(DezMin_Calc "$dataset" "5" "6")
}

update_FFM() {
	local lat=$1
	local lon=$2

	if [ $(echo $lat | sed -e 's/.\{3\}$//') != $(echo $lat_old | sed -e 's/.\{3\}$//') ] || [ $(echo $lon | sed -e 's/.\{3\}$//') != $(echo $lon_old | sed -e 's/.\{3\}$//') ]; then
		uci -q set "fff.system.latitude=$lat"
		uci -q set "fff.system.longitude=$lon"
		uci -q commit
		lat_old="$lat"
		lon_old="$lon"
		echo "Updated Coordinates: $lat $lon"
	fi
}

nmea_parse() {
	local dataset=$1
	update=0

	case "$dataset" in
	\$GPGGA*)
		DezMin_parse "$dataset"
	;;
	\$GNGGA*)
		DezMin_parse "$dataset"
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
