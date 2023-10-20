#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J DeepVariant      # Job name
#SBATCH -p ngs1gpu           # Partition Name
#SBATCH -c 6               # core preserved
#SBATCH --mem=90G           # memory used
#SBATCH --gres=gpu:1        # 使用的GPU數 請參考Queue資源設定

aligner=
SampleName=
workdir=
ref="b37"

cd ${workdir}

module load libs/singularity/3.7.1

# environment setting

ref_fasta=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta


singularity run --nv -B ${workdir}:${workdir} \
/opt/ohpc/Taiwania3/pkg/biology/DeepVariant/deepvariant_1.4.0-gpu.sif \
/opt/deepvariant/bin/run_deepvariant \
--ref=${workdir}/human_g1k_v37_decoy.fasta \
--model_type=WES \
--reads=${workdir}/${SampleName}.${aligner}.${ref}.realigned.bam \
--output_vcf=${workdir}/${SampleName}.${aligner}.${ref}.DeepVariant.vcf.gz \
--output_gvcf=${workdir}/${SampleName}.${aligner}.${ref}.DeepVariant.gvcf.gz \
--num_shards=4



