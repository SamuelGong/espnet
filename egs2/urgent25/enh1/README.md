# Recipe for the Interspeech 2025 URGENT challenge
Official data preparation scripts for the [URGENT 2025 Challenge](https://urgent-challenge.github.io/urgent2025/)

## Install ESPnet from source
For more details on installing ESPnet, please refer to https://espnet.github.io/espnet/installation.html.
```sh
# Clone espnet code.
git clone -b urgent2025 https://github.com/kohei0209/espnet

# Checkout the commit where we tested our code.
cd ./espnet/tools

# Set up python environment.
# ./setup_miniforge.sh [output-dir-name|default=venv] [conda-env-name|default=root] [python-version|default=none]
./setup_miniforge.sh miniconda espnet_urgent2025 3.10.8

# Install espnet from source with other dependencies.
# We used torch 2.3.1 and cuda 12.1.
make TH_VERSION=2.3.1 CUDA_VERSION=12.1
```

## Instructions

0. Data preparation
    
    Please do data preparation with [https://github.com/urgent-challenge/urgent2025_challenge](https://github.com/urgent-challenge/urgent2025_challenge). 

1. Move to the recipe directory:
    ```sh
    # Assuming you are now at ./espnet 
    cd egs2/urgent25/enh1
    ```

2. Make symbolic links
    ```sh
    # link to the data preparation directory
    ln -s /path/to/urgent2025_challenge ./

    # link to the datasets
    # we assume that each .scp file generated in data preparation stage points ./${dataset}/...
    # if you have changed paths in .scp files manually, please change the following command accordingly. 
    for dataset in commonvoice dns5_fullband ears fma fsd50k libritts mls_segments vctk wham_noise_48k wsj simulation_train simulation_validation; do
        ln -s "./urgent2025_challenge/${dataset}" ./
    done
    ```

3. Prepare data files
    ```sh
    cp -r ./urgent2025_challenge/data ./data
    mkdir -p ./dump && cp -r ./data ./dump/raw

    # remove sampling rate information
    mv dump/raw/noise_train.scp dump/raw/noise_train.scp.bak
    awk '{print $1" "$3}' dump/raw/noise_train.scp.bak > dump/raw/noise_train.scp

    mv dump/raw/rir_train.scp dump/raw/rir_train.scp.bak
    awk '{print $1" "$3}' dump/raw/rir_train.scp.bak > dump/raw/rir_train.scp

    # generate `./exp/enh_stats_16k` directory including `speech_mix_shape` and `speech_ref1_shape`
    # it takes ~2h with 8 jobs (--nj 8)
    ./run.sh --stage 5 --stop_stage 5 --nj 8
    ```

    A few samples may sometimes be broken for some reason, resulting in shape of 0 in `speech_mix_shape`.
    The following command removes such samples.
    ```sh
    . ./local/remove_broken_files.sh
    ```



4. Training and inference
    
    Training can be run as follows:
    ```sh
    # training
    ./run.sh --stage 6 --stop-stage 6 --ngpu <number-of-gpus> --enh_config conf/tuning/<your-favorite-config.yaml>
    ```

    If you would like to use a pre-trained model, please add `--init_param` argument.
    For instance, if you use the pre-trained model from the 1st challenge provided [here](https://huggingface.co/wyz/tfgridnet_for_urgent24/tree/main/exp/enh_train_enh_tfgridnet_raw), after downloading the model, do as follows.
    ```sh
    # training
    ./run.sh --stage 6 --stop-stage 6 --ngpu <number-of-gpus> --enh_config conf/tuning/<your-favorite-config.yaml> --init_param "exp/enh_train_enh_tfgridnet_raw_1stchallenge/21epoch.pth"
    ```

    After training the model, inference and scoring can be run as follows.

    Note: `scoring.sh` activates `urgent2025` environment made in data preparation stage by `conda activate urgent2025`. 
    If you do not use miniconda or use different environment name, please modify `path2.sh` accordingly.
    ```sh
    # inference and scoring
    # <exp directory> is like ./exp/enh_train_enh_bsrnn_medium_noncausal_raw
    # to evaluate noisy speech, please change `eval_noisy_data=false` to `eval_noisy_data=true` in `scoring.sh`.
    . ./scoring.sh <path-to-exp-directory>
    ```

    Scores are saved in `<path-to-exp-directory>/{scoring*}` directories.