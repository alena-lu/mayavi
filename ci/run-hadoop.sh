#!/bin/sh
set -eu
: "${BUILD_NUMBER:?Jenkins BUILD_NUMBER required}"
: "${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT for the gcloud agent}"
ARCHIVE="mayavi-repo.tar"

gcloud container clusters get-credentials hadoop-cluster \
  --zone us-central1-a --project "$GOOGLE_CLOUD_PROJECT"
POD=hadoop-master-0
REMOTE="/tmp/mayavi-build-${BUILD_NUMBER}"
HDFS_INPUT="/mayavi/build-${BUILD_NUMBER}/input"
HDFS_OUTPUT="/mayavi/build-${BUILD_NUMBER}/output"

# copy git revision to the namenode container
kubectl exec -n hadoop "$POD" -c namenode -- mkdir -p "$REMOTE"
kubectl cp "$ARCHIVE" "hadoop/$POD:$REMOTE/repo.tar" -c namenode

# job to actually count lines
# AI citation, used AI to help me find the following reference docs
# https://hadoop.apache.org/docs/r3.3.6/hadoop-streaming/HadoopStreaming.html 
# https://hadoop.apache.org/docs/r3.3.6/hadoop-project-dist/hadoop-common/FileSystemShell.html 
kubectl exec -n hadoop "$POD" -c namenode -- sh -ec '
  remote="$1"
  input="$2" 
  output="$3"

  mkdir -p "$remote/repo"
  tar -xf "$remote/repo.tar" -C "$remote/repo"

  hdfs dfs -mkdir -p "$input"
  hdfs dfs -put "$remote/repo" "$input/"

  hadoop jar /opt/hadoop/share/hadoop/tools/lib/hadoop-streaming-3.3.6.jar \
    -D mapreduce.job.name=mayavi-lines \
    -D mapreduce.input.fileinputformat.input.dir.recursive=true \
    -files /opt/hadoop-jobs/mapper.sh,/opt/hadoop-jobs/reducer.sh \
    -input "$input" -output "$output" \
    -mapper "sh mapper.sh" -reducer "sh reducer.sh"

  echo "line counts:"
  hdfs dfs -cat "$output/part-*"
' sh "$REMOTE" "$HDFS_INPUT" "$HDFS_OUTPUT"
