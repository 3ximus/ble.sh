# source script for ble.sh interactive sessions -*- mode: sh; mode: sh-bash -*-

ble-import lib/core-test

ble/test/start-section 'util' 648

# bleopt

(
  # 定義・設定・出力
  ble/test 'bleopt a=1' \
           exit=1
  ble/test 'bleopt a' \
           stdout= exit=1
  ble/test 'bleopt a:=2'
  ble/test 'bleopt a' \
           stdout="bleopt a='2'"
  ble/test '[[ $bleopt_a == 2 ]]'
  ble/test "bleopt | grep 'bleopt a='" \
           stdout="bleopt a='2'"
  ble/test 'bleopt a=3'
  ble/test 'bleopt a' \
           stdout="bleopt a='3'"

  # setter
  function bleopt/check:a { value=123; }
  ble/test 'bleopt a=4 && bleopt a'
  stdout="bleopt a='123'"
  function bleopt/check:a { false; }
  ble/test 'bleopt a=5' \
           exit=1
  ble/test 'bleopt a' \
           stdout="bleopt a='123'"

  # 複数引数
  ble/test bleopt f:=10 g:=11
  ble/test bleopt f g \
           stdout="bleopt f='10'${_ble_term_nl}bleopt g='11'"
  ble/test bleopt f=12 g=13
  ble/test bleopt f g \
           stdout="bleopt f='12'${_ble_term_nl}bleopt g='13'"

  # bleopt/declare
  ble/test bleopt/declare -v b 6
  ble/test bleopt b stdout="bleopt b='6'"
  ble/test bleopt/declare -n c 7
  ble/test bleopt c stdout="bleopt c='7'"
  ble/test bleopt d:= e:=
  ble/test bleopt/declare -v d 8
  ble/test bleopt/declare -n e 9
  ble/test bleopt d stdout="bleopt d=''"
  ble/test bleopt e stdout="bleopt e='9'"
)

# ble/test

ble/test ble/util/setexit 0   exit=0
ble/test ble/util/setexit 1   exit=1
ble/test ble/util/setexit 9   exit=9
ble/test ble/util/setexit 128 exit=128
ble/test ble/util/setexit 255 exit=255

# ble/unlocal

(
  a=1
  function f1 {
    echo g:$a
    local a=2
    echo l:$a
    ble/util/unlocal a
    echo g:$a
    a=3
  }
  ble/test 'f1; echo g:$a' \
           stdout=g:1 \
           stdout=l:2 \
           stdout=g:1 \
           stdout=g:3

  function f2 {
    echo f1:$a@f2
    local a=3
    echo f2:$a@f2
    ble/util/unlocal a
    echo f1:$a@f2
    a=$a+
  }
  function f1 {
    echo g:$a@f1
    local a=2
    echo f1:$a@f1
    f2
    echo f1:$a@f1
    ble/util/unlocal a
    echo g:$a@f1
    a=$a+
  }
  ble/test 'a=1; f1; echo g:$a@g' \
           stdout=g:1@f1 \
           stdout=f1:2@f1 \
           stdout=f1:2@f2 \
           stdout=f2:3@f2 \
           stdout=f1:2@f2 \
           stdout=f1:2+@f1 \
           stdout=g:1@f1 \
           stdout=g:1+@g
)

# ble/util/upvar, ble/util/uparr (Freddy Vulto's trick)

(
  function f1 {
    local a=1 b=2
    local result=$((a+b))
    local "$1" && ble/util/upvar "$1" "$result"
  }
  ble/test 'f1 x; ret=$x' ret=3
  ble/test 'f1 a; ret=$a' ret=3
  ble/test 'f1 result; ret=$result' ret=3

  function f2 {
    local a=1
    local -a b=(2)
    local -a result=($((a+b[0])) y z)
    local "$1" && ble/util/uparr "$1" "${result[@]}"
  }
  ble/test 'f2 x; ret="(${x[*]})"' ret='(3 y z)'
  ble/test 'f2 a; ret="(${a[*]})"' ret='(3 y z)'
  ble/test 'f2 b; ret="(${b[*]})"' ret='(3 y z)'
  ble/test 'f2 result; ret="(${result[*]})"' ret='(3 y z)'
)

# ble/util/save-vars, restore-vars

(
  VARNAMES=(name x y count data)

  function print-status {
    echo "name=$name x=$x y=$y count=$count data=(${data[*]})"
  }

  function f1 {
    local "${VARNAMES[@]}"

    name=1 x=2 y=3 count=4 data=(aa bb cc dd)
    print-status
    ble/util/save-vars save1_ "${VARNAMES[@]}"

    name=one x= y=A count=1 data=(Q)
    print-status
    ble/util/save-vars save2_ "${VARNAMES[@]}"

    ble/util/restore-vars save1_ "${VARNAMES[@]}"
    print-status

    ble/util/restore-vars save2_ "${VARNAMES[@]}"
    print-status
  }
  ble/test f1 \
           stdout='name=1 x=2 y=3 count=4 data=(aa bb cc dd)' \
           stdout='name=one x= y=A count=1 data=(Q)' \
           stdout='name=1 x=2 y=3 count=4 data=(aa bb cc dd)' \
           stdout='name=one x= y=A count=1 data=(Q)'
)

# ble/variable#get-attr

(
  declare v=1
  declare -i i=1
  export x=2
  readonly r=3
  declare -a a=()
  if ((_ble_bash>=40000)); then
    declare -A A=()
    declare -u u=a
    declare -l l=B
    declare -c c=c
  fi
  if ((_ble_bash>=40300)); then
    declare -n n=r
  fi

  ble/test 'ble/variable#get-attr v; ret=$attr' ret=
  ble/test 'ble/variable#get-attr i; ret=$attr' ret=i
  ble/test 'ble/variable#get-attr x; ret=$attr' ret=x
  ble/test 'ble/variable#get-attr r; ret=$attr' ret=r
  ble/test 'ble/variable#get-attr a; ret=$attr' ret=a
  if ((_ble_bash>=40000)); then
    ble/test 'ble/variable#get-attr u; ret=$attr' ret=u
    ble/test 'ble/variable#get-attr l; ret=$attr' ret=l
    ble/test 'ble/variable#get-attr c; ret=$attr' ret=c
    ble/test 'ble/variable#get-attr A; ret=$attr' ret=A
  fi
  # ((_ble_bash>=40300)) &&
  #   ble/test 'ble/variable#get-attr n; ret=$attr' ret=n

  ble/test 'ble/variable#has-attr i i'
  ble/test 'ble/variable#has-attr x x'
  ble/test 'ble/variable#has-attr r r'
  ble/test 'ble/variable#has-attr a a'
  ble/test 'ble/variable#has-attr v i' exit=1
  ble/test 'ble/variable#has-attr v x' exit=1
  ble/test 'ble/variable#has-attr v r' exit=1
  ble/test 'ble/variable#has-attr v a' exit=1
  if ((_ble_bash>=40000)); then
    ble/test 'ble/variable#has-attr u u'
    ble/test 'ble/variable#has-attr l l'
    ble/test 'ble/variable#has-attr c c'
    ble/test 'ble/variable#has-attr A A'
    ble/test 'ble/variable#has-attr v u' exit=1
    ble/test 'ble/variable#has-attr v l' exit=1
    ble/test 'ble/variable#has-attr v c' exit=1
    ble/test 'ble/variable#has-attr v A' exit=1
  fi
  # if ((_ble_bash>=40300)); then
  #   ble/test 'ble/variable#has-attr n n'
  #   ble/test 'ble/variable#has-attr v n' exit=1
  # fi

  ble/test 'ble/is-inttype i'
  ble/test 'ble/is-inttype v' exit=1
  ble/test 'ble/is-readonly r'
  ble/test 'ble/is-readonly v' exit=1
  if ((_ble_bash>=40000)); then
    ble/test 'ble/is-transformed u'
    ble/test 'ble/is-transformed l'
    ble/test 'ble/is-transformed c'
    ble/test 'ble/is-transformed v' exit=1
  fi
)

