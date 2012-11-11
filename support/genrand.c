
/* create a (long) sequence of pseudoi random data
 * 
 * Usage:
 * genrand -s seed -S statefile -n num_units -b -w -l -d -h -a -o -t 
 * -s seed : seed value, number in the range 0 < 2^32-1
 * -S statefile : file to store internal state between invocations
 * -m minvalue : minimal output vale to produce
 * -M maxvalue : maximum output value to produce
 * -c num_units : number of output data units
 * -b : output bytes
 * -w : output words (16-bits)
 * -l : output longs (32-bits)
 * -d : output units as decimal strings, one unit per line
 * -h : output units in hex-coding, one unit per line
 * -a : output units as string in base64-coding
 * -o : output units in binary coding, i.e. as one, two or four octets per unit
 * -t : produce triangular distributed numbers with limits -m and -M
 * 
 * -m -M -a and -t are not implemented.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <getopt.h>

extern char *optarg;
extern int optind;
extern int optopt;
extern int opterr;
extern int optreset;

char *option_string = "s:S:m:M:c:bwldhao";

static struct option long_options[] = {
	{"seed", required_argument, 0, 's'},
	{"statefile", required_argument, 0, 'S'},
	{"min", required_argument, 0, 'm'},
	{"max", required_argument, 0, 'M'},
	{"count", required_argument, 0, 'c'},
	{"bytes", no_argument, 0, 'b'},
	{"words", no_argument, 0, 'w'},
	{"longs", no_argument, 0, 'l'},
	{"decimal", no_argument, 0, 'd'},
	{"hex", no_argument, 0, 'h'},
	{"ascii", no_argument, 0, 'a'},
	{"octets", no_argument, 0, 'o'},
	{"help", no_argument, 0, '?'},
	{0, 0, 0, 0}
};

void print_help(void) {
  fprintf(stdout, "%s\n",
  " Usage:\n"
  " genrand -s seed -S statefile -n num_units -b -w -l -d -h -a -o -t \n"
  " -s seed : seed value, number in the range 0 < 2^32-1\n"
  " -S statefile : file to store internal state between invocations\n"
  " -m minvalue : minimal output vale to produce\n"
  " -M maxvalue : maximum output value to produce\n"
  " -c num_units : number of output data units\n"
  " -b : output bytes\n"
  " -w : output words (16-bits)\n"
  " -l : output longs (32-bits)\n"
  " -d : output units as decimal strings, one unit per line\n"
  " -h : output units in hex-coding, one unit per line\n"
  " -a : output units as string in base64-coding\n"
  " -o : output units in binary coding, i.e. as one, two or four octets per unit\n"
  " -t : produce triangular distributed numbers with limits -m and -M\n"
  " \n"
  " -m -M -a and -t are not implemented.\n");
}

int opt_mode_fmt = 'd';
int opt_mode_fmt_cnt = 0;
int opt_mode_size = 'b';
int opt_mode_size_cnt = 0;
char *opt_seed = 0;
unsigned long opt_min = 0;
unsigned long opt_max = 0;
unsigned long long opt_count = 0;
char *opt_statefile = 0;
unsigned long long opt_seed_lcg = 0;
unsigned long long opt_seed_lfsr = 0;


/*
 * The first prng implements a linear congruential generator, as used
 * by many libraries and compilers.  This implemention follows the 
 * algorithm found under
 * [1] http://en.wikipedia.org/wiki/Linear_congruential_generator
 * and uses the parameters listed there for the glibc variant.
 */
unsigned long long lcg_param_a = 1103515245;  /* lcg multiplicator as per [1] */
unsigned long long lcg_param_c = 12345;  /* additive factor as per [1] */
unsigned int lcg_param_m = 31; /* exponent of modulus as per [1] */
unsigned long long lcg_param_m2 = 0x07fffffff; /* bit mask for modulus operation: 2^31 - 1 */
 
/* lcg state */
unsigned int lcg_bits_left = 0;  /* number of unused bits from last iteration. */
unsigned long lcg_bits = 0;  /* result of last iteration */
unsigned long long lcg_val = 0;  /* internal value of lcg */
unsigned long long lcg_bits2 = 0; /* shadow register for lcg_bits, used to construct 32 bit values. */
unsigned int lcg_bits2_left = 0; /* number of valid bits in lcg_bits2 */
unsigned long *lcg_bits_lp = &lcg_bits;
unsigned short *lcg_bits_wp = (unsigned short *) &lcg_bits;
unsigned char *lcg_bits_cp = (unsigned char *) &lcg_bits;


#ifdef DEBUG_LCG
unsigned int lcg_dbg_cnt = 0;
#endif

