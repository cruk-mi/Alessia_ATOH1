# Alessias ATOH1 (ChIP and RNAseq) analysis
## Alessia Catozzi & Sam Humphrey 
## Last updated 20/12/2022

# Overview

Alessia has performed a ChIP-seq experiment to test the ChIP protocol and an in-house ATOH1 antibody. This pilot study has no replicate data and so, any results identified must be formally validated either experimentally or though a further ChIP-seq run. RNA-seq has also been performed on the same samples and prelimianry analysis is ongoing.

Data: `/data/cep/shumphrey/AlessiasData`


## Upstream sample processing

### NGSCheckMate 

Script: *runCheckMateFASTQ.pbs*

Results are as expected for both ChIP and RNA-seq - all samples match CDX17/19 germline apart from the the 3 H146 cell lines in the ChIP experiment, which do not match any CDX germline.


### RNA-seq analysis


This sequencing run was joined with some samples from Sarahs FOXC2 KD experiments. The NGSCheckMate and `nf-core/rnaseq` pipeline was intially run across all samples, but it will be re-run seperately. Handily, the two experiments have different idnetifiers (Simpson and Frese), so Sarahs samples can be linked using Frese.

```
ln -s /mnt/gpfs2/facilities/sequencers/seq.08/210225_A01065_0041_AHY35TDRXX/Unaligned_CD29/*Frese*.fastq.gz .
```


