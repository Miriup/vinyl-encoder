
Download record JSON
--------------------

```
curl -o 2/MP3-128-CBR/60643/60643.json https://api.discogs.com/releases/60643
```

Check tags with FFMPEG
----------------------

```
ffmpeg -i ${file} -f ffmetadata
```

Beautify JSON
-------------

```
python -m json.tool ${file}.json
```

```
set -x; (while read TAG DISCOGS SIDE REST; do echo $TAG/$DISCOGS/$SIDE; test -e ${TAG}.txt || (test -e ${TAG}.WAV -a -e ../../AJ3/${DISCOGS}.json && ~/src/vinyl-encoder/ve-silencedetect ../../AJ3/${DISCOGS}.json ${TAG}.WAV ${SIDE} ${TAG}.txt 2> ${TAG}.log ); done) < ../../AJ/digitised.csv; set +x
```

Behaviour of discogstagger upon encountering missing fles
----------------------------------------------------------

```
2021-11-06 17:21:39,297 - discogstagger2 - INFO - Found 1 audio source directories to process
Visit this URL in your browser: https://www.discogs.com/oauth/authorize?oauth_token=vuBqKKsITKnEBBTyNQMLfoTREsycrSPdJLtqZXIU
Enter the PIN you got from the above url: mqOsOaQULN
2021-11-06 17:27:00,493 - discogstagger2 - INFO - start tagging
2021-11-06 17:27:00,506 - discogstagger2 - INFO - Found release ID: 60643 for source dir: /home/dirk/Music/Temp/2/MP3-128-CBR/60643/
2021-11-06 17:27:00,508 - discogstagger2 - INFO - Using destination directory: /home/dirk/Music/Temp/3/MP3-128-CBR
[{'name': 'Vinyl', 'qty': '2', 'descriptions': ['12"', '33 ⅓ RPM', 'Album']}]
2021-11-06 17:27:00,552 - discogsalbum - INFO - determined 2 no of discs total
2021-11-06 17:27:00,555 - discogstagger2 - INFO - Tagging album "Hardfloor - All Targets Down"
2021-11-06 17:27:00,583 - taggerutils - ERROR - not matching number of files....
2021-11-06 17:27:00,942 - discogstagger2 - ERROR - Error during tagging (60643), /home/dirk/Music/Temp/2/MP3-128-CBR/60643/: 'MediaFile' object has no attribute 'TLEN'
2021-11-06 17:27:00,943 - discogstagger2 - INFO - Tagging complete.
2021-11-06 17:27:00,944 - discogstagger2 - INFO - converted successful: 0
2021-11-06 17:27:00,945 - discogstagger2 - INFO - converted with Errors 1
2021-11-06 17:27:00,945 - discogstagger2 - INFO - releases touched: 1
2021-11-06 17:27:00,946 - discogstagger2 - ERROR - The following discs could not get converted.
2021-11-06 17:27:00,947 - discogstagger2 - ERROR - Error during tagging (60643), /home/dirk/Music/Temp/2/MP3-128-CBR/60643/: 'MediaFile' object has no attribute 'TLEN'
```
