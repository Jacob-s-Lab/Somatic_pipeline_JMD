#!/bin/bash
#SBATCH -A MST109178        # Account name/project number
#SBATCH -J mutect2      # Job name
#SBATCH -p ngs186G           # Partition Name
#SBATCH -c 28               # core preserved
#SBATCH --mem=186G           # memory used



aligner=
SampleName=
workdir=
cd ${workdir}


gatk=/opt/ohpc/Taiwania3/pkg/biology/GATK/gatk_v4.2.3.0/gatk
ref=b37
ref_fasta=/reference/GATK_bundle/2.8/b37/human_g1k_v37_decoy.fasta

realigned_bam=${workdir}/${SampleName}.${aligner}.${ref}.realigned.bam
mutect2_vcf=${workdir}/${SampleName}.${aligner}.${ref}.Mutect2.vcf

$gatk --java-options "-Xmx80g" Mutect2 -I $realigned_bam  -O ${mutect2_vcf} -R ${ref_fasta}