Upstream analysis of the samples is currently being performed using the `nfcore/rnaseq v3.0` pipeline (https://nf-co.re/rnaseq/usage). There have been some bugs with the new pipeline, so running the pipeline is still ongoing.


```	
	source /data/cep/CDX_Model_NGS_Data/CDX_Model_Git_Repo/RNAseq_scripts/nextflowModules.sh

	nextflow run nf-core/rnaseq \
	--input /home/shumphrey/PreClinProjects/AlessiaChipData/alessias-chip-analysis/Data/DesignFile_RNAseq.csv \
	--genome GRCh38_v99 \
	-profile singularity \
	-c /data/cep/CDX_Model_NGS_Data/CDX_Model_Git_Repo/RNAseq_scripts/nextflow.config \
	-name AlessiaRNAseq_humanRun \
	-bg

	nextflow run nf-core/rnaseq \
	--input /home/shumphrey/PreClinProjects/AlessiaChipData/alessias-chip-analysis/Data/DesignFile_RNAseq.csv \
	 --genome GRCm38_v99 \
	 -profile singularity \
	 -c /data/cep/CDX_Model_NGS_Data/CDX_Model_Git_Repo/RNAseq_scripts/nextflow.config \
	 -name AlessiaSarahRNA_mouseRun \
	 -bg

```


### ChIP-seq analysis

The `nf-core/chipseq v1.2.1` has been used to call peaks in the ChIP experiment (https://nf-co.re/chipseq/1.2.1/usage). This pipeline has been run with both narrow and broad peak settings for calling peaks using MACS2. The results kept are those from the narrow-peak run, as well as the actual broad-peak calls (not all the data duplicated with the narrow peak run, bams etc...).

```
source /data/cep/CDX_Model_NGS_Data/CDX_Model_Git_Repo/RNAseq_data/nextflowModules.sh

nohup nextflow run nf-core/chipseq \
	--input /home/shumphrey/PreClinProjects/AlessiaChipData/alessias-chip-analysis/Data/DesignFile_ChIP.csv \
	-c /data/cep/CDX_Model_NGS_Data/CDX_Model_Git_Repo/RNAseq_data/nextflow.config \
	--genome GRCh38_v99 \
	-profile singularity \
	--macs_gsize 2.7e9 \
	--narrow_peak

```

## Mousefiltering

#### ChIP
Following alignment to both human and mouse genomes, reads were compared using bamcmp and reads better aligned to the mouse genome were removed (*runBAMcmp.sh*, which calls *countBAMsiszes.sh*). The percentage of reads kept after filtering was 97.9 (min), 98.2 (median), 98.9 (max). Since 2% of reads mapped to mouse better than human in all samples, including the human only H146 cell lines, we concluded that mouse filtering is unnecessary for this data.

#### RNA-seq
Ongoing


## Multi-QC report

Seemingly <0.1% of read pairs were removed by *cutadapt*, although it seems to remove 1 nt from a the end of the majority of reads.
I suspect process causes selectively removes A's at the end of the read, which causes the per base sequence content to fail in FASTQC (it does not fail before trimming). 

##### FastQC of the trimmed reads suggests:

* Around 10 - 15% duplicate reads.
* We have 30 - 40 million unique read pairs per sample.
* Reads are consistently AT rich, which may be a feature that these sequences are primarily upstream of TSS.

##### Alignment

* Reads align to the human reference at >99%, while only 30% align to the mouse genome.
* Very few reads map to the Y chromosome - CDX19 is froma a female patient, not sure about H146's
* All Chromosomes have a decent amout of reads proportionally, although MT has more than expected.
* Picard Alignment suggests we have between 25 - 35M paired reads per sample, after duplicate reads are removed.
* Insert size is approx 150bp, which makes sense

##### Additional QC

* Fingerprint plot - looks good, several samples have some high ChIP enrichment
* Reads are generally situated 500bp upstream of the TSS 

##### Peak Calls

* Total Peaks show H146_IP_SY0287 and CDX19_shATOH1#3_DOX_IP_SY0287 to have no peaks. The Ptech seems lower than the rest, but still a significant number of peaks.
* All reads map to called peaks 
* In the Normalized strand coefficient some samples are around or below 1.05. *1.1 is the critical threshold. Datasets with NSC values much less than 1.1 (< 1.05) tend to have low signal to noise or few peaks*
* Relative strand correlation (RSC), all samples are >1. *RSC values significantly lower than 1 (< 0.8) tend to have low signal to noise.*
* HOmer annotation looks as expected

All of these files are present in "/data/cep/CDX_Model_NGS_Data/ExVivo_Experiments/ATOH1_KD_ACatozzi/"

# Downstream anlaysis

## Design files

In the data folder there are:

* Design files to run Nextflow
* Sample sheets for ChIP to create dba objects in DiffBind: 
  1. all files
  2. "experiment" = only ATOH1
  3. Filtered = use xls files generated by macs2 **manually** filtered by pileup (>20) in excel.
  
.xls files filtered by pileup are in "/data/cep/CDX_Model_NGS_Data/ExVivo_Experiments/ATOH1_KD_ACatozzi/NFpipeline_ChIP/results_human/bwa/mergedLibrary/macs/narrowPeak/macs2_filtered_xls_files/"

## ChIP downstream analysis

Downstream anlaysis with differential binding (with DiffBind) was performed by Alessia.

The analysis was performed in two ways: 
* Standard analysis with NarrowPeak files from macs2 output (from Nextflow) --> this analysis is perfromed with code ChIP_Analysis_Alessia
* Filtered analysis, whereby narrowpeaks were filtered by pile up (>20) in the .xls file output of macs2 (from Nextflow) --> this analysis is perfromed with code ChIP_Analysis_Alessia_fiulterByPileUp


## RNASeq downstream analysis

I found a batch effect due to experimental date which was removed with Limma. Then, I performed DGEA between ATOH1 competent (6 samples) and ATOH1 KD (3 samples). These were not technical reps but **biological** reps.


## Data integration with BETA

After differential binding analysis and DGEA I performed integration of ChIPSeq and RNAseq data with BETA. 
Code in "BETA_Integration_RNAseq_ChIPSeq" and "BETA_Integration_RNAseq_ChIPSeq_filteredbyPileUp"

ATOH1 direct targets were then assayed for GO enrichment analysis with GProfiler within R and metascape on https://metascape.org/gp/index.html#/main/step1

## Output data

output data have been saved based on whether the anlaysis was filtered by pileup or not.

