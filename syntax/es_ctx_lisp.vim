if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

if exists('g:lisp_isk')
 exe 'setl isk='.g:lisp_isk
elseif v:version > 704 || (v:version == 704 && has('patch-7.4.1142'))
 syn iskeyword 38,42,43,45,47-58,60-62,64-90,97-122,_
else
 setl iskeyword=38,42,43,45,47-58,60-62,64-90,97-122,_
endif

" Can it be made more lightweight?
syn keyword lispFunc < find-method pprint-indent
syn keyword lispFunc <= find-package pprint-linear
syn keyword lispFunc = find-restart pprint-logical-block
syn keyword lispFunc > find-symbol pprint-newline
syn keyword lispFunc >= finish-output pprint-pop
syn keyword lispFunc - first pprint-tab
syn keyword lispFunc / fixnum pprint-tabular
syn keyword lispFunc /= flet prin1
syn keyword lispFunc // float prin1-to-string
syn keyword lispFunc /// float-digits princ
syn keyword lispFunc * floating-point-inexact princ-to-string
syn keyword lispFunc ** floating-point-invalid-operation print
syn keyword lispFunc *** floating-point-overflow print-not-readable
syn keyword lispFunc + floating-point-underflow print-not-readable-object
syn keyword lispFunc ++ floatp print-object
syn keyword lispFunc +++ float-precision print-unreadable-object
syn keyword lispFunc 1- float-radix probe-file
syn keyword lispFunc 1+ float-sign proclaim
syn keyword lispFunc abort floor prog
syn keyword lispFunc abs fmakunbound prog*
syn keyword lispFunc access force-output prog1
syn keyword lispFunc acons format prog2
syn keyword lispFunc acos formatter progn
syn keyword lispFunc acosh fourth program-error
syn keyword lispFunc add-method fresh-line progv
syn keyword lispFunc adjoin fround provide
syn keyword lispFunc adjustable-array-p ftruncate psetf
syn keyword lispFunc adjust-array ftype psetq
syn keyword lispFunc allocate-instance funcall push
syn keyword lispFunc alpha-char-p function pushnew
syn keyword lispFunc alphanumericp function-keywords putprop
syn keyword lispFunc and function-lambda-expression quote
syn keyword lispFunc append functionp random
syn keyword lispFunc apply gbitp random-state
syn keyword lispFunc applyhook gcd random-state-p
syn keyword lispFunc apropos generic-function rassoc
syn keyword lispFunc apropos-list gensym rassoc-if
syn keyword lispFunc aref gentemp rassoc-if-not
syn keyword lispFunc arithmetic-error get ratio
syn keyword lispFunc arithmetic-error-operands get-decoded-time rational
syn keyword lispFunc arithmetic-error-operation get-dispatch-macro-character rationalize
syn keyword lispFunc array getf rationalp
syn keyword lispFunc array-dimension gethash read
syn keyword lispFunc array-dimension-limit get-internal-real-time read-byte
syn keyword lispFunc array-dimensions get-internal-run-time read-char
syn keyword lispFunc array-displacement get-macro-character read-char-no-hang
syn keyword lispFunc array-element-type get-output-stream-string read-delimited-list
syn keyword lispFunc array-has-fill-pointer-p get-properties reader-error
syn keyword lispFunc array-in-bounds-p get-setf-expansion read-eval-print
syn keyword lispFunc arrayp get-setf-method read-from-string
syn keyword lispFunc array-rank get-universal-time read-line
syn keyword lispFunc array-rank-limit go read-preserving-whitespace
syn keyword lispFunc array-row-major-index graphic-char-p read-sequence
syn keyword lispFunc array-total-size handler-bind readtable
syn keyword lispFunc array-total-size-limit handler-case readtable-case
syn keyword lispFunc ash hash-table readtablep
syn keyword lispFunc asin hash-table-count real
syn keyword lispFunc asinh hash-table-p realp
syn keyword lispFunc assert hash-table-rehash-size realpart
syn keyword lispFunc assoc hash-table-rehash-threshold reduce
syn keyword lispFunc assoc-if hash-table-size reinitialize-instance
syn keyword lispFunc assoc-if-not hash-table-test rem
syn keyword lispFunc atan host-namestring remf
syn keyword lispFunc atanh identity remhash
syn keyword lispFunc atom if remove
syn keyword lispFunc base-char if-exists remove-duplicates
syn keyword lispFunc base-string ignorable remove-if
syn keyword lispFunc bignum ignore remove-if-not
syn keyword lispFunc bit ignore-errors remove-method
syn keyword lispFunc bit-and imagpart remprop
syn keyword lispFunc bit-andc1 import rename-file
syn keyword lispFunc bit-andc2 incf rename-package
syn keyword lispFunc bit-eqv initialize-instance replace
syn keyword lispFunc bit-ior inline require
syn keyword lispFunc bit-nand in-package rest
syn keyword lispFunc bit-nor in-package restart
syn keyword lispFunc bit-not input-stream-p restart-bind
syn keyword lispFunc bit-orc1 inspect restart-case
syn keyword lispFunc bit-orc2 int-char restart-name
syn keyword lispFunc bit-vector integer return
syn keyword lispFunc bit-vector-p integer-decode-float return-from
syn keyword lispFunc bit-xor integer-length revappend
syn keyword lispFunc block integerp reverse
syn keyword lispFunc boole interactive-stream-p room
syn keyword lispFunc boole-1 intern rotatef
syn keyword lispFunc boole-2 internal-time-units-per-second round
syn keyword lispFunc boolean intersection row-major-aref
syn keyword lispFunc boole-and invalid-method-error rplaca
syn keyword lispFunc boole-andc1 invoke-debugger rplacd
syn keyword lispFunc boole-andc2 invoke-restart safety
syn keyword lispFunc boole-c1 invoke-restart-interactively satisfies
syn keyword lispFunc boole-c2 isqrt sbit
syn keyword lispFunc boole-clr keyword scale-float
syn keyword lispFunc boole-eqv keywordp schar
syn keyword lispFunc boole-ior labels search
syn keyword lispFunc boole-nand lambda second
syn keyword lispFunc boole-nor lambda-list-keywords sequence
syn keyword lispFunc boole-orc1 lambda-parameters-limit serious-condition
syn keyword lispFunc boole-orc2 last set
syn keyword lispFunc boole-set lcm set-char-bit
syn keyword lispFunc boole-xor ldb set-difference
syn keyword lispFunc both-case-p ldb-test set-dispatch-macro-character
syn keyword lispFunc boundp ldiff set-exclusive-or
syn keyword lispFunc break least-negative-double-float setf
syn keyword lispFunc broadcast-stream least-negative-long-float set-macro-character
syn keyword lispFunc broadcast-stream-streams least-negative-normalized-double-float set-pprint-dispatch
syn keyword lispFunc built-in-class least-negative-normalized-long-float setq
syn keyword lispFunc butlast least-negative-normalized-short-float set-syntax-from-char
syn keyword lispFunc byte least-negative-normalized-single-float seventh
syn keyword lispFunc byte-position least-negative-short-float shadow
syn keyword lispFunc byte-size least-negative-single-float shadowing-import
syn keyword lispFunc call-arguments-limit least-positive-double-float shared-initialize
syn keyword lispFunc call-method least-positive-long-float shiftf
syn keyword lispFunc call-next-method least-positive-normalized-double-float short-float
syn keyword lispFunc capitalize least-positive-normalized-long-float short-float-epsilon
syn keyword lispFunc car least-positive-normalized-short-float short-float-negative-epsilon
syn keyword lispFunc case least-positive-normalized-single-float short-site-name
syn keyword lispFunc catch least-positive-short-float signal
syn keyword lispFunc ccase least-positive-single-float signed-byte
syn keyword lispFunc cdr length signum
syn keyword lispFunc ceiling let simple-array
syn keyword lispFunc cell-error let* simple-base-string
syn keyword lispFunc cell-error-name lisp simple-bit-vector
syn keyword lispFunc cerror lisp-implementation-type simple-bit-vector-p
syn keyword lispFunc change-class lisp-implementation-version simple-condition
syn keyword lispFunc char list simple-condition-format-arguments
syn keyword lispFunc char< list* simple-condition-format-control
syn keyword lispFunc char<= list-all-packages simple-error
syn keyword lispFunc char= listen simple-string
syn keyword lispFunc char> list-length simple-string-p
syn keyword lispFunc char>= listp simple-type-error
syn keyword lispFunc char/= load simple-vector
syn keyword lispFunc character load-logical-pathname-translations simple-vector-p
syn keyword lispFunc characterp load-time-value simple-warning
syn keyword lispFunc char-bit locally sin
syn keyword lispFunc char-bits log single-flaot-epsilon
syn keyword lispFunc char-bits-limit logand single-float
syn keyword lispFunc char-code logandc1 single-float-epsilon
syn keyword lispFunc char-code-limit logandc2 single-float-negative-epsilon
syn keyword lispFunc char-control-bit logbitp sinh
syn keyword lispFunc char-downcase logcount sixth
syn keyword lispFunc char-equal logeqv sleep
syn keyword lispFunc char-font logical-pathname slot-boundp
syn keyword lispFunc char-font-limit logical-pathname-translations slot-exists-p
syn keyword lispFunc char-greaterp logior slot-makunbound
syn keyword lispFunc char-hyper-bit lognand slot-missing
syn keyword lispFunc char-int lognor slot-unbound
syn keyword lispFunc char-lessp lognot slot-value
syn keyword lispFunc char-meta-bit logorc1 software-type
syn keyword lispFunc char-name logorc2 software-version
syn keyword lispFunc char-not-equal logtest some
syn keyword lispFunc char-not-greaterp logxor sort
syn keyword lispFunc char-not-lessp long-float space
syn keyword lispFunc char-super-bit long-float-epsilon special
syn keyword lispFunc char-upcase long-float-negative-epsilon special-form-p
syn keyword lispFunc check-type long-site-name special-operator-p
syn keyword lispFunc cis loop speed
syn keyword lispFunc class loop-finish sqrt
syn keyword lispFunc class-name lower-case-p stable-sort
syn keyword lispFunc class-of machine-instance standard
syn keyword lispFunc clear-input machine-type standard-char
syn keyword lispFunc clear-output machine-version standard-char-p
syn keyword lispFunc close macroexpand standard-class
syn keyword lispFunc clrhash macroexpand-1 standard-generic-function
syn keyword lispFunc code-char macroexpand-l standard-method
syn keyword lispFunc coerce macro-function standard-object
syn keyword lispFunc commonp macrolet step
syn keyword lispFunc compilation-speed make-array storage-condition
syn keyword lispFunc compile make-array store-value
syn keyword lispFunc compiled-function make-broadcast-stream stream
syn keyword lispFunc compiled-function-p make-char stream-element-type
syn keyword lispFunc compile-file make-concatenated-stream stream-error
syn keyword lispFunc compile-file-pathname make-condition stream-error-stream
syn keyword lispFunc compiler-let make-dispatch-macro-character stream-external-format
syn keyword lispFunc compiler-macro make-echo-stream streamp
syn keyword lispFunc compiler-macro-function make-hash-table streamup
syn keyword lispFunc complement make-instance string
syn keyword lispFunc complex make-instances-obsolete string<
syn keyword lispFunc complexp make-list string<=
syn keyword lispFunc compute-applicable-methods make-load-form string=
syn keyword lispFunc compute-restarts make-load-form-saving-slots string>
syn keyword lispFunc concatenate make-method string>=
syn keyword lispFunc concatenated-stream make-package string/=
syn keyword lispFunc concatenated-stream-streams make-pathname string-capitalize
syn keyword lispFunc cond make-random-state string-char
syn keyword lispFunc condition make-sequence string-char-p
syn keyword lispFunc conjugate make-string string-downcase
syn keyword lispFunc cons make-string-input-stream string-equal
syn keyword lispFunc consp make-string-output-stream string-greaterp
syn keyword lispFunc constantly make-symbol string-left-trim
syn keyword lispFunc constantp make-synonym-stream string-lessp
syn keyword lispFunc continue make-two-way-stream string-not-equal
syn keyword lispFunc control-error makunbound string-not-greaterp
syn keyword lispFunc copy-alist map string-not-lessp
syn keyword lispFunc copy-list mapc stringp
syn keyword lispFunc copy-pprint-dispatch mapcan string-right-strim
syn keyword lispFunc copy-readtable mapcar string-right-trim
syn keyword lispFunc copy-seq mapcon string-stream
syn keyword lispFunc copy-structure maphash string-trim
syn keyword lispFunc copy-symbol map-into string-upcase
syn keyword lispFunc copy-tree mapl structure
syn keyword lispFunc cos maplist structure-class
syn keyword lispFunc cosh mask-field structure-object
syn keyword lispFunc count max style-warning
syn keyword lispFunc count-if member sublim
syn keyword lispFunc count-if-not member-if sublis
syn keyword lispFunc ctypecase member-if-not subseq
syn keyword lispFunc debug merge subsetp
syn keyword lispFunc decf merge-pathname subst
syn keyword lispFunc declaim merge-pathnames subst-if
syn keyword lispFunc declaration method subst-if-not
syn keyword lispFunc declare method-combination substitute
syn keyword lispFunc decode-float method-combination-error substitute-if
syn keyword lispFunc decode-universal-time method-qualifiers substitute-if-not
syn keyword lispFunc defclass min subtypep
syn keyword lispFunc defconstant minusp svref
syn keyword lispFunc defgeneric mismatch sxhash
syn keyword lispFunc define-compiler-macro mod symbol
syn keyword lispFunc define-condition most-negative-double-float symbol-function
syn keyword lispFunc define-method-combination most-negative-fixnum symbol-macrolet
syn keyword lispFunc define-modify-macro most-negative-long-float symbol-name
syn keyword lispFunc define-setf-expander most-negative-short-float symbolp
syn keyword lispFunc define-setf-method most-negative-single-float symbol-package
syn keyword lispFunc define-symbol-macro most-positive-double-float symbol-plist
syn keyword lispFunc defmacro most-positive-fixnum symbol-value
syn keyword lispFunc defmethod most-positive-long-float synonym-stream
syn keyword lispFunc defpackage most-positive-short-float synonym-stream-symbol
syn keyword lispFunc defparameter most-positive-single-float sys
syn keyword lispFunc defsetf muffle-warning system
syn keyword lispFunc defstruct multiple-value-bind t
syn keyword lispFunc deftype multiple-value-call tagbody
syn keyword lispFunc defun multiple-value-list tailp
syn keyword lispFunc defvar multiple-value-prog1 tan
syn keyword lispFunc delete multiple-value-seteq tanh
syn keyword lispFunc delete-duplicates multiple-value-setq tenth
syn keyword lispFunc delete-file multiple-values-limit terpri
syn keyword lispFunc delete-if name-char the
syn keyword lispFunc delete-if-not namestring third
syn keyword lispFunc delete-package nbutlast throw
syn keyword lispFunc denominator nconc time
syn keyword lispFunc deposit-field next-method-p trace
syn keyword lispFunc describe nil translate-logical-pathname
syn keyword lispFunc describe-object nintersection translate-pathname
syn keyword lispFunc destructuring-bind ninth tree-equal
syn keyword lispFunc digit-char no-applicable-method truename
syn keyword lispFunc digit-char-p no-next-method truncase
syn keyword lispFunc directory not truncate
syn keyword lispFunc directory-namestring notany two-way-stream
syn keyword lispFunc disassemble notevery two-way-stream-input-stream
syn keyword lispFunc division-by-zero notinline two-way-stream-output-stream
syn keyword lispFunc do nreconc type
syn keyword lispFunc do* nreverse typecase
syn keyword lispFunc do-all-symbols nset-difference type-error
syn keyword lispFunc documentation nset-exclusive-or type-error-datum
syn keyword lispFunc do-exeternal-symbols nstring type-error-expected-type
syn keyword lispFunc do-external-symbols nstring-capitalize type-of
syn keyword lispFunc dolist nstring-downcase typep
syn keyword lispFunc do-symbols nstring-upcase unbound-slot
syn keyword lispFunc dotimes nsublis unbound-slot-instance
syn keyword lispFunc double-float nsubst unbound-variable
syn keyword lispFunc double-float-epsilon nsubst-if undefined-function
syn keyword lispFunc double-float-negative-epsilon nsubst-if-not unexport
syn keyword lispFunc dpb nsubstitute unintern
syn keyword lispFunc dribble nsubstitute-if union
syn keyword lispFunc dynamic-extent nsubstitute-if-not unless
syn keyword lispFunc ecase nth unread
syn keyword lispFunc echo-stream nthcdr unread-char
syn keyword lispFunc echo-stream-input-stream nth-value unsigned-byte
syn keyword lispFunc echo-stream-output-stream null untrace
syn keyword lispFunc ed number unuse-package
syn keyword lispFunc eighth numberp unwind-protect
syn keyword lispFunc elt numerator update-instance-for-different-class
syn keyword lispFunc encode-universal-time nunion update-instance-for-redefined-class
syn keyword lispFunc end-of-file oddp upgraded-array-element-type
syn keyword lispFunc endp open upgraded-complex-part-type
syn keyword lispFunc enough-namestring open-stream-p upper-case-p
syn keyword lispFunc ensure-directories-exist optimize use-package
syn keyword lispFunc ensure-generic-function or user
syn keyword lispFunc eq otherwise user-homedir-pathname
syn keyword lispFunc eql output-stream-p use-value
syn keyword lispFunc equal package values
syn keyword lispFunc equalp package-error values-list
syn keyword lispFunc error package-error-package variable
syn keyword lispFunc etypecase package-name vector
syn keyword lispFunc eval package-nicknames vectorp
syn keyword lispFunc evalhook packagep vector-pop
syn keyword lispFunc eval-when package-shadowing-symbols vector-push
syn keyword lispFunc evenp package-used-by-list vector-push-extend
syn keyword lispFunc every package-use-list warn
syn keyword lispFunc exp pairlis warning
syn keyword lispFunc export parse-error when
syn keyword lispFunc expt parse-integer wild-pathname-p
syn keyword lispFunc extended-char parse-namestring with-accessors
syn keyword lispFunc fboundp pathname with-compilation-unit
syn keyword lispFunc fceiling pathname-device with-condition-restarts
syn keyword lispFunc fdefinition pathname-directory with-hash-table-iterator
syn keyword lispFunc ffloor pathname-host with-input-from-string
syn keyword lispFunc fifth pathname-match-p with-open-file
syn keyword lispFunc file-author pathname-name with-open-stream
syn keyword lispFunc file-error pathnamep with-output-to-string
syn keyword lispFunc file-error-pathname pathname-type with-package-iterator
syn keyword lispFunc file-length pathname-version with-simple-restart
syn keyword lispFunc file-namestring peek-char with-slots
syn keyword lispFunc file-position phase with-standard-io-syntax
syn keyword lispFunc file-stream pi write
syn keyword lispFunc file-string-length plusp write-byte
syn keyword lispFunc file-write-date pop write-char
syn keyword lispFunc fill position write-line
syn keyword lispFunc fill-pointer position-if write-sequence
syn keyword lispFunc find position-if-not write-string
syn keyword lispFunc find-all-symbols pprint write-to-string
syn keyword lispFunc find-class pprint-dispatch yes-or-no-p
syn keyword lispFunc find-if pprint-exit-if-list-exhausted y-or-n-p
syn keyword lispFunc find-if-not pprint-fill zerop
" clojure
syn keyword lispFunc true false
syn match lispParen '[()]'

syn match  lispKey      "[&:][^\t )]\+"
syn region lispString   start=+"+  skip=+\\\\\|\\"+ end=+"\|^+
syn region lispAtomList matchgroup=Special start="(" matchgroup=Special end=')\|^' contained contains=lispAtomList
syn match  lispAtom     "[^\t()]\+" contained
syn region lispAtom     start=+"+ skip=+\\"+  end=+"\|^+ contained
syn match  lispAtomMark "'" nextgroup=lispAtomList,lispAtom
syn match  lispComment  ";.*$"
syn region lispComment  start="#|" end="|#\|^"

hi def link lispFunc          Statement
hi def link lispParen         Delimiter
hi def link lispKey           Type
hi def link lispString        String
hi def link lispAtomList      cleared
hi def link lispAtom          Identifier
hi def link lispAtomMark      Delimiter
hi def link lispComment       Comment

let b:current_syntax = 'es_ctx_lisp'
