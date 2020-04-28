# SeqProcess
> (Pre)Processing of RNA-sequencing data generated within TransQST project (WP8)

## Outline
This shell script is to be used to process RNA-seq data (.fastq file format). The user should customize parameters described in the first part of the script.  
Edited: version 2 (v2) does not contain a concatenation step (when reads are spread across multiple lanes during sequencing).
The processing consists of 3 main steps:  
1. Quality control with FastQC  
2. Trimming of adapters and first 12 bases with Trimmomatic  
3. Alignment with bowtie/bowtie2 and quantification with RSEM

## Prerequisites
The script is suited for shell. Tools used:
```shell
Trimmomatic
Bowtie
RSEM 
```

## Input files
It takes .fastq files as input.

## Output
1. Intermediate files (a copy of original files, trimmed .fastq files) 
2. Alignment files (.BAM files)
3. Files with gene (.genes.results) and isoform (.isoform.results) counts 


