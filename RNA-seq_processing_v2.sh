##################################################
## Script for NGS data processing (TransQST) #####
##################################################
###### Parameters set by user ####################

## Specify experiment details
COMP="DOX"
SPEC="human2"
CPU=40

# Path to raw files 
RAWORIGIN=/ngs-data-2/data/TransQST/NovaSeq_runs/Fastq_04_21_2020_transQST_v5_1Mismatch/TransQST/
DATADIR=/ngs-data-2/data/TransQST/
OUTDIR=/ngs-data-2/analysis/TransQST/
GENOMEDIR=${OUTDIR}Genome/hs_genome_bt1/
GENOMEID="hs93"

# Path to tools
STAR_PATH=/home/tsouza/STAR-2.7.3a/source/STAR/
RSEM_PATH=/share/tools/RSEM-1.3.1/

#####################################################################################
###################################### START RUN ####################################
#####################################################################################
## Create directories
#Paths that will be created for analyses
RAWDIR=${DATADIR}${COMP}/${SPEC}/raw/
#Path to trimmed files
TRIMDIR=${DATADIR}${COMP}/${SPEC}/trimmed/
#Directories for outputs
QCDIR=${OUTDIR}${COMP}/${SPEC}/QC_output/
ALIGNMENTS=${OUTDIR}${COMP}/${SPEC}/alignment/
QUANT=${OUTDIR}${COMP}/${SPEC}/quantification/
GENES=${OUTDIR}${COMP}/${SPEC}/quantification/genes_results/
ISOFORMS=${OUTDIR}${COMP}/${SPEC}/quantification/isoforms_results/
#Create directories
mkdir -p ${TRIMDIR} ${QCDIR} ${ALIGNMENTS} ${QUANT} ${GENES} ${ISOFORMS} 

##Make copies of fastq files 
#cp ${RAWORIGIN}*.fastq.gz ${RAWDIR}
# Create a .txt containing file names
ls ${RAWDIR} > /ngs-data-2/data/TransQST/${COMP}/${SPEC}/filenames.txt
sed -e 's/_R2.*//g' -e 's/_R1.*//g' filenames.txt | uniq > unique_files.txt
SUFFIX=`sed -e 's/.*_R2//g' -e 's/.*_R1//g' filenames.txt | uniq`
SUFFIX_R1=_R1${SUFFIX}
SUFFIX_R2=_R2${SUFFIX}
OUTR1=_R1.fastq
OUTR2=_R2.fastq

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
#echo "QC of sample $i"
#/share/tools/FastQC-0.11.7/fastqc $i* -o ${QCDIR}
echo "Trimming Sample $i"
java -Xms2G -Xmx3G -jar /share/tools/Trimmomatic-0.33/trimmomatic-0.33.jar PE -threads ${CPU} -phred33 ${RAWDIR}$i${SUFFIX_R1} ${RAWDIR}$i${SUFFIX_R2} ${TRIMDIR}$i${FORWARD_P}.gz ${TRIMDIR}$i${FORWARD_U}.gz ${TRIMDIR}$i${REVERSE_P}.gz ${TRIMDIR}$i${REVERSE_U}.gz ILLUMINACLIP:/share/tools/Trimmomatic-0.33/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 HEADCROP:12
cd ${TRIMDIR}
gunzip -k $i*paired*.gz
echo "Starting alignment of sample $i"
/share/tools/RSEM-1.3.1/rsem-calculate-expression -p ${CPU} --bowtie-chunkmbs 1024 --bowtie-path /share/tools/bowtie-1.1.1/ --paired-end $i${FORWARD_P} $i${REVERSE_P} /ngs-data-2/analysis/TransQST/Genome/hs_genome_bt1/hs_93 $i >> $i.txt 2>&1
mv $i${GENESN} ${GENES}
mv $i${ISOFORMSN} ${ISOFORMS}
mv $i${ALIGNMENTSN} ${ALIGNMENTS}
rm -rf $i.stat
rm -rf $i.temp
rm -rf $i*.fastq
done;

### the end ######