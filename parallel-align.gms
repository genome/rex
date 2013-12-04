bwa_index is Tool::Bwa::Index test_name = 'REFERENCE',
    input_fasta from @reference_fasta

Aligner::Standard parallel by unaligned_bam,
    alignment_index from bwa_index.output_fasta,
    unaligned_bam from @unaligned_bams,
    aligned_bam to @aligned_bams
