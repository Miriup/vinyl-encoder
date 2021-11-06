
#
# Staging directories
#
STAGE0=0-Vanilla
STAGE1=1-noisereduced
#STAGE2=2-json

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

stage2: $(STAGE2_CSV_FILES) $(STAGE2_JSON_FILES)

#
# audacity label files
#
$(STAGE1)/%.txt: $(STAGE1)/%.WAV $(STAGE1)/%-discogs-ids.csv
	set -x; while read TAG DISCOGS SIDE REST; do ~/src/vinyl-encoder/ve-silencedetect --noise_db=-100 --silence_length=3 $(STAGE1)/$${DISCOGS}.json $< $${SIDE} $@ 2> $(STAGE1)/$*.log; done < $(STAGE1)/$*-discogs-ids.csv; set +x

STAGE2_TXT_FILES=$(shell echo ${STAGE1}/*.csv | sed 's!-discogs-ids.csv!.txt!g')

txt-files: $(STAGE2_TXT_FILES)

.PRECIOUS: $(STAGE1)/%.soxnoiseprof $(STAGE1_FILES) $(STAGE2)/%.json $(STAGE1)/%.txt