# _ble_array_prototype
(
  _ble_array_prototype=()
  ble/test 'echo ${#_ble_array_prototype[@]}' stdout=0
  ble/array#reserve-prototype 10
  ble/test 'echo ${#_ble_array_prototype[@]}' stdout=10
  ble/test 'x=("${_ble_array_prototype[@]::10}"); echo ${#x[@]}' stdout=10
  ble/array#reserve-prototype 3
  ble/test 'echo ${#_ble_array_prototype[@]}' stdout=10
  ble/test 'x=("${_ble_array_prototype[@]::3}"); echo ${#x[@]}' stdout=3
)

# ble/is-array
(
  declare -a a=()
  declare b=
  ble/test 'ble/is-array a'
  ble/test 'ble/is-array b' exit=1
  ble/test 'ble/is-array c' exit=1
)

# ble/array#set
(
  ble/test 'ble/array#set a; echo "${#a[@]}:(${a[*]})"' stdout='0:()'
  ble/test 'ble/array#set a Q; echo "${#a[@]}:(${a[*]})"' stdout='1:(Q)'
  ble/test 'ble/array#set a 1 2 3; echo "${#a[@]}:(${a[*]})"' stdout='3:(1 2 3)'
  ble/test 'ble/array#set a; echo "${#a[@]}:(${a[*]})"' stdout='0:()'
)

# ble/array#push
(
  declare -a a=()
  ble/array#push a
  ble/test 'echo "${#a[@]}:(${a[*]})"' stdout='0:()'
  ble/array#push a A
  ble/test 'echo "${#a[@]}:(${a[*]})"' stdout='1:(A)'
  ble/array#push a B C
  ble/test 'echo "${#a[@]}:(${a[*]})"' stdout='3:(A B C)'
  ble/array#push a
  ble/test 'echo "${#a[@]}:(${a[*]})"' stdout='3:(A B C)'
)

# ble/array#pop
(
  function result { echo "$ret:${#arr[*]}:(${arr[*]})"; }
  ble/test 'arr=()     ; ble/array#pop arr; result' stdout=':0:()'
  ble/test 'arr=(1)    ; ble/array#pop arr; result' stdout='1:0:()'
  ble/test 'arr=(1 2)  ; ble/array#pop arr; result' stdout='2:1:(1)'
  ble/test 'arr=(0 0 0); ble/array#pop arr; result' stdout='0:2:(0 0)'
  ble/test 'arr=(1 2 3); ble/array#pop arr; result' stdout='3:2:(1 2)'
  ble/test 'arr=(" a a " " b b " " c c "); ble/array#pop arr; result' \
           stdout=' c c :2:( a a   b b )'
)

# ble/array#unshift
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=()
  ble/array#unshift a
  ble/test status stdout='0:()'
  ble/array#unshift a A
  ble/test status stdout='1:(A)'
  ble/array#unshift a
  ble/test status stdout='1:(A)'
  ble/array#unshift a B
  ble/test status stdout='2:(B A)'
  ble/array#unshift a C D E
  ble/test status stdout='5:(C D E B A)'
  a=()
  ble/array#unshift a A B
  ble/test status stdout='2:(A B)'
)

# ble/array#reverse
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=(); ble/array#reverse a
  ble/test status stdout='0:()'
  a=(1); ble/array#reverse a
  ble/test status stdout='1:(1)'
  a=(xy zw); ble/array#reverse a
  ble/test status stdout='2:(zw xy)'
  a=(a 3 x); ble/array#reverse a
  ble/test status stdout='3:(x 3 a)'
  a=({1..10}) b=({10..1}); ble/array#reverse a
  ble/test status stdout="10:(${b[*]})"
  a=({1..9}) b=({9..1}); ble/array#reverse a
  ble/test status stdout="9:(${b[*]})"
)

# ble/array#insert-at
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=(); ble/array#insert-at a 0 A B C
  ble/test status stdout='3:(A B C)'
  a=(); ble/array#insert-at a 1 A B C
  ble/test status stdout='3:(A B C)'
  a=(x y z); ble/array#insert-at a 0 A
  ble/test status stdout='4:(A x y z)'
  a=(x y z); ble/array#insert-at a 1 A
  ble/test status stdout='4:(x A y z)'
  a=(x y z); ble/array#insert-at a 3 A
  ble/test status stdout='4:(x y z A)'
  a=(x y z); ble/array#insert-at a 0 A B C
  ble/test status stdout='6:(A B C x y z)'
  a=(x y z); ble/array#insert-at a 1 A B C
  ble/test status stdout='6:(x A B C y z)'
  a=(x y z); ble/array#insert-at a 3 A B C
  ble/test status stdout='6:(x y z A B C)'
  a=(x y z); ble/array#insert-at a 0
  ble/test status stdout='3:(x y z)'
  a=(x y z); ble/array#insert-at a 1
  ble/test status stdout='3:(x y z)'
  a=(x y z); ble/array#insert-at a 3
  ble/test status stdout='3:(x y z)'
)

# ble/array#insert-after
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=(hello world hello world)
  ble/array#insert-after a hello 1 2 3
  ble/test status stdout='7:(hello 1 2 3 world hello world)'
  a=(heart world hello world)
  ble/array#insert-after a hello 1 2 3
  ble/test status stdout='7:(heart world hello 1 2 3 world)'
  a=(hello world hello world)
  ble/test 'ble/array#insert-after a check 1 2 3' exit=1
  ble/test status stdout='4:(hello world hello world)'
)

# ble/array#insert-before
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=(hello world this)
  ble/array#insert-before a this with check
  ble/test status stdout='5:(hello world with check this)'
  a=(hello world this)
  ble/test 'ble/array#insert-before a haystack kick check' exit=1
  ble/test status stdout='3:(hello world this)'
)

# ble/array#remove
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=(xxx yyy xxx yyy yyy xxx fdsa fdsa)
  ble/array#remove a xxx
  ble/test status stdout='5:(yyy yyy yyy fdsa fdsa)'
  a=(aa aa aa aa aa)
  ble/array#remove a bb
  ble/test status stdout='5:(aa aa aa aa aa)'
  ble/array#remove a aa
  ble/test status stdout='0:()'
  ble/array#remove a cc
  ble/test status stdout='0:()'
)

# ble/array#index
(
  a=(hello world this hello world)
  ble/test 'ble/array#index a hello' ret=0
  a=(world hep this hello world)
  ble/test 'ble/array#index a hello' ret=3
  a=(hello world this hello world)
  ble/test 'ble/array#index a check' ret=-1
)

# ble/array#last-index
(
  a=(hello world this hello world)
  ble/test 'ble/array#last-index a hello' ret=3
  a=(world hep this hello world)
  ble/test 'ble/array#last-index a hello' ret=3
  a=(hello world this hello world)
  ble/test 'ble/array#last-index a check' ret=-1
)

