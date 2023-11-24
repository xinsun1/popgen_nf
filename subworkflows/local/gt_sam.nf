//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION } from '../../modules/local/gt_sam.nf'

workflow GT_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t' )
    | map { row ->
        meta_gt = [
            ref:            row.ref,
            list_bam:       row.list_bam,
            batch:          row.batch,
            param_mpileup:  row.p_mpileup,
            param_call:     row.p_call
        ]
        list_region = row.list_region
    }
    | set { meta }
    meta.view { it }
    
    Channel.fromPath(meta.list_region)
    | view{ it }

    // MPILE_UP_CALL_REGION ( meta_gt, ch_region )
    

    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.meta )
}

