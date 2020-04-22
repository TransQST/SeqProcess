##################################################
## Script for NGS data processing (TransQST) #####
##################################################
###### Parameters set by user ####################
CPU=30

#File containing sample names
allfiles=`cat 'filenames_002004.txt'`

#Path to raw files
RAWDIR=/share/data/undefined_projects/TransQST/mouse/raw/ 

#Path to concatenated files
CATDIR=/ngs-data2/data/TransQST/DOX/mouse/cat/ 

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
mkdir ${RAWDIR} ${CATDIR} ${TRIMDIR} ${QCDIR1} ${QCDIR2} ${ALIGNMENTS} ${GENES} ${ISOFORMS}

#Concatenate samples
echo "Starting concatenation of .fastq files"
SUFFIX_R1=_R1.fastq
SUFFIX_R2=_R2.fastq

for i in $allfiles;
do
cd ${RAWDIR}$i
gunzip -k *.gz
cat *R1*.fastq > cat_$i${SUFFIX_R1}
cat *R2*.fastq > cat_$i${SUFFIX_R2}
gzip cat_$i${SUFFIX_R1}
gzip cat_$i${SUFFIX_R2}
echo $i "done";
mv cat_*.fastq.gz ${CATDIR}
#rm $i.fastq
done;
echo "Finished concatenating, starting first QC..."

##Run QC1
cd ${CATDIR}  
for i in $allfiles; do
/share/tools/FastQC-0.11.7/fastqc $i -o ${QCDIR1}
echo "First QC with $i done";
done


##### RUNNING TRIMMING AND PIPING DIRECTLY INTO TO RSEM ######################## 
echo "Trimming, alignment and qualification is starting..."
export PATH=$PATH:/share/tools/FastQC_v0.11.4/
export PATH=$PATH:/share/tools/Trimmomatic-0.33/
PREFIX=cat_
SUFFIX_R1=_R1.fastq
SUFFIX_R2=_R2.fastq
FORWARD_P=_f_paired.fastq
REVERSE_P=_r_paired.fastq
FORWARD_U=_f_unpaired.fastq
REVERSE_U=_r_unpaired.fastq
GENESN=.genes.results
ISOFORMSN=.isoforms.results
ALIGNMENTSN=.transcript.bam


for i in $allfiles; do
cd ${CATDIR}
echo "Trimming Sample $i"
DATE1="$(date -u +%s)"
java -Xms2G -Xmx3G -jar /share/tools/Trimmomatic-0.33/trimmomatic-0.33.jar PE -threads ${CPU} -phred33 ${PREFIX}$i${SUFFIX_R1}.gz ${PREFIX}$i${SUFFIX_R2}.gz ${TRIMDIR}${PREFIX}$i${FORWARD_P}.gz ${TRIMDIR}${PREFIX}$i${FORWARD_U}.gz ${TRIMDIR}${PREFIX}$i${REVERSE_P}.gz ${TRIMDIR}${PREFIX}$i${REVERSE_U}.gz ILLUMINACLIP:/share/tools/Trimmomatic-0.33/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 HEADCROP:12
cd ${TRIMDIR}
gunzip -k ${PREFIX}$i*.gz
echo "Starting alignment of sample $i"
/share/tools/RSEM-1.3.1/rsem-calculate-expression -p ${CPU} --bowtie-path /share/tools/bowtie-1.1.1 --bowtie-chunkmbs 1024 --paired-end ${PREFIX}$i${FORWARD_P} ${PREFIX}$i${REVERSE_P} ${TRANSCRIPTOME} ${PREFIX}$i >> ${PREFIX}$i.txt 2>&1
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