# ble/array#remove-at
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  a=()
  ble/test 'ble/array#remove-at a 0; status' stdout='0:()'
  ble/test 'ble/array#remove-at a 10; status' stdout='0:()'
  a=(x y z)
  ble/test 'ble/array#remove-at a 4; status' stdout='3:(x y z)'
  ble/test 'ble/array#remove-at a 3; status' stdout='3:(x y z)'
  ble/test 'ble/array#remove-at a 1; status' stdout='2:(x z)'
  ble/test 'ble/array#remove-at a 0; status' stdout='1:(z)'
  ble/test 'ble/array#remove-at a 0; status' stdout='0:()'
  a=({a..z}) a1=({a..y}) a2=({b..y}) a3=({b..h} {j..y})
  ble/test 'ble/array#remove-at a 25; status' stdout="25:(${a1[*]})"
  ble/test 'ble/array#remove-at a 0; status' stdout="24:(${a2[*]})"
  ble/test 'ble/array#remove-at a 7; status' stdout="23:(${a3[*]})"
)

# ble/string#reserve-prototype
(
  _ble_string_prototype='        '
  ble/test 'echo ${#_ble_string_prototype}' stdout=8
  ble/string#reserve-prototype 10
  ble/test 'echo ${#_ble_string_prototype}' stdout=16
  ble/test 'x=${_ble_string_prototype::10}; echo ${#x}' stdout=10
  ble/string#reserve-prototype 3
  ble/test 'echo ${#_ble_string_prototype}' stdout=16
  ble/test 'x=${_ble_string_prototype::3}; echo ${#x}' stdout=3
  ble/string#reserve-prototype 77
  ble/test 'echo ${#_ble_string_prototype}' stdout=128
  ble/test 'x=${_ble_string_prototype::77}; echo ${#x}' stdout=77
)

# ble/string#repeat
(
  ble/test 'ble/string#repeat' ret=
  ble/test 'ble/string#repeat ""' ret=
  ble/test 'ble/string#repeat a' ret=
  ble/test 'ble/string#repeat abc' ret=
  ble/test 'ble/string#repeat "" ""' ret=
  ble/test 'ble/string#repeat a ""' ret=
  ble/test 'ble/string#repeat abc ""' ret=
  ble/test 'ble/string#repeat "" 0' ret=
  ble/test 'ble/string#repeat a 0' ret=
  ble/test 'ble/string#repeat abc 0' ret=
  ble/test 'ble/string#repeat "" 1' ret=
  ble/test 'ble/string#repeat "" 10' ret=

  ble/test 'ble/string#repeat a 1' ret=a
  ble/test 'ble/string#repeat a 2' ret=aa
  ble/test 'ble/string#repeat a 5' ret=aaaaa
  ble/test 'ble/string#repeat abc 1' ret=abc
  ble/test 'ble/string#repeat abc 2' ret=abcabc
  ble/test 'ble/string#repeat abc 5' ret=abcabcabcabcabc
  ble/test 'ble/string#repeat ";&|<>" 5' ret=';&|<>;&|<>;&|<>;&|<>;&|<>'
)

# ble/string#common-prefix
(
  ble/test 'ble/string#common-prefix' ret=
  ble/test 'ble/string#common-prefix ""' ret=
  ble/test 'ble/string#common-prefix a' ret=
  ble/test 'ble/string#common-prefix "" ""' ret=
  ble/test 'ble/string#common-prefix a ""' ret=
  ble/test 'ble/string#common-prefix a b' ret=
  ble/test 'ble/string#common-prefix a a' ret=a
  ble/test 'ble/string#common-prefix abc abc' ret=abc
  ble/test 'ble/string#common-prefix abc aaa' ret=a
  ble/test 'ble/string#common-prefix abc ccc' ret=
  ble/test 'ble/string#common-prefix abc xyz' ret=
)

# ble/string#common-suffix
(
  ble/test 'ble/string#common-suffix' ret=
  ble/test 'ble/string#common-suffix ""' ret=
  ble/test 'ble/string#common-suffix a' ret=
  ble/test 'ble/string#common-suffix "" ""' ret=
  ble/test 'ble/string#common-suffix a ""' ret=
  ble/test 'ble/string#common-suffix a b' ret=
  ble/test 'ble/string#common-suffix a a' ret=a
  ble/test 'ble/string#common-suffix abc abc' ret=abc
  ble/test 'ble/string#common-suffix abc aaa' ret=
  ble/test 'ble/string#common-suffix abc ccc' ret=c
  ble/test 'ble/string#common-suffix abc xyz' ret=
)

# ble/string#split
(
  function status { echo "${#a[@]}:(""${a[*]}"")"; }
  nl=$'\n'
  ble/test 'ble/string#split a , ""  ; status' stdout='1:()'
  ble/test 'ble/string#split a , "1"  ; status' stdout='1:(1)'
  ble/test 'ble/string#split a , ","  ; status' stdout='2:( )'
  ble/test 'ble/string#split a , "1,"  ; status' stdout='2:(1 )'
  ble/test 'ble/string#split a , ",2"  ; status' stdout='2:( 2)'
  ble/test 'ble/string#split a , "1,,3"  ; status' stdout='3:(1  3)'
  ble/test 'ble/string#split a , "1,2,3"  ; status' stdout='3:(1 2 3)'
  ble/test 'ble/string#split a " " "1 2 3"; status' stdout='3:(1 2 3)'
  ble/test 'ble/string#split a " " "1	2	3"; status' stdout='1:(1	2	3)'
  ble/test 'ble/string#split a " " "1'"$nl"'2'"$nl"'3"; status' stdout="1:(1${nl}2${nl}3)"
)

# ble/string#split-words
(
  function status { echo "${#a[@]}:(${a[*]})"; }
  nl=$'\n' ht=$'\t'
  ble/test 'ble/string#split-words a ""  ; status' stdout='0:()'
  ble/test 'ble/string#split-words a "1"  ; status' stdout='1:(1)'
  ble/test 'ble/string#split-words a " "  ; status' stdout='0:()'
  ble/test 'ble/string#split-words a "1 "  ; status' stdout='1:(1)'
  ble/test 'ble/string#split-words a " 2"  ; status' stdout='1:(2)'
  ble/test 'ble/string#split-words a "1  3"  ; status' stdout='2:(1 3)'
  ble/test 'ble/string#split-words a "1 2 3"; status' stdout='3:(1 2 3)'
  ble/test 'ble/string#split-words a "  1'"$ht"'2'"$ht"'3  "; status' stdout='3:(1 2 3)'
  ble/test 'ble/string#split-words a "  1'"$nl"'2'"$nl"'3  "; status' stdout='3:(1 2 3)'
)

# ble/string#split-lines
(
  function status { echo "${#a[@]}:(""${a[*]}"")"; }
  nl=$'\n' ht=$'\t'
  ble/test 'ble/string#split-lines a ""  ; status' stdout='1:()'
  ble/test 'ble/string#split-lines a "1"  ; status' stdout='1:(1)'
  ble/test 'ble/string#split-lines a "'"$nl"'"  ; status' stdout='2:( )'
  ble/test 'ble/string#split-lines a "1'"$nl"'"  ; status' stdout='2:(1 )'
  ble/test 'ble/string#split-lines a "'"$nl"'2"  ; status' stdout='2:( 2)'
  ble/test 'ble/string#split-lines a "1'"$nl$nl"'3"  ; status' stdout='3:(1  3)'
  ble/test 'ble/string#split-lines a "1'"$nl"'2'"$nl"'3"; status' stdout='3:(1 2 3)'
  ble/test 'ble/string#split-lines a "1'"$ht"'2'"$ht"'3"; status' stdout="1:(1${ht}2${ht}3)"
  ble/test 'ble/string#split-lines a "1 2 3"; status' stdout="1:(1 2 3)"
)