void lcg_iterate(void) {
#ifdef DEBUG_LCG
  unsigned char c = (unsigned char) ( (lcg_dbg_cnt << 2) & 0x0ff);
  lcg_bits_cp[0] = c;
  lcg_bits_cp[2] = c | 1;
  lcg_bits_cp[2] = c | 2;
  lcg_bits_cp[3] = c | 3;
  lcg_dbg_cnt += 1;
#else
  while (lcg_bits2_left < 32) {
    lcg_val *= lcg_param_a;
    lcg_val += lcg_param_c;
    lcg_val &= lcg_param_m2;
    if (lcg_bits2_left > 0)
      lcg_bits2 |= lcg_val << lcg_bits2_left;
    else
      lcg_bits2 = lcg_val;
    lcg_bits2_left += lcg_param_m;
  }
  lcg_bits = (unsigned long)lcg_bits2;
  lcg_bits2 = lcg_bits2 >> 32;
  lcg_bits2_left -= 32;
#endif
  lcg_bits_left = 32;
}

void lcg_save_state(FILE *fp) {
  fprintf(fp, "[lcg]\n");
  fprintf(fp, "# linear congruential generator\n");
  fprintf(fp, "# see [1] http://en.wikipedia.org/wiki/Linear_congruential_generator\n");

  /* lcg parameters */
  fprintf(fp, "# lcg multiplicator as per [1]\n"
              "lcg_param_a = %lld\n", lcg_param_a);

  fprintf(fp, "# additive factor as per [1]\n"
              "lcg_param_c = %lld\n", lcg_param_c);

  fprintf(fp, "# exponent of modulus as per [1]\n"
              "lcg_param_m = %d\n", lcg_param_m); /*  */
 
  /* lcg state */
  fprintf(fp, "# internal value of lcg (seed)\n"
              "lcg_val = %lld\n", lcg_val);

  fprintf(fp, "# shadow register for lcg_bits, used to construct 32 bit values\n"
              "lcg_bits2 = %lld\n", lcg_bits2);

  fprintf(fp, "# number of valid bits in lcg_bits2\n"
              "lcg_bits2_left = %d\n", lcg_bits2_left);

  fprintf(fp, "# result of last iteration\n"
              "lcg_bits = %ld\n", lcg_bits );

  fprintf(fp, "# number of unused bits from last iteration\n"
              "lcg_bits_left = %d\n", lcg_bits_left);
}

int lcg_read_state(FILE *fp, char *readbuffer) {
  int stateflags = 0;
  char key[255];
  unsigned long long val=0;
  unsigned int n=0;
  
  while (!feof(fp)) {
    if (fgets(readbuffer, 255, fp) != NULL) {
      if (readbuffer[0] == '#' || readbuffer[0] == 10)
        continue;
      n = sscanf(readbuffer, "%s = %lld", key, &val);
      if (n != 2)
        break;
      if (strcmp(key, "lcg_param_a") == 0) {
        lcg_param_a = val;
        stateflags |= 1;
      } else
      if (strcmp(key, "lcg_param_c") == 0) {
        lcg_param_c = val;
        stateflags |= 2;
      } else
      if (strcmp(key, "lcg_param_m") == 0) {
        lcg_param_m = val;
        stateflags |= 4;
      } else
      if (strcmp(key, "lcg_val") == 0) {
        lcg_val = val;
        stateflags |= 8;
      } else
      if (strcmp(key, "lcg_bits2") == 0) {
        lcg_bits2 = val;
        stateflags |= 16;
      } else
      if (strcmp(key, "lcg_bits2_left") == 0) {
        lcg_bits2_left = val;
        stateflags |= 32;
      } else
      if (strcmp(key, "lcg_bits") == 0) {
        lcg_bits = val;
        stateflags |= 64;
      } else
      if (strcmp(key, "lcg_bits_left") == 0) {
        lcg_bits_left = val;
        stateflags |= 128;
      } else {
        // unknown key
        fprintf(stderr, "Warning: Skipping unknown key '%s' in state file\n", key);
      }
    } else {
      break;
    }
  }
  if (stateflags != 255) {
    fprintf(stderr, "Warning: State file is incomplete, using defaults\n");
  }
}

unsigned short get_byte_lcg() {
  if (lcg_bits_left == 0) {
    lcg_iterate();
  }
  unsigned short res = lcg_bits;
  lcg_bits = lcg_bits >> 8;
  lcg_bits_left -= 8;
  res &= 0xff;
  return res;
}

