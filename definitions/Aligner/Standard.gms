bwa_index is Tool::Bwa::Index test_name = 'REFERENCE',
    input_fasta from @reference_fasta
Aligner::Bwa::Paired
    alignment_index from bwa_index.output_fasta,
    unaligned_bam from @unaligned_bam

Tool::Samtools::SamToBam
    sam_file from Paired.aligned_sam
Tool::Samtools::Sort
    input_bam from SamToBam.bam_file
Tool::Samtools::Index
    input_bam from Sort.output_bam