# ble/string#count-char
(
  #UB: ble/test 'ble/string#count-char hello' ret=5
  ble/test 'ble/string#count-char hello a' ret=0
  ble/test 'ble/string#count-char hello あ' ret=0
  ble/test 'ble/string#count-char hello e' ret=1
  ble/test 'ble/string#count-char hello l' ret=2
  ble/test 'ble/string#count-char hello olh' ret=4
  ble/test 'ble/string#count-char hello hello' ret=5
  ble/test 'ble/string#count-char "" a' ret=0
  ble/test 'ble/string#count-char "" ab' ret=0
)

# ble/string#count-string
(
  ble/test 'ble/string#count-string hello a' ret=0
  ble/test 'ble/string#count-string hello あ' ret=0
  ble/test 'ble/string#count-string hello ee' ret=0
  ble/test 'ble/string#count-string hello e' ret=1
  ble/test 'ble/string#count-string hello l' ret=2
  ble/test 'ble/string#count-string hello ll' ret=1
  ble/test 'ble/string#count-string hello hello' ret=1
  ble/test 'ble/string#count-string "" a' ret=0
  ble/test 'ble/string#count-string "" ab' ret=0
  ble/test 'ble/string#count-string ababababa aba' ret=2
)

# ble/string#index-of
(
  ble/test 'ble/string#index-of hello a' ret=-1
  ble/test 'ble/string#index-of hello あ' ret=-1
  ble/test 'ble/string#index-of hello ee' ret=-1
  ble/test 'ble/string#index-of hello e' ret=1
  ble/test 'ble/string#index-of hello l' ret=2
  ble/test 'ble/string#index-of hello ll' ret=2
  ble/test 'ble/string#index-of hello hello' ret=0
  ble/test 'ble/string#index-of "" a' ret=-1
  ble/test 'ble/string#index-of "" ab' ret=-1
  ble/test 'ble/string#index-of ababababa aba' ret=0
)

# ble/string#last-index-of
(
  ble/test 'ble/string#last-index-of hello a' ret=-1
  ble/test 'ble/string#last-index-of hello あ' ret=-1
  ble/test 'ble/string#last-index-of hello ee' ret=-1
  ble/test 'ble/string#last-index-of hello e' ret=1
  ble/test 'ble/string#last-index-of hello l' ret=3
  ble/test 'ble/string#last-index-of hello ll' ret=2
  ble/test 'ble/string#last-index-of hello hello' ret=0
  ble/test 'ble/string#last-index-of "" a' ret=-1
  ble/test 'ble/string#last-index-of "" ab' ret=-1
  ble/test 'ble/string#last-index-of ababababa aba' ret=6
)

# ble/string#{toggle-case,tolower,toupper,capitalize}
(
  ble/test 'ble/string#toggle-case' ret=
  ble/test 'ble/string#tolower    ' ret=
  ble/test 'ble/string#toupper    ' ret=
  ble/test 'ble/string#capitalize ' ret=
  ble/test 'ble/string#toggle-case ""' ret=
  ble/test 'ble/string#tolower     ""' ret=
  ble/test 'ble/string#toupper     ""' ret=
  ble/test 'ble/string#capitalize  ""' ret=
  ble/test 'ble/string#toggle-case a' ret=A
  ble/test 'ble/string#tolower     a' ret=a
  ble/test 'ble/string#toupper     a' ret=A
  ble/test 'ble/string#capitalize  a' ret=A
  ble/test 'ble/string#toggle-case あ' ret=あ
  ble/test 'ble/string#tolower     あ' ret=あ
  ble/test 'ble/string#toupper     あ' ret=あ
  ble/test 'ble/string#capitalize  あ' ret=あ
  ble/test 'ble/string#toggle-case +' ret=+
  ble/test 'ble/string#tolower     +' ret=+
  ble/test 'ble/string#toupper     +' ret=+
  ble/test 'ble/string#capitalize  +' ret=+
  ble/test 'ble/string#toggle-case abc' ret=ABC
  ble/test 'ble/string#tolower     abc' ret=abc
  ble/test 'ble/string#toupper     abc' ret=ABC
  ble/test 'ble/string#capitalize  abc' ret=Abc
  ble/test 'ble/string#toggle-case ABC' ret=abc
  ble/test 'ble/string#tolower     ABC' ret=abc
  ble/test 'ble/string#toupper     ABC' ret=ABC
  ble/test 'ble/string#capitalize  ABC' ret=Abc
  ble/test 'ble/string#toggle-case aBc' ret=AbC
  ble/test 'ble/string#tolower     aBc' ret=abc
  ble/test 'ble/string#toupper     aBc' ret=ABC
  ble/test 'ble/string#capitalize  aBc' ret=Abc
  ble/test 'ble/string#toggle-case +aBc' ret=+AbC
  ble/test 'ble/string#tolower     +aBc' ret=+abc
  ble/test 'ble/string#toupper     +aBc' ret=+ABC
  ble/test 'ble/string#capitalize  +aBc' ret=+Abc
  ble/test 'ble/string#capitalize  "hello world"' ret='Hello World'
)

# ble/string#{trim,ltrim,rtrim}
(
  ble/test 'ble/string#trim ' ret=
  ble/test 'ble/string#ltrim' ret=
  ble/test 'ble/string#rtrim' ret=
  ble/test 'ble/string#trim  ""' ret=
  ble/test 'ble/string#ltrim ""' ret=
  ble/test 'ble/string#rtrim ""' ret=
  ble/test 'ble/string#trim  "a"' ret=a
  ble/test 'ble/string#ltrim "a"' ret=a
  ble/test 'ble/string#rtrim "a"' ret=a
  ble/test 'ble/string#trim  " a "' ret=a
  ble/test 'ble/string#ltrim " a "' ret='a '
  ble/test 'ble/string#rtrim " a "' ret=' a'
  ble/test 'ble/string#trim  " a b "' ret='a b'
  ble/test 'ble/string#ltrim " a b "' ret='a b '
  ble/test 'ble/string#rtrim " a b "' ret=' a b'
  ble/test 'ble/string#trim  "abc"' ret='abc'
  ble/test 'ble/string#ltrim "abc"' ret='abc'
  ble/test 'ble/string#rtrim "abc"' ret='abc'
  ble/test 'ble/string#trim  "  abc  "' ret='abc'
  ble/test 'ble/string#ltrim "  abc  "' ret='abc  '
  ble/test 'ble/string#rtrim "  abc  "' ret='  abc'
  for pad in $' \t\n \t\n' $'\t\t\t' $'\n\n\n'; do
    ble/test 'ble/string#trim  "'"$pad"'abc'"$pad"'"' ret='abc'
    ble/test 'ble/string#ltrim "'"$pad"'abc'"$pad"'"' ret="abc${pad}"
    ble/test 'ble/string#rtrim "'"$pad"'abc'"$pad"'"' ret="${pad}abc"
  done
)

