#!/usr/bin/bash

SECONDS=0

# Change working Directory
cd /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2

# Step 1: Run Fastqc
fastqc /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887/SRR27313887_1.fastq /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887/SRR27313887_2.fastq -o /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data -t 8

# Run Trimmomatic to trim reads with poor quality
java -jar /mnt/a/ani_linux/tools/Trimmomatic/Trimmomatic-0.39/trimmomatic-0.39.jar SE -threads 8 /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887/SRR27313887_1.fastq /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887/SRR27313887_1trimmed.fastq TRAILING:10 -phred33
echo "Trimmomatic finished running"

# Run Fastqc on trimmed data
fastqc /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887/SRR27313887_1trimmed.fastq -o /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/

# Step 2: Run HISAT2
mkdir -p bowtie2  # Create directory if not exists
cd bowtie2

# Get the genome indices
wget -c https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz
tar -xvf grch38_genome.tar.gz

# Download sample data
prefetch SRR27313887

# Convert the downloaded data to FASTQ
fastq-dump --split-files -O ../data SRR27313887

# Run Bowtie2 alignment
bowtie2 --very-fast-local -x /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/bowtie2/grch38_genome -1 ../data/SRR27313887_1.fastq -2 ../data/SRR27313887_2.fastq -S /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887.sam -p 6
echo "Bowtie2 finished running!"

# Convert BAM file to SAM
samtools view -h -o /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887.sam /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887.bam

# Step 3: Run FeatureCounts - Quantification
# Get GTF File
wget https://ftp.ncbi.nlm.nih.gov/refseq/H_sapiens/annotation/GRCh38_latest/refseq_identifiers/GRCh38_latest_genomic.gtf.gz
gunzip GRCh38_latest_genomic.gtf.gz

# Run FeatureCounts
featureCounts -s 2 -a GRCh38_latest_genomic.gtf -o /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/quants/demo_feature_counts.txt /mnt/a/ani_linux/pipeline/RNASeq_pipeline/rna_seq_bowtie2/data/SRR27313887.bam
echo "FeatureCounts finished running!"

duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

