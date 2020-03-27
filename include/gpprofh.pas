unit GpProfH;

interface

const
  PR_FREQUENCY   =  0; // .prf tags, never reuse them, always add new!
  PR_ENTERPROC   =  1;
  PR_EXITPROC    =  2;
  PR_UNITTABLE   =  3;
  PR_CLASSTABLE  =  4;
  PR_PROCTABLE   =  5;
  PR_PROCSIZE    =  6;
  PR_ENDDATA     =  7;
  PR_STARTDATA   =  8;
  PR_ENDHEADER   =  9;
  PR_COMPTICKS   = 10;
  PR_COMPTHREADS = 11;
  PR_PRFVERSION  = 12;
  PR_STARTCALIB  = 13;
  PR_ENDCALIB    = 14;
  PR_DIGEST      = 15;
  PR_DIGTHREADS  = 16;
  PR_DIGUNITS    = 17;
  PR_DIGCLASSES  = 18;
  PR_DIGPROCS    = 19;
  PR_DIGFREQ     = 20;
  PR_ENDDIGEST   = 21;
  PR_DIGESTVER   = 22;
  PR_DIGCALLG    = 23;
  PR_START_THREADINFO = 24;
  PR_END_THREADINFO = 25;
  PR_ENTER_MP   =  26;
  PR_EXIT_MP    =  27;
  PR_DIGENDCG    = -1;


  CALIB_CNT = 1000;

  CMD_MESSAGE = 'GPPROFILE_COMMAND';
  CMD_DONE    = 0;

  PRF_VERSION   = 4;

  { compressed format with the reduced raw data of the plain format }
  PRF_DIGESTVER_0 = 0;
  { data with additional average call time information for a procedure }
  PRF_DIGESTVER_1 = 1;
  { data with additional min/max call time information for a procedure }
  PRF_DIGESTVER_2 = 2;
  { data with additional callee and caller time information for a procedure }
  PRF_DIGESTVER_3 = 3;


  { the currently used digest version }
  PRF_DIGESTVER_CURRENT = PRF_DIGESTVER_3;

implementation

end.
 