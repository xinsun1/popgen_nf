//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION } from '../../modules/local/gt_sam.nf'

// workflow GT_REGION {
//     take:
//     meta_gt

//     main:
//     meta_gt | view { it }
//     Channel.fromPath( meta_gt.list_region )
//     | splitText()
//     | view { it }
    

//     // MPILE_UP_CALL_REGION ( meta_gt, ch_region )
    

//     // emit:
//     // reads                                     // channel: [ val(meta), [ reads ] ]
//     // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
// }

workflow GT_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t', quote: '"')
    | multiMap { row ->
        meta:
            [
                ref:            row.ref,
                list_bam:       row.list_bam,
                batch:          row.batch,
                param_mpileup:  row.p_mpileup,
                param_call:     row.p_call,
                list_region:    row.list_region
            ]
        list_region: row.list_region
        
    }
    | set { meta_gt }
    meta_gt.list_region | view { it }

    // // ch_re = Channel.fromPath( file(meta_gt.list_region) )
    // Channel.fromPath( file(meta_gt.list_region) )
    // | splitText()
    // | view { it }

    // GT_REGION( meta_gt )

    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.meta )
}

