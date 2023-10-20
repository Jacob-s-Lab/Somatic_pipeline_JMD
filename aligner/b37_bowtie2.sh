#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J b37_bowtie2      # Job name
#SBATCH -p ngs1T_18           # Partition Name
#SBATCH -c 18               # core preserved
#SBATCH --mem=1000G           # memory used


SampleName=
workdir=
fastqdir=
fastq_1=$fastqdir/${SampleName}_1.fastq.gz
fastq_2=$fastqdir/${SampleName}_2.fastq.gz


# making folder and log file 

mkdir -p ${workdir}
cd ${workdir}


ref=b37
ref_fasta=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta
aligner=bowtie2
bowtie2=/opt/ohpc/Taiwania3/pkg/biology/BOWTIE/bowtie2_v2.4.2/bowtie2
bowtie2_build=/opt/ohpc/Taiwania3/pkg/biology/BOWTIE/bowtie2_v2.4.2/bowtie2-build

# Sentieon
export SENTIEON_LICENSE=
dbsnp="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/dbsnp_138.b37.vcf"
known_Mills_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
known_1000G_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/1000G_phase1.indels.b37.vcf"

sample="SM_"${SampleName}
group="GP_"${SampleName}
platform="ILLUMINA"

SENTIEON_INSTALL_DIR="/staging/reserve/paylong_ntu/AI_SHARE/software/Sentieon/sentieon-genomics-202112"
nt=40 #number of threads to use in computation


#output sample name
bw2_index=$workdir/${aligner}_${ref}.fai
sam=$workdir/${SampleName}.${aligner}.${ref}.sam
sorted_bam=$workdir/${SampleName}.${aligner}.${ref}.sorted.bam
deduped_bam=$workdir/${SampleName}.${aligner}.${ref}.deduped.bam
score_info=$workdir/${SampleName}.${aligner}.${ref}.score.txt
dedup_metrics=$workdir/${SampleName}.${aligner}.${ref}.dedup_metrics.txt
realigned_bam=$workdir/${SampleName}.${aligner}.${ref}.realigned.bam



#Align fastq by BOWTIE2
$bowtie2 -p $nt --rg-id $group --rg "SM:$sample" --rg "PL:$platform" -x $bw2_index -1 $fastq_1 -2 $fastq_2 -S $sam
cat $sam | $SENTIEON_INSTALL_DIR/bin/sentieon util sort -r ${ref_fasta} -o $sorted_bam -t $nt --sam2bam -i-
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo LocusCollector --fun score_info $score_info
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo Dedup --rmdup --score_info $score_info --metrics $dedup_metrics $deduped_bam
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r ${ref_fasta}  -t $nt -i $deduped_bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels $realigned_bam
