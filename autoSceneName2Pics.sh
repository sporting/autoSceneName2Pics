#!/bin/bash
googleApiKey=YOUR_GOOGLE_API_KEY
googlePlaceUrl="https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latlng&types=establishment&rankby=distance&language=en_US&key=$googleApiKey"


# check input parameters exists
if [ -z "$1" ]; then
  printf 'please enter 1 input arguments: pic folder';
  exit;
fi

#second argument means backup pictures or not (default 1:yes)
if [ -z "$2" ]; then
  backupFlag="1"
else
  backupFlag="$2"
fi


#backupFlag="$2"
#if [ $backupFlag -ne "0" ]; then
#  backupFlag="1"
#fi

searchFolder=$1
jpgList=$searchFolder'/jpg.lst'
strucList=$searchFolder'/struc.lst'
strucList2=$searchFolder'/struc2.lst'
mvList=$searchFolder'/mv.lst'
backupFolder=$searchFolder'/backup'

rm $jpgList
rm $strucList
rm $strucList2
rm $mvList

find $searchFolder -maxdepth 1 -type f -name '*.JPG' >> $jpgList
find $searchFolder -maxdepth 1 -type f -name '*.jpg' >> $jpgList

#extract jpg filename to fullfilename@filename@datetime
cat $jpgList | while read x;do echo $x"@""${x##*/}""@"$(jhead $x \
 |grep  'GPS Latitude'\
 | cut -c -50\
 |awk -F ':' '{print $2$3$4$5}'\
 |tr -d [:blank:]\
 |sed 's/^\([N|S]\)\(.*\)d\(.*\)m\(.*\)s/\1 \2 \3 \4/'\
 |awk -F ' ' '{if ($1=="N") {printf("%.20f", $2+$3/60+$4/3600)} else {printf("%.20f", -1*($2+$3/60+$4/3600))}}')"@"$(jhead $x |grep  'GPS Longitude'\
 |cut -c -50 \
 |awk -F ':' '{print $2$3$4$5}'\
 |tr -d [:blank:]\
 |sed 's/^\([E|W]\)\(.*\)d\(.*\)m\(.*\)s/\1 \2 \3 \4/'\
 |awk -F ' ' '{if ($1=="E") {printf("%.20f", $2+$3/60+$4/3600)} else {printf("%.20f", -1*($2+$3/60+$4/3600))}}') >> $strucList; done

# filter invalid gps location
awk -F '@' '{if ($3!=0) {print $0}}' $strucList > $strucList2


if [ $backupFlag -eq "1" ]; then
  #clone jpg files to backup folder
  mkdir $backupFolder

  while IFS='' read -r line || [[ -n "$line" ]]; do
    filename=$(echo $line|awk -F '@' '{print $2}')
    cp $filename $backupFolder"/"$filename
  done < $strucList2
fi


while IFS='' read -r line || [[ -n "$line" ]]; do
  filename=$(echo $line|awk -F '@' '{print $2}')
  lat=$(echo $line|awk -F '@' '{print $3}')
  lng=$(echo $line|awk -F '@' '{print $4}')
  latlng=$lat,$lng

  ext="${filename##*.}"
  file="${filename%.*}"


  scene=$(wget -qO- $googlePlaceUrl |./JSON.sh|grep '\["results",0,"name"\]'|awk -F ' ' '{print $2}'|tr -d "\"")

  if [ ! -z "$scene " ]; then
    newfilename=$scene"_"$file.$ext
  
    echo "mv "$searchFolder/$filename" $searchFolder/$newfilename" >> $mvList
  fi
done < $strucList2

cat $mvList | while read x; do $x; done

