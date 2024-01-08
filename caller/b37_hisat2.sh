#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J b37_hisat2     # Job name
#SBATCH -p ngs1T_18           # Partition Name
#SBATCH -c 18               # core preserved
#SBATCH --mem=1000G           # memory used
#SBATCH --mail-user=r04633023@g.ntu.edu.tw
#SBATCH --mail-type=END

SampleName=$1
workdir=/staging/biology/peimiao0322/b37_Somatic/hisat2
fastqdir=/staging/reserve/paylong_ntu/AI_SHARE/reference/Somatic/SEQC2/WES_FASTQ/
fastq_1=$fastqdir/${SampleName}_1.fastq.gz
fastq_2=$fastqdir/${SampleName}_2.fastq.gz

# do not change
ref=b37
aligner=hisat2
ref_fasta=/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta

module add biology/HISAT2/2.2.1
export SENTIEON_LICENSE=140.110.16.119:8990

# make folder and logfile
mkdir -p ${workdir}
cd ${workdir}

logfile=${SampleName}_hisat2_run.log
exec 3<&1 4<&2
exec >$logfile 2>&1
set -euo pipefail
set -x


sample="SM_"${SampleName}
group="GP_"${SampleName}
platform="ILLUMINA"

SENTIEON_INSTALL_DIR="/staging/reserve/paylong_ntu/AI_SHARE/software/Sentieon/sentieon-genomics-202112"
nt=40 #number of threads to use in computation

#output file name
hisat2_index=$workdir/hisat2_human_g1k_v37_decoy.fai
sam=$workdir/${SampleName}.${aligner}.${ref}.sam
sorted_bam=$workdir/${SampleName}.${aligner}.${ref}.sorted.bam
deduped_bam=$workdir/${SampleName}.${aligner}.${ref}.deduped.bam
score_info=$workdir/${SampleName}.${aligner}.${ref}.score.txt
dedup_metrics=$workdir/${SampleName}.${aligner}.${ref}.dedup_metrics.txt
realigned_bam=$workdir/${SampleName}.${aligner}.${ref}.realigned.bam


dbsnp="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/dbsnp_138.b37.vcf"
known_Mills_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
known_1000G_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/1000G_phase1.indels.b37.vcf"

#Build HISAT2 index
#hisat2-build ${ref_fasta}  $hisat2_index

#Align fastq by HISAT2
hisat2 -p $nt --rg-id $group --rg "SM:$sample" --rg "PL:$platform" -x $hisat2_index -1 $fastq_1 -2 $fastq_2 -S $sam
cat $sam | $SENTIEON_INSTALL_DIR/bin/sentieon util sort -r ${ref_fasta} -o $sorted_bam -t $nt --sam2bam -i-

if [ -f $sorted_bam ]
then
  rm ${sam}
fi

$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo LocusCollector --fun score_info $score_info
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo Dedup --rmdup --score_info $score_info --metrics $dedup_metrics $deduped_bam
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r ${ref_fasta}  -t $nt -i $deduped_bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels $realigned_bam
