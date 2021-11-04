
DIR_TEMP_SILENCEDETECT=Temp/0
DIR_SOURCE_WAVE=AJ3

all: $(shell ls $(DIR_SOURCE_WAVE)/*.WAV|sed 's|$(DIR_SOURCE_WAVE)|$(DIR_TEMP_SILENCEDETECT)/0|;s|WAV|wav|')

.PRECIOUS: $(DIR_TEMP_SILENCEDETECT)/%.noiseprofile

$(DIR_TEMP_SILENCEDETECT)/%.noiseprofile: $(DIR_SOURCE_WAVE)/%.WAV
	sox $< -n trim =0 =3 noiseprof $@

$(DIR_TEMP_SILENCEDETECT)/%.wav: $(DIR_TEMP_SILENCEDETECT)/%.noiseprofile $(DIR_SOURCE_WAVE)/%.WAV
	sox $(DIR_SOURCE_WAVE)/$*.WAV $@ noisered $< 1

	#ffmpeg -i $< -af silencedetect=noise=-100dB:d=3 -f null /dev/null
