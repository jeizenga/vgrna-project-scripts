
/*
calc_gam_edit_distance
Calculates the edit distance for each alignment in GAM format and outputs as a table
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <algorithm>
#include <assert.h>

#include "vg/io/stream.hpp"


using namespace std;

int64_t alignment_edit_dist(const vg::Alignment& aln) {
    int64_t dist = 0;
    for (const auto& mapping : aln.path().mapping()) {
        for (const auto& edit : mapping.edit()) {
            if (edit.from_length() == 0 || edit.to_length() == 0 || !edit.sequence().empty()) {
                dist += max(edit.from_length(), edit.to_length());
            }
        }
    }
    return dist;
}


int main(int argc, char* argv[]) {

    if (argc != 2) {
        cerr << "Usage: calc_gam_edit_distance <simulated_gam> > edit_dists.txt" << endl;
        return 1;
    }

    printScriptHeader(argc, argv);

    string gam_name = argv[1];
    ifstream gam(gam_name);
    if (!gam) {
        cerr << "error: could not open GAM file " << gam_name << endl;
        return 1;
    }
    
    cout << "read_name\tedit_dist\n";
    vg::io::for_each(gam, [&](vg::Alignment& aln) {
        cout << aln.name() << '\t' << alignment_edit_dist(aln) << '\n';
    });
    cout << std::flush;

	return 0;
}
