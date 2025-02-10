#!/bin/bash

outfile=$1
filename=$2
ml apps/samtools

f="${filename%%.*}"
sample=${f#"${f%/*}/"}

human=$(samtools view -c -F 260 ${filename}_human_allReads.bam)
mouse=$(samtools view -c -F 260 ${filename}_mouse_allReads.bam)

echo "${sample} ${human} ${mouse}" >> $outfile
