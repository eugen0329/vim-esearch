if exists('b:current_syntax')
  finish
endif

" based on vim builtin syntax

syn keyword es_cConstant NULL
syn keyword es_cStatement    goto break return continue asm const_cast static_cast dynamic_cast reinterpret_cast
syn keyword es_cLabel        case default
syn keyword es_cConditional  if else switch
syn keyword es_cRepeat       while for do
syn keyword es_cStructure    struct union enum typedef class typename template namespace
syn keyword es_cStorageClass static register auto volatile extern const mutable
syn keyword es_cType         int long short char void signed unsigned float double int8_t int16_t int32_t int64_t uint8_t uint16_t uint32_t uint64_t
syn region  es_cComment      start="//"  end="$"
syn region  es_cComment      start="/\*" end="\*/\|^"
syn region  es_cString       start=+"+ skip=+\\\\\|\\"+ end=+"\|^+

syn region es_cPreProc        start="\(%:\|#\)\s*\(pragma\|line\|warning\|warn\|error\)" end="$\|^" contains=ALL
syn region es_cDefine         start="\(%:\|#\)\s*\(define\|undef\)\>"                    end="$\|^"
syn region es_cPreCondit      start="\(%:\|#\)\s*\(if\|ifdef\|ifndef\|elif\)\>"          end="$\|^"
syn match  es_cPreConditMatch "\(%:\|#\)\s*\(else\|endif\)\>"

syn region  es_cIncluded        contained start=+"+ skip=+\\\\\|\\"+ end=+"\|^+
syn match   es_cIncluded        contained "<[^>]*>"
syn match   es_cInclude         "\(%:\|#\)\s*include\>\s*["<]" contains=es_cIncluded

syn keyword es_cppSTLconstant std experimental this_thread filesystem execution rel_ops nullptr badbit cerr cin clog cout digits digits10 eofbit failbit goodbit has_denorm has_denorm_loss has_infinity has_quiet_NaN has_signaling_NaN is_bounded is_exact is_iec559 is_integer is_modulo is_signed is_specialized max_digits10 max_exponent max_exponent10 min_exponent min_exponent10 nothrow npos radix round_style tinyness_before traps wcerr wcin wclog wcout
syn keyword es_cppSTLtype allocator auto_ptr basic_filebuf basic_fstream basic_ifstream basic_iostream basic_istream basic_istringstream basic_ofstream basic_ostream basic_ostringstream basic_streambuf basic_string basic_stringbuf basic_stringstream binary_compose binder1st binder2nd bitset char_traits char_type const_mem_fun1_t const_mem_fun_ref1_t const_mem_fun_ref_t const_mem_fun_t const_pointer const_reference container_type deque difference_type div_t double_t filebuf first_type float_denorm_style float_round_style float_t fstream gslice_array ifstream imaxdiv_t indirect_array int_type ios_base iostream istream istringstream istrstream iterator_traits key_compare key_type ldiv_t list lldiv_t map mapped_type mask_array mem_fun1_t mem_fun_ref1_t mem_fun_ref_t mem_fun_t multimap multiset nothrow_t off_type ofstream ostream ostringstream ostrstream pair pointer pointer_to_binary_function pointer_to_unary_function pos_type priority_queue queue reference second_type sequence_buffer set sig_atomic_t size_type slice_array stack stream streambuf streamsize string stringbuf stringstream strstream strstreambuf temporary_buffer test_type time_t tm traits_type type_info u16string u32string unary_compose unary_negate valarray value_compare value_type vector wfilebuf wfstream wifstream wiostream wistream wistringstream wofstream wostream wostringstream wstreambuf wstring wstringbuf wstringstream
syn keyword es_cppSTLios boolalpha dec defaultfloat endl ends fixed floatfield flush get_money get_time hex hexfloat internal noboolalpha noshowbase noshowpoint noshowpos noskipws nounitbuf nouppercase oct put_money put_time resetiosflags scientific setbase setfill setiosflags setprecision setw showbase showpoint showpos skipws unitbuf uppercase

syn keyword es_cppSTLtype is_void is_integral is_floating_point is_array is_enum is_union is_class is_function is_pointer is_lvalue_reference is_rvalue_reference is_member_object_pointer is_member_function_pointer is_fundamental is_arithmetic is_scalar is_object is_compound is_reference is_member_pointer is_const is_volatile is_trivial is_trivially_copyable is_standard_layout is_pod is_literal_type is_empty is_polymorphic is_abstract is_signed is_unsigned is_constructible is_trivially_constructible is_nothrow_constructible is_default_constructible is_trivially_default_constructible is_nothrow_default_constructible is_copy_constructible is_trivially_copy_constructible is_nothrow_copy_constructible is_move_constructible is_trivially_move_constructible is_nothrow_move_constructible is_assignable is_trivially_assignable is_nothrow_assignable is_copy_assignable is_trivially_copy_assignable is_nothrow_copy_assignable is_move_assignable is_trivially_move_assignable is_nothrow_move_assignable is_destructible is_trivially_destructible is_nothrow_destructible has_virtual_destructor alignment_of rank extent is_same is_base_of is_convertible remove_cv remove_const remove_volatile add_cv add_const add_volatile remove_reference add_lvalue_reference add_rvalue_reference remove_pointer add_pointer make_signed make_unsigned remove_extent remove_all_extents aligned_storage aligned_union decay enable_if conditional common_type underlying_type result_of integral_constant true_type false_type unordered_map unordered_set unordered_multimap unordered_multiset hasher key_equal

