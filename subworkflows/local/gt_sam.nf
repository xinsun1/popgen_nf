//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION } from '../../modules/local/gt_sam.nf'

workflow GT_REGION {
    take:
    meta_gt
    list_region

    main:
    meta_gt | view { it }
    list_region | view {it}

    // Channel.fromPath( list_region )
    // | splitText()
    // | view { it }
    

    // MPILE_UP_CALL_REGION ( meta_gt, ch_region )
    

    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

workflow GT_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t', quote: '"')
    | multiMap { row ->
        meta:
            [
                batch:          row.batch,
                ref:            row.ref,
                list_bam:       row.list_bam,
                param_mpileup:  row.p_mpileup,
                param_call:     row.p_call
            ]
        list_region:    row.list_region
        // list_region:
        //     [
        //         batch:          row.batch,
        //         list_region:    row.list_region
        //     ]
    }
    | set { meta_gt }

    // // ch_re = Channel.fromPath( file(meta_gt.list_region) )
    // Channel.fromPath( file(meta_gt.list_region) )
    // | splitText()
    // | view { it }

    GT_REGION( meta_gt.meta, meta_gt.list_region)

    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.meta )
}

