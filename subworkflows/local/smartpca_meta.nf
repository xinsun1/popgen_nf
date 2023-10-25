//
// Generate smartpca par file and run smartpca from metafile input
//

nextflow.enable.dsl = 2

include { SMARTPCA_PAR; SMARTPCA } from '../../modules/local/smartpca.nf'

workflow SMARTPCA_META {
    take:
    meta_batch

    main:
    Channel.fromPath(meta_batch)
    | splitCsv ( header: true, sep: '\t' )
    | map { row ->
        eigen_meta = [
            snp:      "${row.wdir}/${row.eigen_snp}",
            geno:     "${row.wdir}/${row.eigen_geno}",
            ind:      "${row.wdir}/${row.eigen_ind}",
            pop_list: "${row.wdir}/${row.pop_list}"
        ]
        para_meta = [
            nchr: row.nchr,
            lsqprj: row.lsqprj,
            args: row.args
        ]    
        [row.batch_id, eigen_meta, para_meta]
    }
    | set { batches }
    // batches.view { it }
    
    ch_par = SMARTPCA_PAR ( batches )
    //ch_par.view { it }


    // | SMARTPCA() 


    // emit:
    // reads                                     // channel: [ val(meta), [ reads ] ]
    // versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}


workflow {
    SMARTPCA_META ( params.meta )
}
