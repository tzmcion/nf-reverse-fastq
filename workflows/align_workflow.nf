//Here each read will SRA accesion will be downloaded
//And alligned to the reference genome, given in a parameters
//By the index folder

include {align_sort_reads} from "../modules/process_genome.nf"
include {reverse_engineer_reads} from "../modules/process_genome.nf"
include {download_reads} from "../modules/downloads.nf"
include {build_index} from "../modules/process_genome.nf"

workflow ALIGN_WORKFLOW {
    take:
    Genome_ref
    REFGenome_indexed
    GENE_locations
    SRA_accession

    main:
    //Download the reads
    download_reads(SRA_accession)
    //Combine the indexes and reads so the alignment runs as many times as there is SRA files
    build_index(Genome_ref, REFGenome_indexed)
    def comb = build_index.out.indexed_folder.combine(build_index.out.indexed_name)
    //combination should make them run after one is downloaded
    mapped = download_reads.out.reads.combine(comb).view()
    

    align_sort_reads(mapped)
    //Combine gene names and gene locations
    split_genes = GENE_locations.splitCsv(sep:';')
    combinations = split_genes.combine(align_sort_reads.out.align_tuple)
    reverse_engineer_reads(combinations)

    emit:
    reads = reverse_engineer_reads.out.fastqs_gene
}