unsigned short get_word_lcg() {
  unsigned short res;

  if (lcg_bits_left == 0) {
    lcg_iterate();
  }

  if (lcg_bits_left >= 16) {
    res = lcg_bits;
    lcg_bits = lcg_bits >> 16;
    lcg_bits -= 16;
  } else {
    /* we have only 8 bits left. */
    res = lcg_bits;
    res = res << 8;
    lcg_bits = 0;
    lcg_iterate();
    res |= get_byte_lcg();
  }
  
  res &= 0x0ffff;
  return res;
}

unsigned long get_long_lcg() {
  if (lcg_bits != 0) {
    unsigned int res = lcg_bits;
    if (lcg_bits_left == 24) {
      res = res << 8;
      lcg_bits = 0;
      res |= get_byte_lcg();
    } else if (lcg_bits_left == 16) {
      res = res << 16;
      lcg_bits = 0;
      res |= get_word_lcg();
    } else {
      res = res << 16;
      lcg_bits = 0;
      res |= get_word_lcg();
      res = res << 8;
      res |= get_byte_lcg();
    }
    return res;
  } else {
    lcg_iterate();
    lcg_bits_left = 0;
    return lcg_bits;
  }
}


void fill_lcg(char *buf, unsigned int bytes) {
  unsigned int bytes_left = lcg_bits_left / 8;
  if (bytes <= bytes_left) {
    unsigned int i;
    for (i = 0; i < bytes; i++)
      buf[i] = get_byte_lcg();
  } else {
    unsigned int i;
    for (i = 0; i < bytes_left; i++) {
      buf[i] = get_byte_lcg();
    }
    if ( ((unsigned long)buf & 0x01) == 1) {
      /* misalligned -> copy byte by byte */
      while (i < bytes) {
        buf[i++] = get_byte_lcg();
      }
    } else {
      /* word aligned, go by full copy */
      unsigned int words = (bytes-i)/4;
      while (words > 0) {
        unsigned long *word_p = (void *)buf;
        *word_p++ = get_long_lcg();
        bytes -= 4;
        i += 4;
      }
      while (bytes > 0) {
        buf[i++] = get_byte_lcg();
        bytes -= 1;
      }
    }
  }
}


int load_statefile(void) {
  FILE *fp = fopen(opt_statefile, "r");

  if (fp == 0) {
    perror("Can't read statefile");
    return 1;
  }

  int err = 0;
  char readbuffer[256];
  while (!feof(fp)) {
    if (fgets(readbuffer, 255, fp) == NULL)
      break;

    if (strcmp(readbuffer, "[lcg]\n") == 0)
      err = lcg_read_state(fp, readbuffer);

  }
  if (ferror(fp)) {
    err |= 1;
    perror("Error while reading statefile");
  }
  fclose(fp);
  
  return err;
}

int save_statefile(void) {
  FILE *fp = fopen(opt_statefile, "w");
  if (fp == NULL) {
    perror("Can't write statefile");
    return 1;
  }
  int err = 0;
  lcg_save_state(fp);
  if (ferror(fp)) {
    perror("Error while writing statefile");
    err = 1;
  }
  fclose(fp);
  return err;
}

int parse_seed(const char *str) {
  int n=0;
  n = sscanf(str, "%lld", &opt_seed_lcg);
  
  if (n == 1) {
    lcg_val = opt_seed_lcg;
    lcg_bits = 0;
    lcg_bits_left = 0;
    lcg_bits2 = 0;
    lcg_bits2_left = 0;
    return 0;
  } else {
    fprintf(stderr, "Error, invalid seed value '%s'\n", str);
    return 1;
  }
}

