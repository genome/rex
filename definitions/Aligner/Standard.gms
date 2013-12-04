Aligner::Bwa::Paired
    alignment_index from @alignment_index,
    unaligned_bam from @unaligned_bam

Tool::Samtools::SamToBam
    sam_file from Paired.aligned_sam
Tool::Samtools::Sort
    input_bam from SamToBam.bam_file
Tool::Samtools::Index
    input_bam from Sort.output_bam,
    output_bam to @aligned_bam