# ble/string#escape-characters
(
  ble/test 'ble/string#escape-characters hello' ret=hello
  ble/test 'ble/string#escape-characters hello ""' ret=hello
  ble/test 'ble/string#escape-characters hello xyz' ret=hello
  ble/test 'ble/string#escape-characters hello el' ret='h\e\l\lo'
  ble/test 'ble/string#escape-characters hello hl XY' ret='\Xe\Y\Yo'

  # regex
  ble/test 'ble/string#escape-for-sed-regex      "A\.[*?+|^\$(){}/"' \
           ret='A\\\.\[\*?+|\^\$(){}\/'
  ble/test 'ble/string#escape-for-awk-regex      "A\.[*?+|^\$(){}/"' \
           ret='A\\\.\[\*\?\+\|\^\$\(\)\{\}\/'
  ble/test 'ble/string#escape-for-extended-regex "A\.[*?+|^\$(){}/"' \
           ret='A\\\.\[\*\?\+\|\^\$\(\)\{\}/'

  # bash
  ble/test 'ble/string#escape-for-bash-glob "A\*?[("' ret='A\\\*\?\[\('
  ble/test 'ble/string#escape-for-bash-single-quote "A'\''B"' ret="A'\''B"
  ble/test 'ble/string#escape-for-bash-double-quote "hello \$ \` \\ ! world"' ret='hello \$ \` \\ "\!" world'
  input=A$'\\\a\b\e\f\n\r\t\v'\'B output=A'\\\a\b\e\f\n\r\t\v\'\'B
  ble/test 'ble/string#escape-for-bash-escape-string "$input"' ret="$output"
  ble/test 'ble/string#escape-for-bash-specialchars "[hello] (world) {this,is} <test>"' \
           ret='\[hello\]\ \(world\)\ {this,is}\ \<test\>'
  ble/test 'ble/string#escape-for-bash-specialchars "[hello] (world) {this,is} <test>" b' \
           ret='\[hello\]\ \(world\)\ \{this\,is\}\ \<test\>'
  ble/test 'ble/string#escape-for-bash-specialchars "a=b:c:d" c' \
           ret='a\=b\:c\:d'
)

# ble/string#quote-command, ble/util/print-quoted-command
(
  ble/test 'ble/string#quote-command' ret=
  ble/test 'ble/string#quote-command echo' ret='echo'
  ble/test 'ble/string#quote-command echo hello world' ret="echo 'hello' 'world'"
  ble/test 'ble/string#quote-command echo "hello world"' ret="echo 'hello world'"
  ble/test 'ble/string#quote-command echo "'\''test'\''"' ret="echo ''\''test'\'''"
  ble/test 'ble/string#quote-command echo "" "" ""' ret="echo '' '' ''"
  ble/test 'ble/string#quote-command echo a{1..4}' ret="echo 'a1' 'a2' 'a3' 'a4'"

  ble/test 'ble/util/print-quoted-command' stdout=
  ble/test 'ble/util/print-quoted-command echo' stdout='echo'
  ble/test 'ble/util/print-quoted-command echo hello world' stdout="echo 'hello' 'world'"
  ble/test 'ble/util/print-quoted-command echo "hello world"' stdout="echo 'hello world'"
  ble/test 'ble/util/print-quoted-command echo "'\''test'\''"' stdout="echo ''\''test'\'''"
  ble/test 'ble/util/print-quoted-command echo "" "" ""' stdout="echo '' '' ''"
  ble/test 'ble/util/print-quoted-command echo a{1..4}' stdout="echo 'a1' 'a2' 'a3' 'a4'"
)

# ble/string#create-unicode-progress-bar
(
  ble/test 'ble/string#create-unicode-progress-bar  0 24 3' ret='   '
  ble/test 'ble/string#create-unicode-progress-bar  1 24 3' ret='▏  '
  ble/test 'ble/string#create-unicode-progress-bar  2 24 3' ret='▎  '
  ble/test 'ble/string#create-unicode-progress-bar  3 24 3' ret='▍  '
  ble/test 'ble/string#create-unicode-progress-bar  4 24 3' ret='▌  '
  ble/test 'ble/string#create-unicode-progress-bar  5 24 3' ret='▋  '
  ble/test 'ble/string#create-unicode-progress-bar  6 24 3' ret='▊  '
  ble/test 'ble/string#create-unicode-progress-bar  7 24 3' ret='▉  '
  ble/test 'ble/string#create-unicode-progress-bar  8 24 3' ret='█  '
  ble/test 'ble/string#create-unicode-progress-bar  9 24 3' ret='█▏ '
  ble/test 'ble/string#create-unicode-progress-bar 15 24 3' ret='█▉ '
  ble/test 'ble/string#create-unicode-progress-bar 16 24 3' ret='██ '
  ble/test 'ble/string#create-unicode-progress-bar 17 24 3' ret='██▏'
  ble/test 'ble/string#create-unicode-progress-bar 24 24 3' ret='███'
  ble/test 'ble/string#create-unicode-progress-bar  0 24 4 unlimited' ret=$'█   '
  ble/test 'ble/string#create-unicode-progress-bar  1 24 4 unlimited' ret=$'\e[7m▏\e[27m▏  '
  ble/test 'ble/string#create-unicode-progress-bar  2 24 4 unlimited' ret=$'\e[7m▎\e[27m▎  '
  ble/test 'ble/string#create-unicode-progress-bar  3 24 4 unlimited' ret=$'\e[7m▍\e[27m▍  '
  ble/test 'ble/string#create-unicode-progress-bar  4 24 4 unlimited' ret=$'\e[7m▌\e[27m▌  '
  ble/test 'ble/string#create-unicode-progress-bar  5 24 4 unlimited' ret=$'\e[7m▋\e[27m▋  '
  ble/test 'ble/string#create-unicode-progress-bar  6 24 4 unlimited' ret=$'\e[7m▊\e[27m▊  '
  ble/test 'ble/string#create-unicode-progress-bar  7 24 4 unlimited' ret=$'\e[7m▉\e[27m▉  '
  ble/test 'ble/string#create-unicode-progress-bar  8 24 4 unlimited' ret=$' █  '
  ble/test 'ble/string#create-unicode-progress-bar  9 24 4 unlimited' ret=$' \e[7m▏\e[27m▏ '
  ble/test 'ble/string#create-unicode-progress-bar 15 24 4 unlimited' ret=$' \e[7m▉\e[27m▉ '
  ble/test 'ble/string#create-unicode-progress-bar 16 24 4 unlimited' ret=$'  █ '
  ble/test 'ble/string#create-unicode-progress-bar 17 24 4 unlimited' ret=$'  \e[7m▏\e[27m▏'
  ble/test 'ble/string#create-unicode-progress-bar 24 24 4 unlimited' ret=$'█   '
)

# ble/util/strlen
(
  ble/test 'ble/util/strlen' ret=0
  ble/test 'ble/util/strlen ""' ret=0
  ble/test 'ble/util/strlen a' ret=1
  ble/test 'ble/util/strlen abc' ret=3
  ble/test 'ble/util/strlen α' ret=2
  ble/test 'ble/util/strlen αβγ' ret=6
  ble/test 'ble/util/strlen あ' ret=3
  ble/test 'ble/util/strlen あいう' ret=9
  ble/test 'ble/util/strlen aα' ret=3
  ble/test 'ble/util/strlen aαあ' ret=6
)

# ble/util/substr
(
  ble/test 'ble/util/substr' ret=
  ble/test 'ble/util/substr ""' ret=
  ble/test 'ble/util/substr a' ret=
  ble/test 'ble/util/substr "" 0' ret=
  ble/test 'ble/util/substr "" 1' ret=
  ble/test 'ble/util/substr a 0' ret=
  ble/test 'ble/util/substr a 1' ret=
  ble/test 'ble/util/substr a 2' ret=
  ble/test 'ble/util/substr "" 0 0' ret=
  ble/test 'ble/util/substr "" 0 1' ret=
  ble/test 'ble/util/substr "" 1 1' ret=
  ble/test 'ble/util/substr a 0 0' ret=
  ble/test 'ble/util/substr a 1 0' ret=
  ble/test 'ble/util/substr a 0 1' ret=a
  ble/test 'ble/util/substr a 1 1' ret=
  ble/test 'ble/util/substr abc 1 0' ret=
  ble/test 'ble/util/substr abc 1 1' ret=b
  ble/test 'ble/util/substr abc 1 2' ret=bc
  ble/test 'ble/util/substr abc 0 0' ret=
  ble/test 'ble/util/substr abc 0 1' ret=a
  ble/test 'ble/util/substr abc 0 3' ret=abc
  ble/test 'ble/util/substr abc 0 4' ret=abc
  ble/test 'ble/util/substr abc 3 0' ret=
  ble/test 'ble/util/substr abc 3 1' ret=
  ble/test 'ble/util/substr abc 4 0' ret=
  ble/test 'ble/util/substr abc 4 1' ret=

  ble/test 'ble/util/substr あいう 0 3' ret=あ
  ble/test 'ble/util/substr あいう 3 6' ret=いう
  ble/test 'ble/util/substr あいう 0 1' ret=$'\xe3'
  ble/test 'ble/util/substr あいう 1 2' ret=$'\x81\x82'
  ble/test 'ble/util/substr あいう 1 4' ret=$'\x81\x82\xe3\x81'
  ble/test 'ble/util/substr あいう 7 5' ret=$'\x81\x86'
)

