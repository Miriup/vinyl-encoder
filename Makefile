
#
# Staging directories
#
STAGE0=0-Vanilla
STAGE1=1-noisereduced
STAGE2=2-sliced
STAGE3=3-encoded
STAGE4=4-tagged

#
# Vinyl encoder tools
#
VE_SLICE=~/src/vinyl-encoder/ve-slice
VE_ENCODE=~/src/vinyl-encoder/ve-encode

#
# Config
#
COMPRESSED_FORMATS="MP3-128-CBR MP3-240-VBR FLAC-24"
#
# Vanilla
#
INPUT_FILES=$(shell echo $(STAGE0)/*.WAV)
DIGITISED_CSV=$(STAGE0)/digitised.csv

#
# Stage 1
#
$(STAGE1)/%.soxnoiseprof: $(STAGE0)/%.WAV
	sox $< -n trim =0 =1 noiseprof $@

$(STAGE1)/%.WAV: $(STAGE0)/%.WAV $(STAGE1)/%.soxnoiseprof
	sox $< $@ noisered $(STAGE1)/$*.soxnoiseprof 1

STAGE1_FILES=$(shell echo $(INPUT_FILES) | sed 's!$(STAGE0)!$(STAGE1)!g')

prep-stage1:
	test -d $(STAGE1) || mkdir $(STAGE1)

stage1: $(STAGE1_FILES)

#
# discogs JSON
#
# for FILE in *.WAV; do grep "${FILE%.WAV}" ../../AJ/digitised.csv; done | while read TIME DISCOGS SIDE REST; do echo $DISCOGS; done | sort -n | uniq | while read DISCOGS; do echo curl -o $DISCOGS.json https://api.discogs.com/releases/$DISCOGS; done

$(STAGE1)/%-discogs-ids.csv: $(STAGE0)/%.WAV
	grep "$*" $(DIGITISED_CSV) > $@

STAGE2_CSV_FILES=$(shell echo $(STAGE1_FILES) | sed 's!.WAV!-discogs-ids.csv!g')
STAGE2_JSON_FILES=$(shell cat $(STAGE1)/*.csv | while read TIME DISCOGS SIDE REST; do echo $(STAGE1)/$$DISCOGS.json; done | sort -n | uniq)

$(STAGE1)/%.json:
	curl -o $(STAGE1)/$$DISCOGS.json https://api.discogs.com/releases/$$DISCOGS

json-files: $(STAGE2_JSON_FILES)

#stage2: $(STAGE2_CSV_FILES) $(STAGE2_JSON_FILES)

#
# audacity label files
#
$(STAGE1)/%.txt: $(STAGE1)/%.WAV $(STAGE1)/%-discogs-ids.csv
	set -x; while read TAG DISCOGS SIDE REST; do ~/src/vinyl-encoder/ve-silencedetect --noise_db=-100 --silence_length=3 $(STAGE1)/$${DISCOGS}.json $< $${SIDE} $@ 2> $(STAGE1)/$*.log; done < $(STAGE1)/$*-discogs-ids.csv; set +x

STAGE2_TXT_FILES=$(shell echo ${STAGE1}/*.csv | sed 's!-discogs-ids.csv!.txt!g')

txt-files: $(STAGE2_TXT_FILES)

.PRECIOUS: $(STAGE1)/%.soxnoiseprof $(STAGE1_FILES) $(STAGE2)/%.json $(STAGE1)/%.txt
#
# Stage 2: slicing
#
stage2:
	set -x; cat $(STAGE1)/*.csv | while read TAG DISCOGS SIDE REST; do echo $$TAG $$DISCOGS $$SIDE; test -e "$(STAGE0)/$$TAG.WAV" -a -e "$(STAGE1)/$$TAG.txt" && $(MAKE) TAG=$$TAG DISCOGS=$$DISCOGS SIDE=$$SIDE $(STAGE2)/$$DISCOGS/$$DISCOGS-$$SIDE-1.WAV; done

$(STAGE2)/$(DISCOGS)/$(DISCOGS)-$(SIDE)-1.WAV: $(STAGE0)/$(TAG).WAV $(STAGE1)/$(TAG)-discogs-ids.csv $(STAGE1)/$(TAG).txt
	$(VE_SLICE) --output-dir $(STAGE2) --discogs-csv $(STAGE1)/$(TAG)-discogs-ids.csv $(STAGE0)/$(TAG).WAV $(STAGE1)/$(TAG).txt

#
# Stage 3: encoding
#
# Note: Variable name DISCOGS_RELEASE instead of DISCOGS below to avoid triggering stage2 rules. Ugly trick, I know.
#
stage3:
	#set -x; for COMPRESSED_FORMAT in "$(COMPRESSED_FORMATS)"; do find $(STAGE2) -name '*-1.wav' | sed 's!^$(STAGE2)!$(STAGE3)/$(COMPRESSED_FORMAT)!;s!-1.wav!1.mp3!' | xargs $(MAKE) COMPRESSED_FORMAT="$$COMPRESSED_FORMAT"; done
	set -x; \
	for COMPRESSED_FORMAT in "$(COMPRESSED_FORMATS)"; do \
		find $(STAGE2) -name '*.wav' | while read IN_FILE; do \
			IFS='-.' read DISCOGS_RELEASE DISCOGS_SIDE TRACK_NO EXTENSION <<< $$(basename $$IN_FILE); \
			[[ $${COMPRESSED_FORMAT} == FLAC* ]] && EXT=flac || EXT=mp3; \
			$(MAKE) DISCOGS_RELEASE=$$DISCOGS_RELEASE SIDE=$$DISCOGS_SIDE NR=$$TRACK_NO COMPRESSED_FORMAT="$$COMPRESSED_FORMAT" $(STAGE3)/$$COMPRESSED_FORMAT/$$DISCOGS_RELEASE/$${DISCOGS_SIDE}$${TRACK_NO}{.$${EXT},-spectrogram.png,.noiseprofile} ; \
			done \
		done

$(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/$(SIDE)$(NR).mp3: $(STAGE2)/$(DISCOGS_RELEASE)/$(DISCOGS_RELEASE)-$(SIDE)-$(NR).wav
	$(VE_ENCODE) "$<" --output-dir $(STAGE3) --quiet --compressed-formats "$(COMPRESSED_FORMAT)"

$(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/$(SIDE)$(NR)-spectrogram.png: $(STAGE2)/$(DISCOGS_RELEASE)/$(DISCOGS_RELEASE)-$(SIDE)-$(NR)-spectrogram.png
	ln $< $@

$(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/$(SIDE)$(NR).noiseprofile: $(STAGE2)/$(DISCOGS_RELEASE)/$(DISCOGS_RELEASE)-$(SIDE)-$(NR).noiseprofile
	ln $< $@

#
# Stage 4: Tagging
#
# discogstagger leaves a .done file in the source directory and we use it to track stage completion per record
#
stage4:
	#set -x; for COMPRESSED_FORMAT in "$(COMPRESSED_FORMATS)"; do find $(STAGE2) -name '*-1.wav' | sed 's!^$(STAGE2)!$(STAGE3)/$(COMPRESSED_FORMAT)!;s!-1.wav!1.mp3!' | xargs $(MAKE) COMPRESSED_FORMAT="$$COMPRESSED_FORMAT"; done
	set -x; \
	for COMPRESSED_FORMAT in "$(COMPRESSED_FORMATS)"; do \
		find $(STAGE2) -name '*-1.wav' | while read IN_FILE; do \
			IFS='-.' read DISCOGS_RELEASE DISCOGS_SIDE TRACK_NO EXTENSION <<< $$(basename $$IN_FILE); \
			$(MAKE) DISCOGS_RELEASE=$$DISCOGS_RELEASE COMPRESSED_FORMAT="$$COMPRESSED_FORMAT" $(STAGE3)/$$COMPRESSED_FORMAT/$$DISCOGS_RELEASE/.done; \
			done \
		done

$(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/.done: $(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/$(DISCOGS_RELEASE).json
	#python ~/src/discogstagger3/discogstagger2.py -s $< -d $@ -r $(DISCOGS_RELEASE) -c discogstagger3.conf
	python3 ~/src/discogstagger3/discogstagger2.py -r $(DISCOGS_RELEASE) -d $(STAGE4)/$(COMPRESSED_FORMAT) -s $$(dirname $<) -c ~/src/vinyl-encoder/discogstagger3.conf

$(STAGE3)/$(COMPRESSED_FORMAT)/$(DISCOGS_RELEASE)/%.json: $(STAGE1)/%.json
	ln $< $@
