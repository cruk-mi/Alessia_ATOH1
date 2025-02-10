#!/bin/bash

	#PBS -N rundeeptools_Alessia
	#PBS -l nodes=1:ppn=1
	#PBS -l walltime=00:24:00:00 
	#PBS -j oe
	#PBS -o /data/cep/shumphrey/AlessiasData/DeepTools/deepTools.out

#----------------------------------------
# Sam Humphrey, Febuary 2021
#
# Run deeptools
#----------------------------------------

dataDir="/data/cep/shumphrey/AlessiasData/"
outputDir="${dataDir}DeepTools/"
workingDir="/scratch/wsspaces/shumphrey-AlessiasData-0/"

cd ${workingDir}
ml apps/deeptools

mkdir -p $outputDir

computeMatrix reference-point --referencePoint TSS \
	-b 1000 -a 1000 \
	-R ${dataDir}results_human/bwa/mergedLibrary/macs/narrowPeak/consensus/SY0287/SY0287.consensus_peaks.bed \
	-S ${dataDir}results_human/bwa/mergedLibrary/bigwig/CDX19_ShRen_DOX_IP_SY0287_R1.bigWig \
	--skipZeros \
	-o ${outputDir}Matrix.tsb.gz \
	-p 6 \
	--outFileSortedRegions ${outputDir}sortedRegions.bed

plotProfile -m ${outputDir}Matrix.tsb.gz \
-out ${outputDir}TSS_Profile.png \
--perGroup \
--colors green purple \
--plotTitle "" \
--refPointLabel "TSS" \
-T "Read density" \
-z ""

plotHeatmap -m ${outputDir}Matrix.tsb.gz \
-out ${outputDir}TSS_Heatmap.png \
--colorMap RdBu \
--whatToShow 'heatmap and colorbar' \
--zMin -4 --zMax 4  
