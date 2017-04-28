#!/bin/bash
googleApiKey=YOUR_GOOGLE_API_KEY
googlePlaceUrl="https://maps.googleapis.com/maps/api/place/nearbysearch/json?types=establishment&rankby=distance&language=en_US&key=$googleApiKey&location="

# check input parameters exists
if [ -z "$1" ]; then
  echo 'please enter 1 input arguments: pic folder';
  exit;
fi
searchFolder=$1


while IFS= read -r -d $'\0' Picture; do
	Lat=`jhead ${Picture}|grep 'GPS Latitude'|cut -c -50|awk -F ':' '{print $2$3$4$5}'|tr -d [:blank:] |sed 's/^\([N|S]\)\(.*\)d\(.*\)m\(.*\)s/\1 \2 \3 \4/'|awk -F ' ' '{if ($1=="N") {printf("%.20f", $2+$3/60+$4/3600)} else {printf("%.20f", -1*($2+$3/60+$4/3600))}}'`
	Lon=`jhead ${Picture}|grep 'GPS Longitude'|cut -c -50|awk -F ':' '{print $2$3$4$5}'|tr -d [:blank:] |sed 's/^\([E|W]\)\(.*\)d\(.*\)m\(.*\)s/\1 \2 \3 \4/'|awk -F ' ' '{if ($1=="E") {printf("%.20f", $2+$3/60+$4/3600)} else {printf("%.20f", -1*($2+$3/60+$4/3600))}}'`
	Scene=`wget -qO- ${googlePlaceUrl}${Lat},${Lon}|jq .results[].name|head -1|sed 's/"//g;s/\ /./g'`
	DateTime=`jhead ${Picture}|grep 'Date/Time'|awk '{print$3""$4}'|sed 's/://g'`
	if [ ! -z "$Scene" -a "$Scene" != " " ]; then
		mv ${Picture} ${searchFolder}/${DateTime}.${Scene}.jpeg
	fi
done < <(find ${searchFolder} -maxdepth 1 -type f -iname '*.jpg' -print0)
