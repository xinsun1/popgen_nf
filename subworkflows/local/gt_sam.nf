//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { MPILE_UP_CALL_REGION; READ_CHR } from '../../modules/local/gt_sam.nf'

workflow GT_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t')
    | multiMap { row ->
        meta_gt = [
            batch:          row.batch,
            ref:            file(row.ref),
            list_bam:       file(row.list_bam),
            param_mpileup:  row.p_mpileup,
            param_call:     row.p_call
        ]
        list_region:    file(row.list_region)
    }
    | set { meta_gt }

    list_region = meta_gt.list_region.collect()
    // // ch_re = Channel.fromPath( file(meta_gt.list_region) )
    Channel.fromPath( list_region[0] )
    | splitText()
    | view { it }

    // ch_meta_run = READ_CHR( meta_gt)
    // ch_meta_run.meta_batch | view { it }
    // Channel.fromPath(ch_meta_run)
    // | splitCsv ( header: true, sep: '\t')
    // | map { row ->
    //     [
    //         batch:          row.batch,
    //         ref:            row.ref,
    //         list_bam:       row.list_bam,
    //         param_mpileup:  row.p_mpileup,
    //         param_call:     row.p_call,
    //         region:         row.region
    //     ]
    // }
    // | set { meta_gt_run }
    // meta_gt_run | view{ it }
    
    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    GT_META ( params.meta )
}

