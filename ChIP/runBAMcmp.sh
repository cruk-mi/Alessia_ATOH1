#!/bin/bash

#----------------------------------------
# Sam Humphrey, Febuary 2020
# Script to run bamcmp over a directory of bamfiles
# 
# The script *runBAMcmp.sh* requires two directories of *.bam* files: one aligned to human, one aligned to mouse, both with exactly the same file names.
# The script will sort, run bamcmp, re-sort and merge the *.bam* files and output into a new 'outputDir'directory
# both human and mouse *.bam* files have been kept individually.
#
# An accompanying script "countBAMsizes.sh" is used to count the extent of mouse contamination removal 
#
#----------------------------------------

dataDir="/data/cep/shumphrey/AlessiasData/"
outputDir="${dataDir}BAMs_ChIP_ASfiltered/"

workingDir="/scratch/wsspaces/shumphrey-AlessiasData-0/"
bamHumanDir="${dataDir}NFpipeline_ChIP/results_human/bwa/mergedLibrary/"
bamMouseDir="${dataDir}NFpipeline_ChIP/results_mouse/bwa/mergedLibrary/"

#bamHumanDir="${dataDir}NFpipeline_RNAseq/results_human/star_salmon/"
#bamMouseDir="${dataDir}NFpipeline_RNAseq/results_mouse/star_salmon/"

countBAMCode="/home/shumphrey/PreClinProjects/AlessiaChipData/alessias-chip-analysis/ChIP/countBAMsizes.sh"
count_outfile="${dataDir}QC/filteredBAMcounts_ChIP.txt"

tmpDir="${workingDir}tmp/"

bamList="${workingDir}bamList.txt"

if [ -d "$outputDir" ]; then rm -r "$outputDir" ; fi
if [ -f "$bamList" ]; then rm "$bamList"; fi
if [ -f "$count_outfile" ]; then rm "$count_outfile"; fi

mkdir $outputDir
mkdir -p $tmpDir
mkdir -p ${workingDir}outfiles/
printf '%s\n' $bamHumanDir*sorted.bam > $bamList

while IFS= read -r line || [ -n "$line" ]; do 
    filename=${line#"${line%/*}/"}
    sample="${filename%%.*}"
    echo "${sample} -*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-"

	qsub <<-_EOF 
		#PBS -N runBAMcmp_${sample}
		#PBS -l nodes=1:ppn=16
		#PBS -l walltime=00:02:00:00 
		#PBS -j oe
		#PBS -o ${workingDir}outfiles/runBAMcmp_as_RNAseq_${sample}.out

		ml apps/bamcmp apps/samtools
		cd ${workingDir}

		samtools sort -@ 16 -n -o ${tmpDir}${sample}_human.sorted.bam ${bamHumanDir}${filename}
		samtools sort -@ 16 -n -o ${tmpDir}${sample}_mouse.sorted.bam ${bamMouseDir}${filename}

	    bamcmp  -s as \
		        -t 16 \
		        -1 ${tmpDir}${sample}_human.sorted.bam \
		        -2 ${tmpDir}${sample}_mouse.sorted.bam \
		        -a ${tmpDir}${sample}_human_only.bam \
		        -A ${tmpDir}${sample}_human_better.bam \
		        -b ${tmpDir}${sample}_mouse_only.bam \
		        -B ${tmpDir}${sample}_mouse_better.bam

		# Sort the sam files into genomic coordinates and convert to bams
		samtools sort -@ 16 -o ${tmpDir}${sample}_human_only.sorted.bam ${tmpDir}${sample}_human_only.bam
		samtools sort -@ 16 -o ${tmpDir}${sample}_human_better.sorted.bam ${tmpDir}${sample}_human_better.bam
		samtools sort -@ 16 -o ${tmpDir}${sample}_mouse_only.sorted.bam ${tmpDir}${sample}_mouse_only.bam
		samtools sort -@ 16 -o ${tmpDir}${sample}_mouse_better.sorted.bam ${tmpDir}${sample}_mouse_better.bam

		# merge the _only and _better files together
		samtools merge -@ 16 ${outputDir}${sample}_human_allReads.bam ${tmpDir}${sample}_human_only.sorted.bam ${tmpDir}${sample}_human_better.sorted.bam
    	samtools merge -@ 16 ${outputDir}${sample}_mouse_allReads.bam ${tmpDir}${sample}_mouse_only.sorted.bam ${tmpDir}${sample}_mouse_better.sorted.bam

		sh ${countBAMCode} $count_outfile ${outputDir}${sample}
		rm ${tmpDir}${sample}*

	_EOF

done < "${bamList}"


