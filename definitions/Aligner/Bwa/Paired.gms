aln_first_reads  is Tool::Bwa::Aln read_mode = 1,
                                   input_bam from @unaligned_bam
aln_second_reads is Tool::Bwa::Aln read_mode = 2,
                                   input_bam from @unaligned_bam

Tool::Bwa::Sampe first_sai  from aln_first_reads,
                 second_sai from aln_second_reads,
                 unaligned_bam from @unaligned_bam