# ble/path#remove{,-glob}
(
  for cmd in ble/path#{remove,remove-glob}; do
    ble/test code:'ret=; '$cmd' ret' ret=
    ble/test code:'ret=; '$cmd' ret ""' ret=
    ble/test code:'ret=a; '$cmd' ret ""' ret=a
    ble/test code:'ret=a; '$cmd' ret a' ret=
    ble/test code:'ret=a; '$cmd' ret b' ret=a
    ble/test code:'ret=a:a:a; '$cmd' ret a' ret=
    ble/test code:'ret=aa; '$cmd' ret a' ret=aa
    ble/test code:'ret=xyz:abc; '$cmd' ret ""' ret=xyz:abc
    ble/test code:'ret=xyz:abc; '$cmd' ret xyz' ret=abc
    ble/test code:'ret=xyz:abc; '$cmd' ret abc' ret=xyz
    ble/test code:'ret=xyz:abc:tuv; '$cmd' ret xyz' ret=abc:tuv
    ble/test code:'ret=xyz:abc:tuv; '$cmd' ret abc' ret=xyz:tuv
    ble/test code:'ret=xyz:abc:tuv; '$cmd' ret tuv' ret=xyz:abc
    ble/test code:'ret=xyz:xyz; '$cmd' ret xyz' ret=
    ble/test code:'ret=xyz:abc:xyz; '$cmd' ret xyz' ret=abc
    ble/test code:'ret=xyz:abc:xyz; '$cmd' ret abc' ret=xyz:xyz
    ble/test code:'ret=xyz:xyz:xyz; '$cmd' ret xyz' ret=
  done

  ble/test code:'ret=a; ble/path#remove ret \?' ret=a
  ble/test code:'ret=aa; ble/path#remove ret \?' ret=aa
  ble/test code:'ret=a:b; ble/path#remove ret \?' ret=a:b
  ble/test code:'ret=a:b:c; ble/path#remove ret \?' ret=a:b:c
  ble/test code:'ret=aa:b:cc; ble/path#remove ret \?' ret=aa:b:cc
  ble/test code:'ret=stdX:stdY:usrZ; ble/path#remove ret "std[a-zX-Z]"' ret=stdX:stdY:usrZ
  ble/test code:'ret=stdX:usrZ:stdY; ble/path#remove ret "std[a-zX-Z]"' ret=stdX:usrZ:stdY
  ble/test code:'ret=usrZ:stdX:stdY; ble/path#remove ret "std[a-zX-Z]"' ret=usrZ:stdX:stdY

  ble/test code:'ret=a; ble/path#remove-glob ret \?' ret=
  ble/test code:'ret=aa; ble/path#remove-glob ret \?' ret=aa
  ble/test code:'ret=a:b; ble/path#remove-glob ret \?' ret=
  ble/test code:'ret=a:b:c; ble/path#remove-glob ret \?' ret=
  ble/test code:'ret=aa:b:cc; ble/path#remove-glob ret \?' ret=aa:cc
  ble/test code:'ret=stdX:stdY:usrZ; ble/path#remove-glob ret "std[a-zX-Z]"' ret=usrZ
  ble/test code:'ret=stdX:usrZ:stdY; ble/path#remove-glob ret "std[a-zX-Z]"' ret=usrZ
  ble/test code:'ret=usrZ:stdX:stdY; ble/path#remove-glob ret "std[a-zX-Z]"' ret=usrZ
)


# blehook
(
  # declare hook
  blehook/declare FOO
  ble/test 'blehook FOO' stdout='blehook FOO='
  ble/test 'blehook/has-hook FOO' exit=1

  # add/remove hook
  blehook FOO+='echo hello'
  ble/test 'blehook FOO' \
           stdout="blehook FOO+='echo hello'"
  ble/test 'blehook/has-hook FOO'
  blehook FOO+='echo world'
  ble/test 'blehook FOO' \
           stdout="blehook FOO+='echo hello'" \
           stdout="blehook FOO+='echo world'"
  ble/test 'blehook/has-hook FOO'
  blehook FOO-='echo hello'
  ble/test 'blehook FOO' \
           stdout="blehook FOO+='echo world'"
  ble/test 'blehook/has-hook FOO'
  blehook FOO-='echo world'
  ble/test 'blehook FOO' \
           stdout='blehook FOO='
  ble/test 'blehook/has-hook FOO' exit=1

  # reset hook
  blehook FOO+='echo hello'
  blehook FOO+='echo world'
  blehook FOO='echo empty'
  ble/test 'blehook FOO' \
           stdout="blehook FOO+='echo empty'"
  ble/test 'blehook/has-hook FOO'

  # clear hook
  blehook FOO+='echo hello'
  blehook FOO+='echo world'
  blehook FOO=
  ble/test 'blehook FOO' \
           stdout='blehook FOO='
  ble/test 'blehook/has-hook FOO' exit=1

  # invoke hook
  blehook FOO+='echo hello'
  blehook FOO+='echo empty'
  blehook FOO+='echo world'
  ble/test 'blehook/invoke FOO' \
           stdout=hello \
           stdout=empty \
           stdout=world
  blehook FOO='echo A$?'
  blehook FOO+='echo B$?'
  blehook FOO+='echo C$?'
  ble/test 'ble/util/setexit 123; blehook/invoke FOO' \
           stdout=A123 \
           stdout=B123 \
           stdout=C123

  # eval-after-load
  blehook/declare bar_load
  blehook bar_load='echo bar_load'
  ble/test 'blehook/eval-after-load bar "echo yes"' stdout=
  ble/test 'blehook/invoke bar_load' \
           stdout=bar_load \
           stdout=yes
  ble/test 'blehook/eval-after-load bar "echo next"' stdout=next
)

