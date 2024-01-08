#!/bin/bash

r1=/staging/peimiao0322/${sample}_1.fastq.gz
r2=/staging/peimiao0322/${sample}_2.fastq.gz
ref_dir='/staging/peimiao0322/SRR'
output_prefix=${sample}_dragen_b37
RGSM="SM_"${sample}


mkdir -p ${output_dir}
cd ${output_dir}

TIME=`date +%Y%m%d%H%M`
logfile=./${TIME}_run.log
exec 3<&1 4<&2
exec >$logfile 2>&1
set -euo pipefail


dragen --ref-dir ${ref_dir}  --output-dir ${output_dir} --output-file-prefix ${output_prefix} --tumor-fastq1 ${r1} --tumor-fastq2 ${r2} --enable-map-align-output true --RGID-tumor ${RGID} --RGSM-tumor ${RGSM} --output-format CRAM --enable-variant-caller true --vc-enable-vcf-output true --vc-emit-ref-confidence GVCF  --repeat-genotype-enable true --enable-duplicate-marking true --remove-duplicates true --enable-map-align true 
