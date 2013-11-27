Aligner::Bwa::Paired unaligned_bam from @unaligned_bam
Tool::Samtools::SamToBam
Tool::Samtools::Sort input_bam from SamToBam
Tool::Samtools::Index input_bam from Sort
