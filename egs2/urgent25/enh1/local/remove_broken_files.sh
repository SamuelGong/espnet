#!/usr/bin/env bash

mv ./exp/enh_stats_16k ./exp/enh_stats_16k.bak && mkdir -p ./exp/enh_stats_16k/train && cp -r ./exp/enh_stats_16k.bak/valid ./exp/enh_stats_16k
mv ./dump/raw/speech_train_track1 ./dump/raw/speech_train_track1.bak && mkdir -p ./dump/raw/speech_train_track1

# remove broken files
awk '$2 != 0' ./exp/enh_stats_16k.bak/train/speech_mix_shape >  ./exp/enh_stats_16k/train/speech_mix_shape
awk '$2 != 0' ./exp/enh_stats_16k.bak/train/speech_ref1_shape > ./exp/enh_stats_16k/train/speech_ref1_shape

for file in spk1.scp text utt2category utt2fs utt2spk wav.scp; do
    ./utils/filter_scp.pl ./exp/enh_stats_16k/train/speech_mix_shape ./dump/raw/speech_train_track1.bak/${file} > ./dump/raw/speech_train_track1/${file}
done
utils/utt2spk_to_spk2utt.pl ./dump/raw/speech_train_track1/utt2spk > ./dump/raw/speech_train_track1/spk2utt