# ble/builtin/trap
(
  # 0 / EXIT (special trap)
  ble/builtin/trap 'echo TRAPEXIT1' 0
  ble/test 'ble/builtin/trap/invoke 0' stdout=TRAPEXIT1
  ble/test 'ble/builtin/trap/invoke EXIT' stdout=TRAPEXIT1
  ble/builtin/trap 0
  ble/test 'ble/builtin/trap/invoke 0' stdout=

  ble/builtin/trap 'echo TRAPEXIT2' EXIT
  ble/test 'ble/builtin/trap/invoke 0' stdout=TRAPEXIT2
  ble/test 'ble/builtin/trap/invoke EXIT' stdout=TRAPEXIT2
  ble/builtin/trap EXIT
  ble/test 'ble/builtin/trap/invoke 0' stdout=

  # 1 / HUP / SIGHUP (signal trap)
  ble/builtin/trap 'echo TRAPHUP1' 1
  ble/test 'ble/builtin/trap/invoke 1' stdout=TRAPHUP1
  ble/test 'ble/builtin/trap/invoke HUP' stdout=TRAPHUP1
  ble/test 'ble/builtin/trap/invoke SIGHUP' stdout=TRAPHUP1
  ble/builtin/trap 1
  ble/test 'ble/builtin/trap/invoke 1' stdout=

  ble/builtin/trap 'echo TRAPHUP2' HUP
  ble/test 'ble/builtin/trap/invoke 1' stdout=TRAPHUP2
  ble/test 'ble/builtin/trap/invoke HUP' stdout=TRAPHUP2
  ble/test 'ble/builtin/trap/invoke SIGHUP' stdout=TRAPHUP2
  ble/builtin/trap HUP
  ble/test 'ble/builtin/trap/invoke HUP' stdout=

  ble/builtin/trap 'echo TRAPHUP3' SIGHUP
  ble/test 'ble/builtin/trap/invoke 1' stdout=TRAPHUP3
  ble/test 'ble/builtin/trap/invoke HUP' stdout=TRAPHUP3
  ble/test 'ble/builtin/trap/invoke SIGHUP' stdout=TRAPHUP3
  ble/builtin/trap SIGHUP
  ble/test 'ble/builtin/trap/invoke HUP' stdout=

  # 9999 / CUSTOM (custom trap)
  ble/builtin/trap/.register 9999 CUSTOM
  ble/builtin/trap/reserve CUSTOM
  ble/builtin/trap 'echo custom trap' CUSTOM
  ble/test 'ble/builtin/trap/invoke CUSTOM' stdout='custom trap'
  function ble/builtin/trap:CUSTOM { echo "__set_handler__ ($2) $1"; }
  ble/test 'ble/builtin/trap "echo hello world" CUSTOM' \
           stdout='__set_handler__ (CUSTOM) echo hello world'
  ble/test 'ble/builtin/trap/invoke CUSTOM' stdout='hello world'
)

# ble/util/{readfile,mapfile,assign,assign-array}
(
  # readfile
  ble/test 'ble/util/readfile ret <(echo hello)' \
           ret=hello$'\n'
  ble/test 'ble/util/readfile ret <(echo hello; echo world)' \
           ret=hello$'\n'world$'\n'
  ble/test 'ble/util/readfile ret <(echo hello; echo -n world)' \
           ret=hello$'\n'world
  ble/test 'ble/util/readfile ret <(:)' ret=

  # mapfile
  function status { echo "${#a[*]}:(""${a[*]}"")"; }
  ble/test "ble/util/mapfile a < <(echo hello); status" stdout='1:(hello)'
  ble/test "ble/util/mapfile a < <(echo -n hello); status" stdout='1:(hello)'
  ble/test "ble/util/mapfile a < <(echo hello; echo world); status" stdout='2:(hello world)'
  ble/test "ble/util/mapfile a < <(echo hello; echo -n world); status" stdout='2:(hello world)'
  ble/test "ble/util/mapfile a < <(printf '%s\n' h1 h2 h3 h4); status" stdout='4:(h1 h2 h3 h4)'
  ble/test "ble/util/mapfile a < <(:); status" stdout='0:()'
  ble/test "ble/util/mapfile a < <(echo); status" stdout='1:()'
  ble/test "ble/util/mapfile a < <(echo;echo); status" stdout='2:( )'
  ble/test "ble/util/mapfile a < <(echo a;echo;echo b); status" stdout='3:(a  b)'

  # assign
  nl=$'\n'
  ble/test 'ble/util/assign ret ""' ret=
  ble/test 'ble/util/assign ret ":"' ret=
  ble/test 'ble/util/assign ret "echo"' ret=
  ble/test 'ble/util/assign ret "echo hello"' ret=hello
  ble/test 'ble/util/assign ret "seq 5"' ret="1${nl}2${nl}3${nl}4${nl}5"
  function f1 { echo stdout; echo stderr >&2; }
  function nested-assign {
    ble/util/assign err 'ble/util/assign out f1 2>&1'
    echo "out=$out err=$err"
  }
  ble/test nested-assign stdout='out=stdout err=stderr'

  # assign-array
  ble/test 'ble/util/assign-array a :; status' stdout='0:()'
  ble/test 'ble/util/assign-array a echo; status' stdout='1:()'
  ble/test 'ble/util/assign-array a "echo hello"; status' stdout='1:(hello)'
  ble/test 'ble/util/assign-array a "seq 5"; status' stdout='5:(1 2 3 4 5)'
  ble/test 'ble/util/assign-array a "echo; echo; echo"; status' stdout='3:(  )'
  ble/test 'ble/util/assign-array a "echo 1; echo; echo 2"; status' stdout='3:(1  2)'
)

# ble/is-function
(
  var=variable
  alias ali=fun
  function fun { echo yes "$*"; }
  function ble/fun { echo yes "$*"; return 99; }
  function ble/fun:type { echo yes "$*"; return 100; }
  function ble/fun#meth { echo yes "$*"; return 101; }

  ble/test 'ble/is-function' exit=1
  ble/test 'ble/is-function ""' exit=1

  ble/test 'ble/is-function fun'
  ble/test 'ble/is-function ble/fun'
  ble/test 'ble/is-function ble/fun:type'
  ble/test 'ble/is-function ble/fun#meth'

  ble/test 'ble/is-function fun1' exit=1
  ble/test 'ble/is-function ble/fun1' exit=1
  ble/test 'ble/is-function ble/fun1:type' exit=1
  ble/test 'ble/is-function ble/fun1#meth' exit=1

  ble/test 'ble/is-function ali' exit=1
  ble/test 'ble/is-function var' exit=1
  ble/test 'ble/is-function compgen' exit=1
  ble/test 'ble/is-function declare' exit=1
  ble/test 'ble/is-function mkfifo' exit=1

  function compgen { :; }
  function declare { :; }
  function mkfifo { :; }
  ble/test 'ble/is-function compgen'
  ble/test 'ble/is-function declare'
  ble/test 'ble/is-function mkfifo'

  # ble/function#try
  ble/test 'ble/function#try fun 1 2 3' stdout='yes 1 2 3'
  ble/test 'ble/function#try ble/fun 1 2 3' stdout='yes 1 2 3' exit=99
  ble/test 'ble/function#try ble/fun:type 1 2 3' stdout='yes 1 2 3' exit=100
  ble/test 'ble/function#try ble/fun#meth 1 2 3' stdout='yes 1 2 3' exit=101
  ble/test 'ble/function#try fun1 1 2 3' stdout= exit=127
  ble/test 'ble/function#try ble/fun1 1 2 3' stdout= exit=127
  ble/test 'ble/function#try ble/fun1:type 1 2 3' stdout= exit=127
  ble/test 'ble/function#try ble/fun1#meth 1 2 3' stdout= exit=127
)

