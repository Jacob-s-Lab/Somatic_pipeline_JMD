#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J b37_bwa      # Job name
#SBATCH -p ngs186G           # Partition Name
#SBATCH -c 28               # core preserved
#SBATCH --mem=186G           # memory used



export SENTIEON_LICENSE=
module add biology/HISAT2/2.2.1


SampleName=
workdir=
fastqdir=
fastq_1=$fastqdir/${SampleName}_1.fastq.gz
fastq_2=$fastqdir/${SampleName}_2.fastq.gz
# making folder and log file 

mkdir -p ${workdir}
cd ${workdir}

ref=b37
aligner=bwa
ref_fasta=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta

sample="SM_"${SampleName}
group="GP_"${SampleName}
platform="ILLUMINA"

SENTIEON_INSTALL_DIR="/staging/reserve/paylong_ntu/AI_SHARE/software/Sentieon/sentieon-genomics-202112"
nt=40 #number of threads to use in computation

sorted_bam=$workdir/${SampleName}.${aligner}.${ref}.sorted.bam
deduped_bam=$workdir/${SampleName}.${aligner}.${ref}.deduped.bam
score_info=$workdir/${SampleName}.${aligner}.${ref}.score.txt
dedup_metrics=$workdir/${SampleName}.${aligner}.${ref}.dedup_metrics.txt
realigned_bam=$workdir/${SampleName}.${aligner}.${ref}.realigned.bam

dbsnp="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/dbsnp_138.b37.vcf"
known_Mills_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
known_1000G_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/1000G_phase1.indels.b37.vcf"

($SENTIEON_INSTALL_DIR/bin/bwa mem -M -R "@RG\tID:$group\tSM:$sample\tPL:$platform" -t $nt -K 10000000 ${ref_fasta} $fastq_1 $fastq_2 || echo -n 'error' ) | $SENTIEON_INSTALL_DIR/bin/sentieon util sort -r ${ref_fasta} -o $sorted_bam -t $nt --sam2bam -i-
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo LocusCollector --fun score_info $score_info
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo Dedup --rmdup --score_info $score_info --metrics $dedup_metrics $deduped_bam
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r ${ref_fasta}  -t $nt -i $deduped_bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels ${realigned_bam}

