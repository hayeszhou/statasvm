
/* load the C extension */
ensurelib_aberrance svm // check for libsvm
program _svm, plugin    // load _svm.plugin, the wrapper for libsvm

program define svm_train, eclass
  version 13
  
  // these defaults were taken from svm-train.c
  // (except that we have shrinking off by default)
  #delimit ;
  syntax varlist (numeric)
         [if] [in]
         [,
           // strings cannot have default values
           // ints and reals *must*
           // (and yes the only other data types known to syntax are int and real, despite the stata datatypes being str, int, byte, float, double, ...)
           // 
           // also be careful of the mixed-case shenanigans
           
           Type(string)
           
           Kernel(string)
           
           GAMMA(real 0) COEF0(real 0) DEGree(int 3)
           
            C(real 1) P(real 0.1) NU(real 0.5)
           
           // weights() --> char* weight_label[], double weight[nr_weight] // how should this work?
           // apparently syntax has a special 'weights' argument which is maybe meant just for this purpose
           // but how to pass it on?
           EPSilon(real 0.001)
           
           SHRINKing PROBability
           
           CACHE_size(int 100)
           
           // if specified, a column to generate to mark which rows were detected as SVs
           SV(string)
         ];
  #delimit cr
  // stash because we run syntax again below, which will smash these
  local cmd = "`0'"
  local _varlist = "`varlist'"
  local _if = "`if'"
  local _in = "`in'"
  gettoken depvar indepvars : _varlist
  
  /* fill in defaults for the string values */
  if("`type'"=="") {
    local type = "C_SVC"
  }
  
  if("`type'" == "C_SVC" | "`type'" == "NU_SVC" /* | "`type'" == "ONE_CLASS" ???? */) {
    // "ensure" type is categorical
    local T : type `depvar'
    if("`T'"=="float" | "`T'"=="double") {
      di as error "Warning: `depvar' is a `T', which is usually used for continuous variables."
      di as error "         SV classification will cast real numbers to integers before fitting." //<-- this is done by libsvm with no control from us
      di as error
      di as error "         If your outcome is actually categorical, consider storing it as one:"
      di as error "         . tempvar B"
      di as error "         . generate byte \`B' = `depvar'"   //CAREFUL: B is meant to be quoted and depvar is meant to be unquoted.
      di as error "         . drop `depvar'"
      di as error "         . rename \`B' `depvar'"
      di as error "         (If your category encoding uses floating point levels this will not be enough)"
      di as error
      di as error "         Alternately, consider SV regression: type(EPSILON_SVR) or type(NU_SVR)."
      
    }
  }
  
  if("`kernel'"=="") {
    local kernel = "RBF"
  }
  
  /* make the string variables case insensitive (by forcing them to CAPS and letting the .c deal with them that way) */
  local type = upper("`type'")
  local kernel = upper("`kernel'")
  
  /* translate the boolean flags into integers */
  // the protocol here is silly, because syntax special-cases "no" prefixes:
  // *if* the user gives the no form of the option, a macro is defined with "noprobability" in lower case in it
  // in all *other* cases, the macro is undefined (so if you eval it you get "")
  // conversely, with regular option flags, if the user gives it you get a macro with "shrinking" in it, and otherwise the macro is undefined
  
  if("`shrinking"=="shrinking") {
    local shrinking = 1
  }
  else {
    local shrinking = 0
  }

  if("`probability'"=="probability") {
    local probability = 1
    
    // ensure model is a classification
    if("`type'" != "C_SVC" & "`type'" != "NU_SVC") {
      // the command line tools *allow* this combination, but at prediction time silently change the parameters
      // "Errors should never pass silently. Unless explicitly silenced." -- Tim Peters, The Zen of Python
      di as error "Error: requested model is a `type'. You can only use the probability option with classification models (C_SVC, NU_SVC)."
      exit 2
    }
  }
  else {
    local probability = 0
  }
  
  // fail-fast on name errors in sv()
  if("`sv'"!="") {
    local 0 = "`sv'"
    syntax newvarname
    
  }
  
  
  /* call down into C */
  #delimit ;
  plugin call _svm `_varlist' `_if' `_in', "train"
      "`type'" "`kernel'"
      "`gamma'" "`coef0'" "`degree'"
      "`c'" "`p'" "`nu'"
      "`epsilon'"
      "`shrinking'" "`probability'"
      "`cache_size'"
      ;
  #delimit cr
  
  /* fixup the e() dictionary */
  ereturn clear
  
  // set standard Stata estimation (e()) properties
  ereturn local cmd = "svm_train"
  ereturn local cmdline = "`e(cmd)' `cmd'"
  ereturn local predict = "svm_predict" //this is a function pointer, or as close as Stata has to that: causes "predict" to run "svm_predict"
  ereturn local estat = "svm_estat"     //ditto. NOT IMPLEMENTED
  
  ereturn local title = "Support Vector Machine"
  ereturn local model = "svm"
  ereturn local svm_type = "`type'"
  ereturn local svm_kernel = "`kernel'"
  
  ereturn local depvar = "`depvar'"
  //ereturn local indepvars = "`indepvars'" //XXX Instead svm_predict reparses cmdline. This needs vetting.
  
  // append the svm_model structure to e()
  _svm_model2stata `_if' `_in', sv(`sv')
end