# ble/function#advice
(
  function f1 { echo original $*; }

  ble/test f1 stdout='original'
  ble/function#advice before f1 'echo pre'
  ble/test f1 stdout={pre,original}
  ble/function#advice after f1 'echo post'
  ble/test f1 stdout={pre,original,post}
  ble/function#advice before f1 'echo A'
  ble/test f1 stdout={A,original,post}
  ble/function#advice after f1 'echo B'
  ble/test f1 stdout={A,original,B}
  ble/function#advice around f1 'echo [; ble/function#advice/do; echo ]'
  ble/test f1 stdout={A,[,original,],B}

  ble/function#advice around f1 '
    ADVICE_WORDS[1]=quick
    echo [; ble/function#advice/do; echo ]
    ADVICE_EXIT=99'
  ble/test f1 stdout={A,[,'original quick',],B} exit=99
  
  ble/function#advice remove f1
  ble/test f1 stdout='original' exit=0
  ble/test 'f1 1' stdout='original 1' exit=0
)

# ble/function#{push,pop}
(
  ble/test 'echo 1 2 3' stdout='1 2 3'
  ble/test 'ble/is-function echo' exit=1
  ble/function#push echo 'builtin echo "[$*]"'
  ble/test 'ble/is-function echo'
  ble/test 'echo 1 2 3' stdout='[1 2 3]'
  ble/function#push echo 'builtin echo "($*)"'
  ble/test 'echo 1 2 3' stdout='(1 2 3)'
  ble/function#push echo 'builtin echo A; ble/function#push/call-top "$@"; builtin echo Z'
  ble/test 'echo 1 2 3' stdout={A,'(1 2 3)',Z}
  ble/function#push echo 'builtin echo [; ble/function#push/call-top "$@"; builtin echo ]'
  ble/test 'echo 1 2 3' stdout={[,A,'(1 2 3)',Z,]}

  ble/test 'ble/function#pop echo'
  ble/test 'echo 1 2 3' stdout={A,'(1 2 3)',Z}
  ble/function#pop echo
  ble/test 'echo 1 2 3' stdout='(1 2 3)'
  ble/function#pop echo
  ble/test 'echo 1 2 3' stdout='[1 2 3]'
  ble/test 'ble/is-function echo'
  ble/test 'ble/function#pop echo'
  ble/test 'ble/is-function echo' exit=1
  ble/test 'echo 1 2 3' stdout='1 2 3'
  ble/test 'ble/function#pop echo' exit=1
  ble/test 'echo 1 2 3' stdout='1 2 3'
)

# ble/util/set
(
  ble/test 'ble/util/set ret hello' ret='hello'
  ble/test 'ble/util/set ret "hello world"' ret='hello world'
  ble/test 'ble/util/set ret ""' ret=''
  ble/test 'ble/util/set ret " "' ret=' '
  ble/test 'ble/util/set ret " a"' ret=' a'
  ble/test 'ble/util/set ret "a "' ret='a '
  ble/test 'ble/util/set ret $'\''\n'\''' ret=$'\n'
  ble/test 'ble/util/set ret A$'\''\n'\''' ret=A$'\n'
  ble/test 'ble/util/set ret A$'\''\n'\''B' ret=A$'\n'B
)

# ble/util/sprintf
(
  ble/test 'ble/util/sprintf ret "[%s]" 1 2 3' ret='[1][2][3]'
  ble/test 'ble/util/sprintf ret "[%5s]" 1' ret='[    1]'
  ble/test 'ble/util/sprintf ret "[%.2s]" 12345' ret='[12]'
  ble/test 'ble/util/sprintf ret "[%d,%d]" 1 3' ret='[1,3]'
  ble/test 'ble/util/sprintf ret "[%x]" 27' ret='[1b]'
  ble/test 'ble/util/sprintf ret "[%#.2g]" 27' ret='[27.]'
  ble/test 'ble/util/sprintf ret "[%#.2f]" 27' ret='[27.00]'
)

# ble/util/type
(
  alias aaa=fun
  function fun { :; }
  function ble/fun { :; }
  function ble/fun:type { :; }
  function ble/fun#meth { :; }

  ble/test 'ble/util/type ret aaa' ret=alias
  ble/test 'ble/util/type ret fun' ret=function
  ble/test 'ble/util/type ret alias' ret=builtin
  ble/test 'ble/util/type ret mkfifo' ret=file
  ble/test 'ble/util/type ret for' ret=keyword
  ble/test 'ble/util/type ret ble/fun' ret=function
  ble/test 'ble/util/type ret ble/fun:type' ret=function
  ble/test 'ble/util/type ret ble/fun#meth' ret=function

  ble/test 'ble/util/type ret fun1' ret=
  ble/test 'ble/util/type ret ble/fun1' ret=
  ble/test 'ble/util/type ret ble/fun1:type' ret=
  ble/test 'ble/util/type ret ble/fun1#meth' ret=
)

# ble/util/expand-alias
(
  # Note: 複数段階の展開は実行しない
  alias aaa1='aaa2 world'
  ble/test 'ble/util/expand-alias aaa1' ret='aaa2 world'
  alias aaa2='aaa3 hello'
  ble/test 'ble/util/expand-alias aaa2' ret='aaa3 hello'
  ble/test 'ble/util/expand-alias aaa1' ret='aaa2 world'
  alias aaa3='aaa4'
  ble/test 'ble/util/expand-alias aaa3' ret='aaa4'
  ble/test 'ble/util/expand-alias aaa2' ret='aaa3 hello'
  ble/test 'ble/util/expand-alias aaa1' ret='aaa2 world'
  alias aaa4='echo'
  ble/test 'ble/util/expand-alias aaa4' ret='echo'
  ble/test 'ble/util/expand-alias aaa3' ret='aaa4'
  ble/test 'ble/util/expand-alias aaa2' ret='aaa3 hello'
  ble/test 'ble/util/expand-alias aaa1' ret='aaa2 world'
)

# ble/util/is-stdin-ready
if ((_ble_bash>=40000)); then
  (
    ble/test 'echo 1 | { sleep 0.01; ble/util/is-stdin-ready; }'
    ble/test 'sleep 0.01 | ble/util/is-stdin-ready' exit=1
    ble/test 'ble/util/is-stdin-ready <<< a'
    ble/test 'ble/util/is-stdin-ready <<< ""'

    # EOF は成功してしまう? これは意図しない振る舞いである。
    # しかし bash 自体が終了するので関係ないのかもしれない。
    ble/test ': | { sleep 0.01; ble/util/is-stdin-ready; }'
    ble/test 'ble/util/is-stdin-ready < /dev/null'
  )
fi

# ble/util/is-running-in-subshell
ble/test ble/util/is-running-in-subshell exit=1
( ble/test ble/util/is-running-in-subshell )

# ble/util/getpid
(
  ble/test/chdir
  function getpid {
    sh -c 'echo -n $PPID' > a.txt
    ble/util/readfile ppid a.txt
  }

  dummy=modification_to_environment.1
  ble/util/getpid
  ble/test '[[ $BASHPID != $$ ]]'
  getpid
  ble/test '[[ $BASHPID == $ppid ]]'
  pid1=$BASHPID
  (
    dummy=modification_to_environment.2
    ble/util/getpid
    ble/test '[[ $BASHPID != $$ && $BASHPID != $pid1 ]]'
    getpid
    ble/test '[[ $BASHPID == $ppid ]]'
  )
  ble/test/rmdir
)

# ble/fd#is-open
(
  ble/test 'ble/fd#is-open 1'
  ble/test 'ble/fd#is-open 2'
  exec 9>&-
  ble/test 'ble/fd#is-open 9' exit=1
  exec 9>/dev/null
  ble/test 'ble/fd#is-open 9'
  exec 9>&-
  ble/test 'ble/fd#is-open 9' exit=1
)

# ble/fd#alloc
# ble/fd#close
(
  ble/test/chdir
  ble/fd#alloc fd '> a.txt'
  echo hello >&$fd
  echo world >&$fd
  if ((_ble_bash/100!=301)); then
    # bash-3.1 はバグがあって一度開いた fd を閉じれない。
    ble/test 'ble/fd#close fd; echo test >&$fd' exit=1
    ble/test 'cat a.txt' stdout={hello,world}
  fi
  ble/test/rmdir
)

# ble/util/declare-print-definitions
# ble/util/print-global-definitions
# ble/util/has-glob-pattern
# ble/util/is-cygwin-slow-glob
# ble/util/eval-pathname-expansion
# ble/util/isprint+
# ble/util/strftime

ble/test/end-section