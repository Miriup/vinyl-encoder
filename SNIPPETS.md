
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
