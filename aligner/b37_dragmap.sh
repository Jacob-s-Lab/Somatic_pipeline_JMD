#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J dragmap      # Job name
#SBATCH -p ngs186G           # Partition Name
#SBATCH -c 28              # core preserved
#SBATCH --mem=186G           # memory used

sample_id=
fastqdir=
fastq_1=$fastqdir/${sample_id}_1.fastq.gz
fastq_2=$fastqdir/${sample_id}_2.fastq.gz
output_dir=
ref=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta
ref_version=b37


module load biology/boost/1.80.0


RGSM="SM_"${sample_id}
group="GP_"${sample_id}

# make referance files folder

mkdir -p ${output_dir}/${ref_version}_ref


#build index
/opt/ohpc/Taiwania3/pkg/biology/Dragmap/DRAGMAP_v1.3/build/release/dragen-os --build-hash-table true --ht-reference ${ref} --output-directory ${output_dir}/${ref_version}_ref

# alignment
/opt/ohpc/Taiwania3/pkg/biology/Dragmap/DRAGMAP_v1.3/build/release/dragen-os -r ${output_dir}/${ref_version}_ref  -1 ${fastq_1} -2 ${fastq_2} --RGSM ${RGSM} > ${sample_id}.dragmap.${ref_version}.sam

# Sentieon
export SENTIEON_LICENSE=140.110.16.119:8990

platform="ILLUMINA"
SENTIEON_INSTALL_DIR="/staging/reserve/paylong_ntu/AI_SHARE/software/Sentieon/sentieon-genomics-202112"

nt=40 #number of threads to use in computation
sam=${output_dir}/${sample_id}.dragmap.${ref_version}.sam
sorted_bam=${output_dir}/${sample_id}.dragmap.${ref_version}.sorted.bam
deduped_bam=${output_dir}/${sample_id}.dragmap.${ref_version}.deduped.bam
score_info=${output_dir}/${sample_id}.dragmap.${ref_version}.score.txt
dedup_metrics=${output_dir}/${sample_id}.dragmap.${ref_version}.dedup_metrics.txt
realigned_bam=${output_dir}/${sample_id}.dragmap.${ref_version}.realigned.bam

dbsnp="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/dbsnp_138.b37.vcf"
known_Mills_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf"
known_1000G_indels="/staging/reserve/paylong_ntu/AI_SHARE/reference/GATK_bundle/2.8/b37/1000G_phase1.indels.b37.vcf"

cat $sam | $SENTIEON_INSTALL_DIR/bin/sentieon util sort -r $ref -o $sorted_bam -t $nt --sam2bam -i-
if [ -f $sorted_bam ]
then
 rm $sam 
fi

$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo LocusCollector --fun score_info $score_info
$SENTIEON_INSTALL_DIR/bin/sentieon driver -t $nt -i $sorted_bam --algo Dedup --rmdup --score_info $score_info --metrics $dedup_metrics $deduped_bam
$SENTIEON_INSTALL_DIR/bin/sentieon driver -r $ref  -t $nt -i $deduped_bam --algo Realigner -k $known_Mills_indels -k $known_1000G_indels $realigned_bam


