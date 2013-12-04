bwa_index is Tool::Bwa::Index test_name = 'REFERENCE',
    input_fasta from @reference_fasta

normal_alignment is Aligner::Standard
    alignment_index from bwa_index.output_fasta,
    unaligned_bam from @normal_bam
tumor_alignment is Aligner::Standard
    alignment_index from bwa_index.output_fasta,
    unaligned_bam from @tumor_bam

Tool::SomaticSniper
    alignment_index from bwa_index.output_fasta,
    normal_bam from normal_alignment.aligned_bam,
    tumor_bam  from tumor_alignment.aligned_bam,
    snv_output to @sniper_snv_output

Tool::Mutect
    alignment_index from bwa_index.output_fasta,
    normal_bam from normal_alignment.aligned_bam,
    tumor_bam  from tumor_alignment.aligned_bam

Tool::Strelka
    alignment_index from bwa_index.output_fasta,
    normal_bam from normal_alignment.aligned_bam,
    tumor_bam  from tumor_alignment.aligned_bam
