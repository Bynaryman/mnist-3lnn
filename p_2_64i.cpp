#include <stdlib.h>
#include <stddef.h>
#include <cstdio>

#include <fstream>
#include <vector>
#include <string>
#include <iostream>
#include <cstdlib>
#include <cstring>

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

  *result = reinterpret_cast<unsigned char *>(smalloc(sizeof(unsigned char)*(size+1)));

  if (size != fread(*result, sizeof(unsigned char), size, f)) {
    free(*result);
    printf("Error: read");
    exit(EXIT_FAILURE);
  }

  fclose(f);
  (*result)[size] = 0;

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

    // general constants
    const unsigned int NB_16_chunk(2*4);
    const unsigned int PIC_DIM(784);
    const unsigned int chunk16_size(PIC_DIM*16);
    const unsigned int SIZE_DATA_OUT(NB_16_chunk * 16 * PIC_DIM);

    // input stuff declaration
    std::string in_file_path("");
    in_file_path = static_cast<std::string>(argv[1]); 
    unsigned char * in_data;
    load_file_to_memory(in_file_path.c_str(), &in_data);
    
    // output stuff declaration
    std::vector<unsigned char> output_data(SIZE_DATA_OUT);
    std::string out_file_path("");
    out_file_path = static_cast<std::string>(argv[2]);
    
    // compute out data
    // planar to 64 pics chunk interleave
    unsigned int chunk16_addr(0);
    for (int i = 0 ; i < NB_16_chunk ; ++i) {
        chunk16_addr = i * PIC_DIM * 16;
        for (int j = chunk16_addr, k = 0 ; j < chunk16_addr + chunk16_size && k < chunk16_size ; ++j, ++k) {
            unsigned int picture_number = k % 16;
            unsigned int pixel_number = k / 16;
//             std::cout << pixel_number << " " << picture_number << std::endl;
//             std::cout << chunk64_addr+ (picture_number*PIC_DIM) + pixel_number << std::endl;
//            std::cout << j << std::endl;
            output_data[j] = in_data[chunk16_addr+ (picture_number*PIC_DIM) + pixel_number];
        }
    }

    // write out to file
    save_file_from_memory(out_file_path, output_data);

    // free memories and exit
    free(in_data);
    return 0;
}
