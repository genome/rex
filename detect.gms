Tool::Bwa::Index test_name = 'REFERENCE'

normal_alignment is Aligner::Standard unaligned_bam from @normal_bam
tumor_alignment is Aligner::Standard unaligned_bam from @tumor_bam

Tool::SomaticSniper normal_bam from normal_alignment,
                    tumor_bam  from tumor_alignment
