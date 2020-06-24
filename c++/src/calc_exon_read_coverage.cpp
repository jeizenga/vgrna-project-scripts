
/*
calc_exon_rsem_read_coverage
Calculates mapped read coverage across exons in a bed file. 
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <assert.h>

#include "SeqLib/BamReader.h"
#include "SeqLib/BamRecord.h"

#include "utils.hpp"

using namespace SeqLib;

int main(int argc, char* argv[]) {

    if (argc != 3) {

        cout << "Usage: calc_allele_read_coverage <read_bam> <exon_bed> > coverage.txt" << endl;
        return 1;
    }

    printScriptHeader(argc, argv);

    BamReader bam_reader;
    bam_reader.Open(argv[1]);
    assert(bam_reader.IsOpen());

    GRC exons;
    assert(exons.ReadBED(argv[2], bam_reader.Header()));

    cout << "Count" << "\t" << "MapQ" << "\t" << "AllelePosition" << "\t" << "ExonSize" << "\t" << "ReadCoverage" << "\t" << "BaseCoverage" << endl;

    BamRecord bam_record;

    uint32_t num_exons = 0;

    auto exons_it = exons.begin();

    while (exons_it != exons.end()) {

        num_exons++;

        exons_it->pos2--;

        assert(bam_reader.SetRegion(*exons_it));

        unordered_map<uint32_t, pair<uint32_t, uint32_t> > mapq_read_coverage_counts;

        while (bam_reader.GetNextRecord(bam_record)) { 

            auto read_genomic_regions = cigarToGenomicRegions(bam_record.GetCigar(), bam_record.Position());
            read_genomic_regions.CreateTreeMap();

            auto overlap = read_genomic_regions.FindOverlapWidth(*exons_it, true);

            if (overlap > 0) {

                auto mapq_read_coverage_counts_it = mapq_read_coverage_counts.emplace(bam_record.MapQuality(), make_pair(0, 0));
                mapq_read_coverage_counts_it.first->second.first++;
                mapq_read_coverage_counts_it.first->second.second += overlap;
            }
        }

        for (auto & mapq_count: mapq_read_coverage_counts) {

            cout << "1";
            cout << "\t" << mapq_count.first;
            cout << "\t" << exons_it->ToString(bam_reader.Header());
            cout << "\t" << exons_it->Width();
            cout << "\t" << mapq_count.second.first;
            cout << "\t" << mapq_count.second.second;
            cout << endl;
        }

        if (num_exons % 10000 == 0) {

            cerr << "Number of analysed exons: " << num_exons << endl;
        }  

        exons_it++;      
    }

    bam_reader.Close();

    cerr << "\nTotal number of analysed exons: " << num_exons << endl;

	return 0;
}