int main(int argc, char **argv) {
  
  int c=0;
  int opt_unknown = 0;
  while (c != -1 && opt_unknown == 0) {
    int option_index = 0;

    c = getopt_long(argc, argv, option_string, long_options, &option_index);

		switch(c) {
		case 's':
			opt_seed = strdup(optarg);
			break;
		case 'S':
			opt_statefile = strdup(optarg);
			break;
		case 'm':
			opt_min = atol(optarg);
			break;
		case 'M':
			opt_max = atol(optarg);
			break;
		case 'c':
			opt_count = atoll(optarg);
			break;
		case 'b':
		case 'w':
		case 'l':
			opt_mode_size = c;
      opt_mode_size_cnt += 1;
      break;
		case 'd':
		case 'h':
		case 'a':
    case 'o':
			opt_mode_fmt = c;
      opt_mode_fmt_cnt += 1;
      break;
    case '?':
      opt_unknown = 1;
      break;
    case -1:
      break;
    default:
      opt_unknown = 1;
      break;
    }
  }

  if (opt_mode_size_cnt > 1) {
    printf("%s\n", "only one of b,w,l may be specified.");
    opt_unknown = 1;
  }

  if (opt_mode_fmt_cnt > 1) {
    printf("%s\n", "only one of d,h,a,o may be specified.");
    opt_unknown = 1;
  }
  
  if (opt_count == 0) {
    if (opt_mode_fmt_cnt > 0 || opt_mode_size_cnt > 0 || opt_statefile == 0) {
      printf("%s\n", "You must specify -c count.");
      opt_unknown = 1;
    } else {
      // neither mode nor count given, but statefile given.  Just (re)create a state file.
      if (opt_seed)
        parse_seed(opt_seed);
      return save_statefile();
    }
  }

  if (opt_unknown == 1) {
    print_help();
    return 1;
  }

  int err=0;
  if (opt_statefile != 0)
    err = load_statefile();

  if (opt_seed != 0)
    err |= parse_seed(opt_seed);

  if (err != 0)
    return 1;  /* error messages already printed by above functions. */

  unsigned long long baseconv = 0;
  int baseconv_bits = 0;

  while (opt_count > 0) {
    if (opt_mode_size == 'b') {
      unsigned int tmp_int = get_byte_lcg();
      if (opt_mode_fmt == 'd') {
        fprintf(stdout, "%d\n", tmp_int);
      } else if (opt_mode_fmt == 'h') {
        fprintf(stdout, "%02x\n", tmp_int);
      } else if (opt_mode_fmt == 'a') {
        baseconv |= tmp_int << baseconv_bits;
        baseconv_bits += 8;
        while (baseconv_bits >= 6) {
          fprintf(stdout, "%c", 32 + (unsigned int)(baseconv & 0x03f));
          baseconv = baseconv >> 6;
          baseconv_bits -= 6;
        }
      } else {
        fprintf(stdout, "%c", tmp_int); /* no newline */
      }
    } else if (opt_mode_size == 'w') {
      unsigned short tmp_short = get_word_lcg();
      unsigned char *tmp_short_p = (unsigned char *)&tmp_short;
      if (opt_mode_fmt == 'd') {
        fprintf(stdout, "%d\n", (unsigned int)tmp_short);
      } else if (opt_mode_fmt == 'h') {
        fprintf(stdout, "%04x\n", (unsigned int)tmp_short);
      } else if (opt_mode_fmt == 'a') {
        baseconv |= ((unsigned long long)tmp_short) << baseconv_bits;
        baseconv_bits += 16;
        while (baseconv_bits >= 6) {
          fprintf(stdout, "%c", 32 + (unsigned int)(baseconv & 0x03f));
          baseconv = baseconv >> 6;
          baseconv_bits -= 6;
        }
/*        fprintf(stdout, "%c%c%c\n", 32 + (tmp_short & 0x03f), 32 + ((tmp_short & 0x0fc0) >> 6), 32 + ((tmp_short & 0x03f000) >> 12)); */
      } else {
        fprintf(stdout, "%c%c", tmp_short_p[0], tmp_short_p[1]); /* no newline */
      }
    } else {
      unsigned long tmp_long = get_long_lcg();
      unsigned char *tmp_long_p = (unsigned char *)&tmp_long;
      if (opt_mode_fmt == 'd') {
        fprintf(stdout, "%ld\n", tmp_long);
      } else if (opt_mode_fmt == 'h') {
        fprintf(stdout, "%08lx\n", tmp_long);
      } else if (opt_mode_fmt == 'a') {
        baseconv |= ((unsigned long long)tmp_long) << baseconv_bits;
        baseconv_bits += 32;
        while (baseconv_bits >= 6) {
          fprintf(stdout, "%c", 32 + (unsigned int)(baseconv & 0x03f));
          baseconv = baseconv >> 6;
          baseconv_bits -= 6;
        }
/*        int i;
        for (i = 0; i < 7; i++) {
          fprintf(stdout, "%c", 32 + (unsigned int)(tmp_long & 0x03f));
          tmp_long = tmp_long >> 6;
        }
        fprintf(stdout, "\n");
*/
      } else {
        fprintf(stdout, "%c%c%c%c", tmp_long_p[0], tmp_long_p[1], tmp_long_p[2], tmp_long_p[3]); /* no newline */
      }
    }
    opt_count -= 1;
  }

  if (opt_mode_fmt == 'a') {
    if (baseconv_bits > 0) {
      fprintf(stdout, "%c", 32 + (unsigned int)(baseconv & 0x03f));
    }
    fprintf(stdout, "\n");
  }

  fflush(stdout);
  
  if (opt_statefile != 0)
    err = save_statefile();

	return err;
}

