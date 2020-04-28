##################################################
## Script for NGS data processing (TransQST) #####
##################################################
###### Parameters set by user ####################

## Specify experiment details
COMP="DOX"
SPEC="human"
CPU=30

# Path to raw files 
RAWORIGIN=/ngs-data-2/data/TransQST/NovaSeq_runs/Fastq_04_21_2020_transQST_v5_1Mismatch/TransQST/


#####################################################################################
###################################### START RUN ####################################
#####################################################################################
## Create directories
#Paths that will be created for analyses
RAWDIR=/ngs-data-2/data/TransQST/${COMP}/${SPEC}/raw/
#Path to trimmed files
TRIMDIR=/ngs-data-2/data/TransQST/${COMP}/${SPEC}/trimmed/
#Path to QC output
QCDIR1=/ngs-data-2/data/TransQST/${COMP}/${SPEC}/QC1_output/
QCDIR2=/ngs-data-2/data/TransQST/${COMP}/${SPEC}/QC2_output/
TRANSCRIPTOME=/ngs-data-2/analysis/TransQST/Genome/hs_genome_bt1/hs_93 
ALIGNMENTS=/ngs-data-2/analysis/TransQST/${COMP}/${SPEC}/alignments/
GENES=/ngs-data-2/analysis/TransQST/${COMP}/${SPEC}/genes_results/
ISOFORMS=/ngs-data-2/analysis/TransQST/${COMP}/${SPEC}/isoforms_results/
mkdir -p ${RAWDIR} ${TRIMDIR} ${QCDIR1} ${QCDIR2} ${ALIGNMENTS} ${GENES} ${ISOFORMS} 

##Make copies of fastq files 
cp ${RAWORIGIN}*.fastq.gz ${RAWDIR}
# Create a .txt containing file names
ls ${RAWDIR} > /ngs-data-2/data/TransQST/DOX/human/filenames.txt
sed -e 's/_R2.*//g' -e 's/_R1.*//g' filenames.txt | uniq > unique_files.txt
SUFFIX=`sed -e 's/.*_R2//g' -e 's/.*_R1//g' filenames.txt | uniq`
SUFFIX_R1=_R1${SUFFIX}
SUFFIX_R2=_R1${SUFFIX}

#########CHANGE HERE THE NAME OF THE FILE CONTAINING SAMPLES TO BE ANALYZED (I.E., SPREAD ACROSS MULTIPLE WINDOWS)##
allfiles=`cat unique_files.txt`


##### RUNNING TRIMMING AND PIPING DIRECTLY INTO TO RSEM ######################## 
echo "Trimming, alignment and quantification are starting..."
FORWARD_P=_f_paired.fastq
REVERSE_P=_r_paired.fastq
FORWARD_U=_f_unpaired.fastq
REVERSE_U=_r_unpaired.fastq
GENESN=.genes.results
ISOFORMSN=.isoforms.results
ALIGNMENTSN=.transcript.bam

for i in $allfiles; do
cd ${RAWDIR}
echo "Trimming Sample $i"
DATE1="$(date -u +%s)"
java -Xms2G -Xmx3G -jar /share/tools/Trimmomatic-0.33/trimmomatic-0.33.jar PE -threads ${CPU} -phred33 $i${SUFFIX_R1} $i${SUFFIX_R2} ${TRIMDIR}$i${FORWARD_P}.gz ${TRIMDIR}$i${FORWARD_U}.gz ${TRIMDIR}$i${REVERSE_P}.gz ${TRIMDIR}$i${REVERSE_U}.gz ILLUMINACLIP:/share/tools/Trimmomatic-0.33/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 HEADCROP:12
cd ${TRIMDIR}
gunzip -k $i*.gz
echo "Starting alignment of sample $i"
/share/tools/RSEM-1.3.1/rsem-calculate-expression -p ${CPU} --bowtie-chunkmbs 1024 --bowtie-path /share/tools/bowtie-1.1.1/ --bowtie-chunkmbs 1024 --paired-end $i${FORWARD_P} $i${REVERSE_P} ${TRANSCRIPTOME} $i >> $i.txt 2>&1
mv $i${GENESN} ${GENES}
mv $i${ISOFORMSN} ${ISOFORMS}
mv $i${ALIGNMENTSN} ${ALIGNMENTS}
rm -rf $i.stat
rm -rf $i.temp
rm -rf $i*.fastq
DATE2="$(date -u +%s)"
elapsed="$(($DATE2-$DATE1))"
echo "Total of $elapsed seconds elapsed for trimming and alignment of sample $i"
done;

echo "Analyses are finished"

############ the end ##########

