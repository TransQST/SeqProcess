##################################################
## Script for NGS data processing (TransQST) #####
##################################################
###### Parameters set by user ####################

##Export and set tool paths
export PATH=$PATH:/share/tools/FastQC_v0.11.4/
export PATH=$PATH:/share/tools/Trimmomatic-0.33/
export PATH=$PATH:/share/tools/RSEM-1.3.1/
BOAPTH=/share/tools/bowtie-1.1.1/
CPU=30

#Path to raw files
RAWORIGIN=/ngs-data-2/data/TransQST/NovaSeq_runs/
RAWDIR=/ngs-data2/data/TransQST/DOX/mouse/raw/

#File containing sample names
allfiles=ls ${RAWORIGIN} > filenames.txt

#Path to trimmed files
TRIMDIR=/ngs-data2/data/TransQST/DOX/mouse/trimmed/

#Path to QC output
QCDIR1=/ngs-data2/data/TransQST/DOX/mouse/QC1_output/
QCDIR2=/ngs-data2/data/TransQST/DOX/mouse/QC2_output/

#Paths for RSEM
TRANSCRIPTOME=/ngs-data2/analysis/TransQST/Genome/mm_genome_bt1 ##if bowtie2 please adapt script at RSEM part
ALIGNMENTS=/ngs-data2/analysis/TransQST/DOX/mouse/alignments
GENES=/ngs-data2/analysis/TransQST/DOX/mouse/genes_results
ISOFORMS=/ngs-data2/analysis/TransQST/DOX/mouse/isoforms_results


#####################################################################################
###################################### SAMPLES ######################################
#####################################################################################
##Create directories
mkdir ${RAWDIR} ${TRIMDIR} ${QCDIR1} ${QCDIR2} ${ALIGNMENTS} ${GENES} ${ISOFORMS} 

##Run QC1
cd ${RAWDIR}  
for i in $allfiles; do
/share/tools/FastQC-0.11.7/fastqc $i -o ${QCDIR1}
echo "First QC with $i done";
done


##### RUNNING TRIMMING AND PIPING DIRECTLY INTO TO RSEM ######################## 
echo "Trimming, alignment and quantification are starting..."
PREFIX=cat_
SUFFIX_R1=_R1.fastq.gz
SUFFIX_R2=_R2.fastq.gz
FORWARD_P=_f_paired.fastq.gz
REVERSE_P=_r_paired.fastq.gz
FORWARD_U=_f_unpaired.fastq.gz
REVERSE_U=_r_unpaired.fastq.gz
GENESN=.genes.results
ISOFORMSN=.isoforms.results
ALIGNMENTSN=.transcript.bam


for i in $allfiles; do
cd ${CATDIR}
echo "Trimming Sample $i"
DATE1="$(date -u +%s)"
java -Xms2G -Xmx3G -jar trimmomatic-0.33.jar PE -threads ${CPU} -phred33 ${PREFIX}$i${SUFFIX_R1} ${PREFIX}$i${SUFFIX_R2} ${TRIMDIR}${PREFIX}$i${FORWARD_P} ${TRIMDIR}${PREFIX}$i${FORWARD_U} ${TRIMDIR}${PREFIX}$i${REVERSE_P} ${TRIMDIR}${PREFIX}$i${REVERSE_U} ILLUMINACLIP:/share/tools/Trimmomatic-0.33/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 HEADCROP:12
cd ${TRIMDIR}
gunzip -k ${PREFIX}$i*.gz
echo "Starting alignment of sample $i"
rsem-calculate-expression -p ${CPU} --bowtie-path ${BOPATH} --bowtie-chunkmbs 1024 --paired-end ${PREFIX}$i${FORWARD_P} ${PREFIX}$i${REVERSE_P} ${TRANSCRIPTOME} ${PREFIX}$i >> ${PREFIX}$i.txt 2>&1
mv ${PREFIX}$i${GENESN} ${GENES}
mv ${PREFIX}$i${ISOFORMSN} ${ISOFORMS}
mv ${PREFIX}$i${ALIGNMENTSN} ${ALIGNMENTS}
rm -rf ${PREFIX}$i.stat
rm -rf ${PREFIX}$i.temp
rm -rf ${PREFIX}$i*.fastq
DATE2="$(date -u +%s)"
elapsed="$(($DATE2-$DATE1))"
echo "Total of $elapsed seconds elapsed for trimming and alignment of sample $i"
done;
    
##Run QC2
cd ${TRIMDIR}  
for i in *_paired.fastq.gz; do
/share/tools/FastQC-0.11.7/fastqc $i -o ${QCDIR2}
echo "Second QC with $i done";
done

echo "Analyses are finished"

############ the end ##########

