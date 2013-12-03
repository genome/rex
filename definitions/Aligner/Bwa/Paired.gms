aln_first_reads  is Tool::Bwa::Aln read_mode = 1,
                                   alignment_index from @alignment_index,
                                   input_bam from @unaligned_bam
aln_second_reads is Tool::Bwa::Aln read_mode = 2,
                                   alignment_index from @alignment_index,
                                   input_bam from @unaligned_bam

Tool::Bwa::Sampe first_sai from aln_first_reads.sai_file,
                 second_sai from aln_second_reads.sai_file,
                 unaligned_bam from @unaligned_bam,
                 alignment_index from @alignment_index,
                 aligned_sam to @aligned_sam
