#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J tnscope     # Job name
#SBATCH -p ngs186G           # Partition Name
#SBATCH -c 28               # core preserved
#SBATCH --mem=186G           # memory used


aligner=
SampleName=
workdir=

export SENTIEON_LICENSE=140.110.16.119:8990

sample="SM_"${SampleName}
group="GP_"${SampleName}
platform="ILLUMINA"

SENTIEON_INSTALL_DIR="/staging/reserve/paylong_ntu/AI_SHARE/software/Sentieon/sentieon-genomics-202112"

ref=b37
ref_fasta=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta

nt=40 #number of threads to use in computation
score_info=$workdir/${SampleName}.${aligner}.${ref}.score.txt
dedup_metrics=$workdir/${SampleName}.${aligner}.${ref}.dedup_metrics.txt
realigned_bam=$workdir/${SampleName}.${aligner}.${ref}.realigned.bam
recal_data=$workdir/${SampleName}.${aligner}.${ref}.recal_data.table
vcf=$workdir/${SampleName}.${aligner}.${ref}.TNscope.vcf
dbsnp="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/dbsnp_138.b37.vcf"
known_Mills_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
known_1000G_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/1000G_phase1.indels.b37.vcf"

#Base recalibration
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r ${ref_fasta} -t $nt -i $realigned_bam --algo QualCal -k $dbsnp -k $known_Mills_indels -k $known_1000G_indels $recal_data


# TNscope calling
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r ${ref_fasta} -t $nt -i $realigned_bam -q $recal_data --algo TNscope --tumor_sample $sample --dbsnp $dbsnp $vcf