syn keyword es_cppSTLfunction abort abs accumulate acos adjacent_difference adjacent_find adjacent_find_if advance append arg asctime asin assert assign at atan atan2 atexit atof atoi atol atoll back back_inserter bad beg binary_compose binary_negate binary_search bind1st bind2nd binder1st binder2nd bsearch calloc capacity ceil clear clearerr clock close compare conj construct copy copy_backward cos cosh count count_if c_str ctime denorm_min destroy difftime distance div empty eof epsilon equal equal_range erase exit exp fabs fail failure fclose feof ferror fflush fgetc fgetpos fgets fill fill_n find find_end find_first_not_of find_first_of find_if find_last_not_of find_last_of first flags flip floor flush fmod fopen for_each fprintf fputc fputs fread free freopen frexp front fscanf fseek fsetpos ftell fwide fwprintf fwrite fwscanf gcount generate generate_n get get_allocator getc getchar getenv getline gets get_temporary_buffer gmtime good ignore imag in includes infinity inner_product inplace_merge insert inserter ios ios_base iostate iota isalnum isalpha iscntrl isdigit isgraph is_heap islower is_open isprint ispunct isspace isupper isxdigit iterator_category iter_swap jmp_buf key_comp labs ldexp ldiv length lexicographical_compare lexicographical_compare_3way llabs lldiv localtime log log10 longjmp lower_bound make_heap make_pair malloc max max_element max_size memchr memcpy mem_fun mem_fun_ref memmove memset merge min min_element mismatch mktime modf next_permutation none norm not1 not2 nth_element open partial_sort partial_sort_copy partial_sum partition peek perror polar pop pop_back pop_front pop_heap pow power precision prev_permutation printf ptr_fun push push_back push_front push_heap put putback putc putchar puts qsort quiet_NaN raise rand random_sample random_sample_n random_shuffle rbegin rdbuf rdstate read real realloc remove remove_copy remove_copy_if remove_if rename rend replace replace_copy replace_copy_if replace_if reserve reset resize return_temporary_buffer reverse reverse_copy rewind rfind rotate rotate_copy round_error scanf search search_n second seekg seekp setbuf set_difference setf set_intersection setjmp setlocale set_new_handler set_symmetric_difference set_union setvbuf signal signaling_NaN sin sinh sort sort_heap splice sprintf sqrt srand sscanf stable_partition stable_sort str strcat strchr strcmp strcoll strcpy strcspn strerror strftime strlen strncat strncmp strncpy strpbrk strrchr strspn strstr strtod strtof strtok strtol strtold strtoll strtoul strxfrm substr swap swap_ranges swprintf swscanf sync_with_stdio tan tanh tellg tellp tmpfile tmpnam tolower top to_string to_ulong toupper to_wstring transform unary_compose unget ungetc uninitialized_copy uninitialized_copy_n uninitialized_fill uninitialized_fill_n unique unique_copy unsetf upper_bound va_arg va_copy va_end value_comp va_start vfprintf vfwprintf vprintf vsprintf vswprintf vwprintf width wprintf write wscanf make_shared declare_reachable undeclare_reachable declare_no_pointers undeclare_no_pointers get_pointer_safety addressof allocate_shared get_deleter

if !exists('g:cpp_no_function_highlight')
    syn match es_cCustomParen transparent   "(" contains=cParen contains=cCppParen
    syn match es_cCustomFunc  "\w\+\s*(\@=" contains=cCustomParen
    hi def link es_cCustomFunc  Function
endif

" cpp definitions
syn keyword es_cStatement  new delete this friend using public protected private
syn keyword es_cType       inline virtual explicit export
syn keyword es_cType       bool wchar_t
syn keyword es_cExceptions throw try catch
syn keyword es_cOperator   operator typeid
syn keyword es_cOperator   and bitor or xor compl bitand and_eq or_eq xor_eq not not_eq
syn keyword es_cBoolean    true false

hi def link es_cppSTLconstant  Constant
hi def link es_cConstant       Constant
hi def link es_cppSTLtype      Typedef
hi def link es_cppSTLios       Function
hi def link es_cppSTLfunction  Function

hi def link es_cStatement      Statement
hi def link es_cLabel          Label
hi def link es_cConditional    Conditional
hi def link es_cRepeat         Repeat
hi def link es_cStructure      Structure
hi def link es_cStorageClass   StorageClass
hi def link es_cComment        Comment
hi def link es_cString         String
hi def link es_cDefine         Macro
hi def link es_cPreProc        PreProc
hi def link es_cType           Type
hi def link es_cExceptions     Exception
hi def link es_cOperator       Operator
hi def link es_cBoolean        Boolean
hi def link es_cInclude        Include
hi def link es_cIncluded       String
hi def link es_cPreCondit      PreProc
hi def link es_cPreConditMatch PreProc

let b:current_syntax = 'es_ctx_c'
