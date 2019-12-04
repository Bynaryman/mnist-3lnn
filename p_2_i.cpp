#include <stdlib.h>
#include <stddef.h>
#include <cstdio>

#include <fstream>
#include <vector>
#include <string>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <bitset>

/**
 * Simple helper function to malloc memory of a specifc size. The
 * function will throw an error if the memory can not be successfully
 * allocated.
 */
static void* smalloc(size_t size) {
  void* ptr;

  ptr = malloc(size);

  if (ptr == NULL) {
    printf("Error: Cannot allocate memory\n");
    exit(EXIT_FAILURE);
  }

  return ptr;
}

size_t load_file_to_memory(const char *filename, unsigned char **result) {
  size_t size;

  FILE *f = fopen(filename, "rb");
  if (f == NULL) {
    *result = NULL;
    printf("Error: Could not read file %s\n", filename);
    exit(EXIT_FAILURE);
  }

  fseek(f, 0, SEEK_END);
  size = ftell(f);
  fseek(f, 0, SEEK_SET);

  *result = reinterpret_cast<unsigned char *>(smalloc(sizeof(unsigned char)*(size)));

  if (size != fread(*result, sizeof(unsigned char), size, f)) {
    free(*result);
    printf("Error: read");
    exit(EXIT_FAILURE);
  }

  fclose(f);
  //(*result)[size] = 0;

  return size;
}

void save_file_from_memory(std::string path, const std::vector<unsigned char> &output_data) {

	std::ofstream my_file(path.c_str(), std::ofstream::out | std::ofstream::binary);

	if (my_file.is_open()) {
		for (size_t j = 0 ; j < output_data.size() ; j++) {
			my_file << output_data[j];
		}
		my_file.close();
	}
	else {
		std::cout << "error creating file" << std::endl;
	}

}

int main (int argc, char * argv[]) {

    // args description
    // argv[1] : str, input path of planar data set
    // argv[2] : str, output path for interleave data set
    // argv[3] : integer, bit width of posit
    // argv[4] : integer, NB_MLP (allows to compute the skip part)

    // general constants
    const unsigned int PIC_DIM(784);
    const uint64_t posit_width = 4;

    // will be recomputed below
    double char_ratio = 8/posit_width;
    std::cout << "char ratio" << char_ratio << std::endl;
    uint64_t chunk_width = 64 * char_ratio;
    unsigned int chunk_size(PIC_DIM*chunk_width);

    // input stuff declaration
    std::string in_file_path("");
    in_file_path = static_cast<std::string>(argv[1]); 
    unsigned char * in_data;
    size_t size_in = load_file_to_memory(in_file_path.c_str(), &in_data);
    uint64_t nb_datum = size_in * char_ratio; 
    uint64_t NB_chunk =  nb_datum/chunk_size;
    
    // convert in char to bitset
    // std::vector<std::bitset<posit_width>> bitset_domain_interleave(nb_datum);
    // for (int i = 0 ; i < size_in ; i++) {
    //     in_data_4b[(2*i)+1] = (in_data[i] >> 4) & 0xF;
    //     in_data_4b[(2*i)]   = (in_data[i]     ) & 0xF;
    //     // std::cout << in_data_4b[2*i] << " " << in_data_4b[(2*i)+1] << std::endl; 
    // }

    std::vector<std::bitset<posit_width>> bitset_domain_planar(nb_datum);
    uint64_t* planar_scratchpad = reinterpret_cast<uint64_t*>(in_data);
    uint64_t nb_posits_in64bp = 64 / posit_width;
    uint64_t mask = (1ULL << posit_width)-1;
    for (int i = 0, k=0 ; i < nb_datum ; i+=nb_posits_in64bp, k++ ) {
        for (int j = 0 ; j < nb_posits_in64bp ; j++) {
            uint32_t shift_amount = j * posit_width;
            bitset_domain_planar[i+j] = (planar_scratchpad[k] >> (shift_amount)) & mask;
        }
    }

    // output stuff declaration
    std::vector<unsigned char> output_data(size_in);
    std::string out_file_path("");
    out_file_path = static_cast<std::string>(argv[2]);
    std::vector<std::bitset<posit_width>> bitset_domain_interleave(nb_datum);

    // compute out data
    // planar to chunk_width pics chunk interleave
    unsigned int chunk_addr(0);
    for (int i = 0 ; i < NB_chunk ; ++i) {
        chunk_addr = i * PIC_DIM * chunk_width;
        for (int j = chunk_addr, k = 0 ; j < chunk_addr + chunk_size && k < chunk_size ; ++j, ++k) {
            unsigned int picture_number = k % chunk_width;
            unsigned int pixel_number = k / chunk_width;
            bitset_domain_interleave[j] = bitset_domain_planar[chunk_addr+ (picture_number*PIC_DIM) + pixel_number];
        }
    }

    // convert out bitset to out char
    // for (int i = 0 ; i < size_in ; i++) {
    //     output_data[i] = (unsigned char)( ((output_data_4b[(2*i)+1].to_ulong() << 4) & 0x00000000000000F0) | (output_data_4b[(2*i)].to_ulong() & 0x000000000000000F) );
    //     // std::cout << (int)output_data[i] << " " << output_data_4b[2*i] << " " <<  output_data_4b[(2*i)+1] << std::endl;
    // }

    uint64_t* interleave_scrathpad = reinterpret_cast<uint64_t*>(output_data.data());
    for (int i = 0, k=0 ; i < nb_datum ; i+=nb_posits_in64bp, k++ ) {
        uint64_t interleave_posits_64b = 0x0000000000000000;
        for (int j = 0 ; j < nb_posits_in64bp ; j++) {
            uint32_t shift_amount = j * posit_width;
            interleave_posits_64b |= (bitset_domain_interleave[i+j].to_ullong() << shift_amount) ;
        }
        interleave_scrathpad[k] = interleave_posits_64b;
    }

    // write out to file
    save_file_from_memory(out_file_path, output_data);

    // free memories and exit
    free(in_data);
    return 0;
}

