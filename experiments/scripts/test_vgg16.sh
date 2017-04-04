#!/bin/bash

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
DATASET=$2

array=( $@ )
len=${#array[@]}
EXTRA_ARGS=${array[@]:2:$len}
EXTRA_ARGS_SLUG=${EXTRA_ARGS// /_}

case ${DATASET} in
  pascal_voc)
    TRAIN_IMDB="voc_2007_trainval"
    TEST_IMDB="voc_2007_test"
    ITERS=70000
    ANCHORS="[8,16,32]"
    ;;
  pascal_voc_0712)
    TRAIN_IMDB="voc_2007_trainval+voc_2012_trainval"
    TEST_IMDB="voc_2007_test"
    ITERS=110000
    ANCHORS="[8,16,32]"
    ;;
  coco)
    TRAIN_IMDB="coco_2014_train+coco_2014_valminusminival"
    TEST_IMDB="coco_2014_minival"
    ITERS=490000
    ANCHORS="[4,8,16,32]"
    ;;
  *)
    echo "No dataset given"
    exit
    ;;
esac

LOG="experiments/logs/test_vgg16_depre_${TRAIN_IMDB}_${EXTRA_ARGS_SLUG}.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

set +x
if [[ ! -z  ${EXTRA_ARGS_SLUG}  ]]; then
  NET_FINAL=output/vgg16_depre/${TRAIN_IMDB}/${EXTRA_ARGS_SLUG}/vgg16_faster_rcnn_iter_${ITERS}.ckpt
else
  NET_FINAL=output/vgg16_depre/${TRAIN_IMDB}/default/vgg16_faster_rcnn_iter_${ITERS}.ckpt
fi
set -x

if [[ ! -z  ${EXTRA_ARGS_SLUG}  ]]; then
  CUDA_VISIBLE_DEVICES=${GPU_ID} time python ./tools/test_vgg16_net.py \
    --imdb ${TEST_IMDB} \
    --weight data/imagenet_weights/vgg16.weights \
    --model ${NET_FINAL} \
    --cfg experiments/cfgs/vgg16_depre.yml \
    --tag ${EXTRA_ARGS_SLUG} \
    --set ANCHOR_SCALES ${ANCHORS} ${EXTRA_ARGS}
else
  CUDA_VISIBLE_DEVICES=${GPU_ID} time python ./tools/test_vgg16_net.py \
    --imdb ${TEST_IMDB} \
    --weight data/imagenet_weights/vgg16.weights \
    --model ${NET_FINAL} \
    --cfg experiments/cfgs/vgg16_depre.yml \
    --set ANCHOR_SCALES ${ANCHORS} ${EXTRA_ARGS}
fi

