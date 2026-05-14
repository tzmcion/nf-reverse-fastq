include {downloadGenome} from "./modules/downloads.nf"
include {download_reads} from "./modules/downloads.nf"
include {checkSums as checkSum1} from "./modules/downloads.nf"
include {checkSums as checkSum2} from "./modules/downloads.nf"
include {cut_genome} from "./modules/process_genome.nf"
include {build_index} from "./modules/process_genome.nf"
include {gene_location} from "./modules/locations.nf"
include {align_sort_reads} from "./modules/process_genome.nf"
include {reverse_engineer_reads} from "./modules/process_genome.nf"
include {zip_files} from "./modules/process_genome.nf"

include {DOWNLOAD_CHECK_GENOME} from "./workflows/dw_genome_workflow.nf"
include {ALIGN_WORKFLOW} from "./workflows/align_workflow.nf"

params {
    batch: String
    refGenome_file_link: String
    checksum_annotations: String
    annotations_file_link: String
    checksum_genome: String
    csvSRA: String
    genes: String
    refGenome_regex: String
    refGenome_indexed: String
}

workflow {
    main:
    //Wrkflow for downloading and checking the control sum of annotation and reference files
    DOWNLOAD_CHECK_GENOME(
        params.annotations_file_link,
        params.checksum_annotations,
        params.refGenome_file_link,
        params.checksum_genome
    )
    //Extract only XY and 1-22 chromosomes from the refGenome
    cut_genome(DOWNLOAD_CHECK_GENOME.out.ref_genome, params.refGenome_regex)
    //Build the index of genome_ref, as it is time-consuming, index can be given
    
    
    //Get the SRA IDs from input file and 
    SRA_files = Channel.fromPath(params.csvSRA)
                    .splitCsv(header: true, sep: ';')
                    .map(item -> item["SRA_id"])

    //Get the genes names into a channel
    genes_names = Channel.fromPath(params.genes)
    //Get the genes locations from annotations file into
    gene_location(genes_names, DOWNLOAD_CHECK_GENOME.out.annot_file)

    //Align the reads and get the reverse reads
    ALIGN_WORKFLOW(
        cut_genome.out.genome_ref,
        Channel.fromPath(params.refGenome_indexed),
        gene_location.out.genes_locs,
        SRA_files
        )

    //Zip the results into one gzip file
    zip_files(
        ALIGN_WORKFLOW.out.reads.collect()
    )
    //publish the results
    publish:
    revs = zip_files.out.zipped_fastqs
}

output {
    //And of course the reads
    revs{
        path "reversed_fastqs"
        mode "copy"
    }

}