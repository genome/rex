tool Tool::Aligner::Bwa::Aln

inputs
File::Bam::Unaligned::Paired input_bam
File::AlignerIndex::Bwa alignment_index
Integer::Bwa::Aln::ReadMode read_mode
Integer::Bwa::Aln::Threads threads
Integer::Bwa::Aln::TrimmingQualityThreshold trimming_quality_threshold
PROCESS process_

outputs
File::Sai output_file
