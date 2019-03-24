lat_old=0
lon_old=0

DezMin_parse() {
	local dataset=$1
	lon_minutes=$(echo $dataset | cut -d',' -f5 | sed 's/\.//g' | sed 's/.*\(.\{6\}\)$/\1/')
        lat_minutes=$(echo $dataset | cut -d',' -f3 | sed 's/\.//g' | sed 's/.*\(.\{6\}\)$/\1/')
        lon_minutes_calc=$((`expr $(echo $lon_minutes) + 0` * 1000 / 60 / 10))
        lat_minutes_calc=$((`expr $(echo $lat_minutes) + 0` * 1000 / 60 / 10))
        lon_degree=$(echo $dataset | cut -d',' -f5 | sed 's/\.//g' | sed -e 's/.\{6\}$//')
        lat_degree=$(echo $dataset | cut -d',' -f3 | sed 's/\.//g' | sed -e 's/.\{6\}$//')
        lon_dir=$(echo $dataset | cut -d',' -f6 | sed 's/W/-/g' | sed 's/E//g')
        lat_dir=$(echo $dataset | cut -d',' -f4 | sed 's/S/-/g' | sed 's/N//g')

        lon=$(echo "$lon_dir""$lon_degree"."$lon_minutes_calc")
        lat=$(echo "$lat_dir""$lat_degree"."$lat_minutes_calc")

        echo "Coordinates: $lat $lon"

        if [ "$lat" != "$lat_old" ] || [ "$lon" != "$lon_old" ]; then
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
	esac
}

nc 10.10.31.57 7000 | while read LINE; do nmea_parse "$LINE"; done
