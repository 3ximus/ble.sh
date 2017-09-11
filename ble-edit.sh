#!/bin/bash

# **** sections ****
#
# @text.c2w
# @edit/draw
# @line.ps1
# @line.text
# @line.info
# @edit
# @edit.dirty
# @edit.ps1
# @edit/render
# @widget.clear
# @widget.mark
# @edit.bell
# @edit.insert
# @edit.delete
# @edit.cursor
# @edit.word
# @edit.exec
# @edit.accept
# @history
# @history.isearch
# @comp
# @bind
# @bind.bind

## オプション bleopt_char_width_mode
##   文字の表示幅の計算方法を指定します。
## bleopt_char_width_mode=east
##   Unicode East_Asian_Width=A (Ambiguous) の文字幅を全て 2 とします
## bleopt_char_width_mode=west
##   Unicode East_Asian_Width=A (Ambiguous) の文字幅を全て 1 とします
## bleopt_char_width_mode=emacs
##   emacs で用いられている既定の文字幅の設定です
## 定義 ble/util/c2w+$bleopt_char_width_mode
: ${bleopt_char_width_mode:=east}

## オプション bleopt_edit_vbell
##   編集時の visible bell の有効・無効を設定します。
## bleopt_edit_vbell=1
##   有効です。
## bleopt_edit_vbell=
##   無効です。
: ${bleopt_edit_vbell=}

## オプション bleopt_edit_abell
##   編集時の audible bell (BEL 文字出力) の有効・無効を設定します。
## bleopt_edit_abell=1
##   有効です。
## bleopt_edit_abell=
##   無効です。
: ${bleopt_edit_abell=1}

## オプション bleopt_history_lazyload
## bleopt_history_lazyload=1
##   ble-attach 後、初めて必要になった時に履歴の読込を行います。
## bleopt_history_lazyload=
##   ble-attach 時に履歴の読込を行います。
##
## bash-3.1 未満では history -s が思い通りに動作しないので、
## このオプションの値に関係なく ble-attach の時に履歴の読み込みを行います。
: ${bleopt_history_lazyload=1}

## オプション bleopt_delete_selection_mode
##   文字挿入時に選択範囲をどうするかについて設定します。
## bleopt_delete_selection_mode=1 (既定)
##   選択範囲の内容を新しい文字で置き換えます。
## bleopt_delete_selection_mode=
##   選択範囲を解除して現在位置に新しい文字を挿入します。
: ${bleopt_delete_selection_mode=1}

## オプション bleopt_exec_type (内部使用)
##   コマンドの実行の方法を指定します。
## bleopt_exec_type=exec
##   関数内で実行します (従来の方法です。将来的に削除されます)
## bleopt_exec_type=gexec
##   グローバルな文脈で実行します (新しい方法です。現在テスト中です)
## 要件: 関数 ble-edit/exec:$bleopt_exec_type/process
: ${bleopt_exec_type:=gexec}

## オプション bleopt_suppress_bash_output (内部使用)
##   bash 自体の出力を抑制するかどうかを指定します。
## bleopt_suppress_bash_output=1
##   抑制します。bash のエラーメッセージは visible-bell で表示します。
## bleopt_suppress_bash_output=
##   抑制しません。bash のメッセージは全て端末に出力されます。
##   これはデバグ用の設定です。bash の出力を制御するためにちらつきが発生する事があります。
##   bash-3 ではこの設定では C-d を捕捉できません。
: ${bleopt_suppress_bash_output=1}

## オプション bleopt_ignoreeof_message (内部使用)
##   bash-3.0 の時に使用します。C-d を捕捉するのに用いるメッセージです。
##   これは自分の bash の設定に合わせる必要があります。
: ${bleopt_ignoreeof_message:='Use "exit" to leave the shell.'}

## オプション bleopt_default_keymap
##   既定の編集モードに使われるキーマップを指定します。
## bleopt_default_keymap=auto
##   [[ -o emacs/vi ]] の状態に応じて emacs/vi を切り替えます。
## bleopt_default_keymap=emacs
##   emacs と同様の編集モードを使用します。
## bleopt_default_keymap=vi
##   vi と同様の編集モードを使用します。
: ${bleopt_default_keymap:=auto}


# 
#------------------------------------------------------------------------------
# **** char width ****                                                @text.c2w

# ※注意 [ -~] の範囲の文字は全て幅1であるという事を仮定したコードが幾らかある
#   もしこれらの範囲の文字を幅1以外で表示する端末が有ればそれらのコードを実装し
#   直す必要がある。その様な変な端末があるとは思えないが。


_ble_text_c2w__table=()

## 関数 ble/util/c2w ccode
##   @var[out] ret
function ble/util/c2w {
  # ret="${_ble_text_c2w__table[$1]}"
  # [[ $ret ]] && return
  "ble/util/c2w+$bleopt_char_width_mode" "$1"
  # _ble_text_c2w__table[$1]="$ret"
}
## 関数 ble/util/c2w-edit ccode
##   編集画面での表示上の文字幅を返します。
##   @var[out] ret
function ble/util/c2w-edit {
  if (($1<32||127<=$1&&$1<160)); then
    # 制御文字は ^? と表示される。
    ret=2
    # TAB は???

    # 128-159: M-^?
    ((128<=$1&&(ret=4)))
  else
    ble/util/c2w "$1"
  fi
}
# ## 関数 ble/util/c2w-edit ccode
# ##   @var[out] ret
# function ble/util/s2w {
#   ble/util/s2c "$1" "$2"
#   "ble/util/c2w+$bleopt_char_width_mode" "$ret"
# }

## 関数 ble/util/c2w+emacs
##   emacs-24.2.1 default char-width-table
_ble_text_c2w__emacs_wranges=(
 162 164 167 169 172 173 176 178 180 181 182 183 215 216 247 248 272 273 276 279
 280 282 284 286 288 290 293 295 304 305 306 308 315 316 515 516 534 535 545 546
 555 556 608 618 656 660 722 723 724 725 768 769 770 772 775 777 779 780 785 787
 794 795 797 801 805 806 807 813 814 815 820 822 829 830 850 851 864 866 870 872
 874 876 898 900 902 904 933 934 959 960 1042 1043 1065 1067 1376 1396 1536 1540 1548 1549
 1551 1553 1555 1557 1559 1561 1563 1566 1568 1569 1571 1574 1576 1577 1579 1581 1583 1585 1587 1589
 1591 1593 1595 1597 1599 1600 1602 1603 1611 1612 1696 1698 1714 1716 1724 1726 1734 1736 1739 1740
 1742 1744 1775 1776 1797 1799 1856 1857 1858 1859 1898 1899 1901 1902 1903 1904)
function ble/util/c2w+emacs {
  local code="$1" al=0 ah=0 tIndex=

  # bash-4.0 bug workaround
  #   中で使用している変数に日本語などの文字列が入っているとエラーになる。
  #   その値を参照していなくても、その分岐に入らなくても関係ない。
  #   なので ret に予め適当な値を設定しておく事にする。
  ret=1

  (('
    code<0xA0?(
      ret=1
    ):(0x3100<=code&&code<0xA4D0||0xAC00<=code&&code<0xD7A4?(
      ret=2
    ):(0x2000<=code&&code<0x2700?(
      tIndex=0x0100+code-0x2000
    ):(
      al=code&0xFF,
      ah=code/256,
      ah==0x00?(
        tIndex=al
      ):(ah==0x03?(
        ret=0xFF&((al-0x91)&~0x20),
        ret=ret<25&&ret!=17?2:1
      ):(ah==0x04?(
        ret=al==1||0x10<=al&&al<=0x50||al==0x51?2:1
      ):(ah==0x11?(
        ret=al<0x60?2:1
      ):(ah==0x2e?(
        ret=al>=0x80?2:1
      ):(ah==0x2f?(
        ret=2
      ):(ah==0x30?(
        ret=al!=0x3f?2:1
      ):(ah==0xf9||ah==0xfa?(
        ret=2
      ):(ah==0xfe?(
        ret=0x30<=al&&al<0x70?2:1
      ):(ah==0xff?(
        ret=0x01<=al&&al<0x61||0xE0<=al&&al<=0xE7?2:1
      ):(ret=1))))))))))
    )))
  '))

  [[ $tIndex ]] || return 0

  local tIndex="$1"
  if ((tIndex<_ble_text_c2w__emacs_wranges[0])); then
    ret=1
    return
  fi

  local l=0 u=${#_ble_text_c2w__emacs_wranges[@]} m
  while ((l+1<u)); do
    ((_ble_text_c2w__emacs_wranges[m=(l+u)/2]<=tIndex?(l=m):(u=m)))
  done
  ((ret=((l&1)==0)?2:1))
  return 0
}

## 関数 ble/util/c2w+west
function ble/util/c2w.ambiguous {
  local code="$1"
  ret=1
  (('
    (code<0xA0)?(
      ret=1
    ):((
      (code<0xFB00)?(
        0x2E80<=code&&code<0xA4D0&&code!=0x303F||
        0xAC00<=code&&code<0xD7A4||
        0xF900<=code||
        0x1100<=code&&code<0x1160||
        code==0x2329||code==0x232A
      ):(code<0x10000?(
        0xFF00<=code&&code<0xFF61||
        0xFE30<=code&&code<0xFE70||
        0xFFE0<=code&&code<0xFFE7
      ):(
        0x20000<=code&&code<0x2FFFE||
        0x30000<=code&&code<0x3FFFE
      ))
    )?(
      ret=2
    ):(
      ret=-1
    ))
  '))
}
function ble/util/c2w+west {
  ble/util/c2w.ambiguous "$1"
  (((ret<0)&&(ret=1)))
}

## 関数 ble/util/c2w+east
_ble_text_c2w__east_wranges=(
 161 162 164 165 167 169 170 171 174 175 176 181 182 187 188 192 198 199 208 209
 215 217 222 226 230 231 232 235 236 238 240 241 242 244 247 251 252 253 254 255
 257 258 273 274 275 276 283 284 294 296 299 300 305 308 312 313 319 323 324 325
 328 332 333 334 338 340 358 360 363 364 462 463 464 465 466 467 468 469 470 471
 472 473 474 475 476 477 593 594 609 610 708 709 711 712 713 716 717 718 720 721
 728 732 733 734 735 736 913 930 931 938 945 962 963 970 1025 1026 1040 1104 1105 1106
 8208 8209 8211 8215 8216 8218 8220 8222 8224 8227 8228 8232 8240 8241 8242 8244 8245 8246 8251 8252
 8254 8255 8308 8309 8319 8320 8321 8325 8364 8365 8451 8452 8453 8454 8457 8458 8467 8468 8470 8471
 8481 8483 8486 8487 8491 8492 8531 8533 8539 8543 8544 8556 8560 8570 8592 8602 8632 8634 8658 8659
 8660 8661 8679 8680 8704 8705 8706 8708 8711 8713 8715 8716 8719 8720 8721 8722 8725 8726 8730 8731
 8733 8737 8739 8740 8741 8742 8743 8749 8750 8751 8756 8760 8764 8766 8776 8777 8780 8781 8786 8787
 8800 8802 8804 8808 8810 8812 8814 8816 8834 8836 8838 8840 8853 8854 8857 8858 8869 8870 8895 8896
 8978 8979 9312 9450 9451 9548 9552 9588 9600 9616 9618 9622 9632 9634 9635 9642 9650 9652 9654 9656
 9660 9662 9664 9666 9670 9673 9675 9676 9678 9682 9698 9702 9711 9712 9733 9735 9737 9738 9742 9744
 9748 9750 9756 9757 9758 9759 9792 9793 9794 9795 9824 9826 9827 9830 9831 9835 9836 9838 9839 9840
 10045 10046 10102 10112 57344 63744 65533 65534 983040 1048574 1048576 1114110)
function ble/util/c2w+east {
  ble/util/c2w.ambiguous "$1"
  ((ret>=0)) && return

  if ((code<_ble_text_c2w__east_wranges[0])); then
    ret=1
    return
  fi

  local l=0 u=${#_ble_text_c2w__east_wranges[@]} m
  while ((l+1<u)); do
    ((_ble_text_c2w__east_wranges[m=(l+u)/2]<=code?(l=m):(u=m)))
  done
  ((ret=((l&1)==0)?2:1))
}

# 
#------------------------------------------------------------------------------
# **** ble-edit/draw ****                                            @edit/draw

function ble-edit/draw/put {
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$*"
}
function ble-edit/draw/put.ind {
  local -i count="${1-1}"
  local ret; ble/string#repeat "${_ble_term_ind}" "$count"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$ret"
}
function ble-edit/draw/put.il {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_il//'%d'/$value}"
}
function ble-edit/draw/put.dl {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_dl//'%d'/$value}"
}
function ble-edit/draw/put.cuu {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_cuu//'%d'/$value}"
}
function ble-edit/draw/put.cud {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_cud//'%d'/$value}"
}
function ble-edit/draw/put.cuf {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_cuf//'%d'/$value}"
}
function ble-edit/draw/put.cub {
  local -i value="${1-1}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="${_ble_term_cub//'%d'/$value}"
}
function ble-edit/draw/put.cup {
  local -i l="${1-1}" c="${2-1}"
  local out="$_ble_term_cup"
  out="${out//'%l'/$l}"
  out="${out//'%c'/$c}"
  out="${out//'%y'/$((l-1))}"
  out="${out//'%x'/$((c-1))}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$out"
}
function ble-edit/draw/put.hpa {
  local -i c="${1-1}"
  local out="$_ble_term_hpa"
  out="${out//'%c'/$c}"
  out="${out//'%x'/$((c-1))}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$out"
}
function ble-edit/draw/put.vpa {
  local -i l="${1-1}"
  local out="$_ble_term_vpa"
  out="${out//'%l'/$l}"
  out="${out//'%y'/$((l-1))}"
  DRAW_BUFF[${#DRAW_BUFF[*]}]="$out"
}
function ble-edit/draw/flush {
  IFS= builtin eval 'builtin echo -n "${DRAW_BUFF[*]}"'
  DRAW_BUFF=()
}
function ble-edit/draw/sflush {
  local _var=ret
  [[ $1 == -v ]] && _var="$2"
  IFS= builtin eval "$_var=\"\${DRAW_BUFF[*]}\""
  DRAW_BUFF=()
}
function ble-edit/draw/bflush {
  IFS= builtin eval 'ble/util/buffer "${DRAW_BUFF[*]}"'
  DRAW_BUFF=()
}

_ble_draw_trace_brack=()
_ble_draw_trace_scosc=
function ble-edit/draw/trace/SC {
  _ble_draw_trace_scosc="$x $y $g $lc $lg"
  ble-edit/draw/put "$_ble_term_sc"
}
function ble-edit/draw/trace/RC {
  local -a scosc
  scosc=($_ble_draw_trace_scosc)
  x="${scosc[0]}"
  y="${scosc[1]}"
  g="${scosc[2]}"
  lc="${scosc[3]}"
  lg="${scosc[4]}"
  ble-edit/draw/put "$_ble_term_rc"
}
function ble-edit/draw/trace/NEL {
  ble-edit/draw/put "$_ble_term_cr"
  ble-edit/draw/put "$_ble_term_nl"
  ((y++,x=0,lc=32,lg=0))
}
## 関数 ble-edit/draw/trace/SGR/arg_next
##   @var[in    ] f
##   @var[in,out] j
##   @var[   out] arg
function ble-edit/draw/trace/SGR/arg_next {
  local _var=arg _ret
  if [[ $1 == -v ]]; then
    _var="$2"
    shift 2
  fi

  if ((j<${#f[*]})); then
    _ret="${f[j++]}"
  else
    ((i++))
    _ret="${specs[i]%%:*}"
  fi

  (($_var=_ret))
}
function ble-edit/draw/trace/SGR {
  local param="$1" seq="$2" specs i iN
  IFS=\; builtin eval 'specs=($param)'
  if ((${#specs[*]}==0)); then
    g=0
    ble-edit/draw/put "$_ble_term_sgr0"
    return
  fi

  for ((i=0,iN=${#specs[@]};i<iN;i++)); do
    local spec="${specs[i]}" f
    IFS=: builtin eval 'f=($spec)'
    if ((30<=f[0]&&f[0]<50)); then
      # colors
      if ((30<=f[0]&&f[0]<38)); then
        local color="$((f[0]-30))"
        ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
      elif ((40<=f[0]&&f[0]<48)); then
        local color="$((f[0]-40))"
        ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
      elif ((f[0]==38)); then
        local j=1 color cspace
        ble-edit/draw/trace/SGR/arg_next -v cspace
        if ((cspace==5)); then
          ble-edit/draw/trace/SGR/arg_next -v color
          ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
        fi
      elif ((f[0]==48)); then
        local j=1 color cspace
        ble-edit/draw/trace/SGR/arg_next -v cspace
        if ((cspace==5)); then
          ble-edit/draw/trace/SGR/arg_next -v color
          ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
        fi
      elif ((f[0]==39)); then
        ((g&=~(_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor)))
      elif ((f[0]==49)); then
        ((g&=~(_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor)))
      fi
    elif ((90<=f[0]&&f[0]<98)); then
      local color="$((f[0]-90+8))"
      ((g=g&~_ble_color_gflags_MaskFg|_ble_color_gflags_ForeColor|color<<8))
    elif ((100<=f[0]&&f[0]<108)); then
      local color="$((f[0]-100+8))"
      ((g=g&~_ble_color_gflags_MaskBg|_ble_color_gflags_BackColor|color<<16))
    elif ((f[0]==0)); then
      g=0
    elif ((f[0]==1)); then
      ((g|=_ble_color_gflags_Bold))
    elif ((f[0]==22)); then
      ((g&=~_ble_color_gflags_Bold))
    elif ((f[0]==4)); then
      ((g|=_ble_color_gflags_Underline))
    elif ((f[0]==24)); then
      ((g&=~_ble_color_gflags_Underline))
    elif ((f[0]==7)); then
      ((g|=_ble_color_gflags_Revert))
    elif ((f[0]==27)); then
      ((g&=~_ble_color_gflags_Revert))
    elif ((f[0]==3)); then
      ((g|=_ble_color_gflags_Italic))
    elif ((f[0]==23)); then
      ((g&=~_ble_color_gflags_Italic))
    elif ((f[0]==5)); then
      ((g|=_ble_color_gflags_Blink))
    elif ((f[0]==25)); then
      ((g&=~_ble_color_gflags_Blink))
    elif ((f[0]==8)); then
      ((g|=_ble_color_gflags_Invisible))
    elif ((f[0]==28)); then
      ((g&=~_ble_color_gflags_Invisible))
    elif ((f[0]==9)); then
      ((g|=_ble_color_gflags_Strike))
    elif ((f[0]==29)); then
      ((g&=~_ble_color_gflags_Strike))
    fi
  done

  ble-color-g2sgr -v seq "$g"
  ble-edit/draw/put "$seq"
}
function ble-edit/draw/trace/process-csi-sequence {
  local seq="$1" seq1="${1:2}" rex
  local char="${seq1:${#seq1}-1:1}" param="${seq1::${#seq1}-1}"
  if [[ ! ${param//[0-9:;]/} ]]; then
    # CSI 数字引数 + 文字
    case "$char" in
    (m) # SGR
      ble-edit/draw/trace/SGR "$param" "$seq"
      return ;;
    ([ABCDEFGIZ\`ade])
      local arg=0
      [[ $param =~ ^[0-9]+$ ]] && arg="$param"
      ((arg==0&&(arg=1)))

      local x0="$x" y0="$y"
      if [[ $char == A ]]; then
        # CUU "CSI A"
        ((y-=arg,y<0&&(y=0)))
        ((y<y0)) && ble-edit/draw/put.cuu "$((y0-y))"
      elif [[ $char == [Be] ]]; then
        # CUD "CSI B"
        # VPR "CSI e"
        ((y+=arg,y>=lines&&(y=lines-1)))
        ((y>y0)) && ble-edit/draw/put.cud "$((y-y0))"
      elif [[ $char == [Ca] ]]; then
        # CUF "CSI C"
        # HPR "CSI a"
        ((x+=arg,x>=cols&&(x=cols-1)))
        ((x>x0)) && ble-edit/draw/put.cuf "$((x-x0))"
      elif [[ $char == D ]]; then
        # CUB "CSI D"
        ((x-=arg,x<0&&(x=0)))
        ((x<x0)) && ble-edit/draw/put.cub "$((x0-x))"
      elif [[ $char == E ]]; then
        # CNL "CSI E"
        ((y+=arg,y>=lines&&(y=lines-1),x=0))
        ((y>y0)) && ble-edit/draw/put.cud "$((y-y0))"
        ble-edit/draw/put "$_ble_term_cr"
      elif [[ $char == F ]]; then
        # CPL "CSI F"
        ((y-=arg,y<0&&(y=0),x=0))
        ((y<y0)) && ble-edit/draw/put.cuu "$((y0-y))"
        ble-edit/draw/put "$_ble_term_cr"
      elif [[ $char == [G\`] ]]; then
        # CHA "CSI G"
        # HPA "CSI `"
        ((x=arg-1,x<0&&(x=0),x>=cols&&(x=cols-1)))
        ble-edit/draw/put.hpa "$((x+1))"
      elif [[ $char == d ]]; then
        # VPA "CSI d"
        ((y=arg-1,y<0&&(y=0),y>=lines&&(y=lines-1)))
        ble-edit/draw/put.vpa "$((y+1))"
      elif [[ $char == I ]]; then
        # CHT "CSI I"
        local _x
        ((_x=(x/it+arg)*it,
          _x>=cols&&(_x=cols-1)))
        if ((_x>x)); then
          ble-edit/draw/put.cuf "$((_x-x))"
          ((x=_x))
        fi
      elif [[ $char == Z ]]; then
        # CHB "CSI Z"
        local _x
        ((_x=((x+it-1)/it-arg)*it,
          _x<0&&(_x=0)))
        if ((_x<x)); then
          ble-edit/draw/put.cub "$((x-_x))"
          ((x=_x))
        fi
      fi
      lc=-1 lg=0
      return ;;
    ([Hf])
      # CUP "CSI H"
      # HVP "CSI f"
      local -a params
      params=(${param//[^0-9]/ })
      ((x=params[1]-1))
      ((y=params[0]-1))
      ((x<0&&(x=0),x>=cols&&(x=cols-1),
        y<0&&(y=0),y>=lines&&(y=lines-1)))
      ble-edit/draw/put.cup "$((y+1))" "$((x+1))"
      lc=-1 lg=0
      return ;;
    ([su]) # SCOSC SCORC
      if [[ $param == 99 ]]; then
        # PS1 の \[ ... \] の処理。
        # ble-edit/prompt/update で \e[99s, \e[99u に変換している。
        if [[ $char == s ]]; then
          _ble_draw_trace_brack[${#_ble_draw_trace_brack[*]}]="$x $y"
        else
          local lastIndex="${#_ble_draw_trace_brack[*]}-1"
          if ((lastIndex>=0)); then
            local -a scosc
            scosc=(${_ble_draw_trace_brack[lastIndex]})
            ((x=scosc[0]))
            ((y=scosc[1]))
            unset "_ble_draw_trace_brack[$lastIndex]"
          fi
        fi
        return
      else
        if [[ $char == s ]]; then
          ble-edit/draw/trace/SC
        else
          ble-edit/draw/trace/RC
        fi
        return
      fi ;;
    # ■その他色々?
    # ([JPX@MKL]) # 挿入削除→カーソルの位置は不変 lc?
    # ([hl]) # SM RM DECSM DECRM
    esac
  fi

  ble-edit/draw/put "$seq"
}
function ble-edit/draw/trace/process-esc-sequence {
  local seq="$1" char="${1:1}"
  case "$char" in
  (7) # DECSC
    ble-edit/draw/trace/SC
    return ;;
  (8) # DECRC
    ble-edit/draw/trace/RC
    return ;;
  (D) # IND
    ((y++))
    ble-edit/draw/put "$_ble_term_ind"
    [[ $_ble_term_ind != $'\eD' ]] &&
      ble-edit/draw/put.hpa "$((x+1))" # tput ind が唯の改行の時がある
    lc=-1 lg=0
    return ;;
  (M) # RI
    ((y--,y<0&&(y=0)))
    ble-edit/draw/put "$_ble_term_ri"
    lc=-1 lg=0
    return ;;
  (E) # NEL
    ble-edit/draw/trace/NEL
    lc=32 lg=0
    return ;;
  # (H) # HTS 面倒だから無視。
  # ([KL]) PLD PLU は何か?
  esac

  ble-edit/draw/put "$seq"
}

## 関数 ble-edit/draw/trace text
##   制御シーケンスを含む文字列を出力すると共にカーソル位置の移動を計算します。
##
##   @param[in]   text
##     出力する (制御シーケンスを含む) 文字列を指定します。
##   @var[in,out] DRAW_BUFF[]
##     出力先の配列を指定します。
##   @var[in,out] x y
##     出力の開始位置を指定します。出力終了時の位置を返します。
##   @var[in,out] lc lg
##     bleopt_suppress_bash_output= の時、
##     出力開始時のカーソル左の文字コードを指定します。
##     出力終了時のカーソル左の文字コードが分かる場合にそれを返します。
##
##   以下のシーケンスを認識します
##
##   - Control Characters (C0 の文字 及び DEL)
##     BS HT LF VT CR はカーソル位置の変更を行います。
##     それ以外の文字はカーソル位置の変更は行いません。
##
##   - CSI Sequence (Control Sequence)
##     | CUU   CSI A | CHB   CSI Z |
##     | CUD   CSI B | HPR   CSI a |
##     | CUF   CSI C | VPR   CSI e |
##     | CUB   CSI D | HPA   CSI ` |
##     | CNL   CSI E | VPA   CSI d |
##     | CPL   CSI F | HVP   CSI f |
##     | CHA   CSI G | SGR   CSI m |
##     | CUP   CSI H | SCOSC CSI s |
##     | CHT   CSI I | SCORC CSI u |
##     上記のシーケンスはカーソル位置の計算に含め、
##     また、端末 (TERM) に応じた出力を実施します。
##     上記以外のシーケンスはカーソル位置を変更しません。
##
##   - SOS, DCS, SOS, PM, APC, ESC k ～ ESC \
##   - ISO-2022 に含まれる 3 byte 以上のシーケンス
##     これらはそのまま通します。位置計算の考慮には入れません。
##
##   - ESC Sequence
##     DECSC DECRC IND RI NEL はカーソル位置の変更を行います。
##     それ以外はカーソル位置の変更は行いません。
##
function ble-edit/draw/trace {
  # cygwin では LC_COLLATE=C にしないと
  # 正規表現の range expression が期待通りに動かない。
  # __ENCODING__:
  #   マルチバイト文字コードで escape seq と紛らわしいコードが含まれる可能性がある。
  #   多くの文字コードでは C0, C1 にあたるバイトコードを使わないので大丈夫と思われる。
  #   日本語と混ざった場合に問題が生じたらまたその時に考える。
  LC_COLLATE=C ble-edit/draw/trace.impl "$@" &>/dev/null
}
function ble-edit/draw/trace.impl {
  local cols="${COLUMNS-80}" lines="${LINES-25}"
  local it="$_ble_term_it" xenl="$_ble_term_xenl"
  local text="$1"

  # CSI
  local rex_csi='^\[[ -?]*[@-~]'
  # OSC, DCS, SOS, PM, APC Sequences + "GNU screen ESC k"
  local rex_osc='^([]PX^_k])([^]|+[^\])*(\\|||$)'
  # ISO-2022 関係 (3byte以上の物)
  local rex_2022='^[ -/]+[@-~]'
  # ESC ?
  local rex_esc='^[ -~]'

  local i=0 iN="${#text}"
  while ((i<iN)); do
    local tail="${text:i}"
    local w=0
    if [[ $tail == [-]* ]]; then
      local s="${tail::1}"
      ((i++))
      case "$s" in
      ('')
        if [[ $tail =~ $rex_osc ]]; then
          # 各種メッセージ (素通り)
          s="$BASH_REMATCH"
          [[ ${BASH_REMATCH[3]} ]] || s="$s\\" # 終端の追加
          ((i+=${#BASH_REMATCH}-1))
        elif [[ $tail =~ $rex_csi ]]; then
          # Control sequences
          s=
          ((i+=${#BASH_REMATCH}-1))
          ble-edit/draw/trace/process-csi-sequence "$BASH_REMATCH"
        elif [[ $tail =~ $rex_2022 ]]; then
          # ISO-2022 (素通り)
          s="$BASH_REMATCH"
          ((i+=${#BASH_REMATCH}-1))
        elif [[ $tail =~ $rex_esc ]]; then
          s=
          ((i+=${#BASH_REMATCH}-1))
          ble-edit/draw/trace/process-esc-sequence "$BASH_REMATCH"
        fi ;;
      ('') # BS
        ((x>0&&(x--,lc=32,lg=g))) ;;
      ($'\t') # HT
        local _x
        ((_x=(x+it)/it*it,
          _x>=cols&&(_x=cols-1)))
        if ((x<_x)); then
          s="${_ble_util_string_prototype::_x-x}"
          ((x=_x,lc=32,lg=g))
        else
          s=
        fi ;;
      ($'\n') # LF = CR+LF
        s=
        ble-edit/draw/trace/NEL ;;
      ('') # VT
        s=
        ble-edit/draw/put "$_ble_term_cr"
        ble-edit/draw/put "$_ble_term_nl"
        ((x)) && ble-edit/draw/put.cuf "$x"
        ((y++,lc=32,lg=0)) ;;
      ($'\r') # CR ^M
        s="$_ble_term_cr"
        ((x=0,lc=-1,lg=0)) ;;
      # その他の制御文字は  (BEL)  (FF) も含めてゼロ幅と解釈する
      esac
      [[ $s ]] && ble-edit/draw/put "$s"
    elif ble/util/isprint+ "$tail"; then
      w="${#BASH_REMATCH}"
      ble-edit/draw/put "$BASH_REMATCH"
      ((i+=${#BASH_REMATCH}))
      if [[ ! $bleopt_suppress_bash_output ]]; then
        ble-text.s2c -v lc "$BASH_REMATCH" "$((w-1))"
        lg="$g"
      fi
    else
      local w ret
      ble-text.s2c -v lc "$tail" 0
      ((lg=g))
      ble/util/c2w "$lc"
      w="$ret"
      if ((w>=2&&x+w>cols)); then
        # 行に入りきらない場合の調整
        ble-edit/draw/put "${_ble_util_string_prototype::x+w-cols}"
        ((x=cols))
      fi
      ble-edit/draw/put "${tail::1}"
      ((i++))
    fi

    if ((w>0)); then
      ((x+=w,y+=x/cols,x%=cols,
        xenl&&x==0&&(y--,x=cols)))
      ((x==0&&(lc=32,lg=0)))
    fi
  done
}

# **** prompt ****                                                    @line.ps1

## called by ble-edit-initialize
function ble-edit/prompt/initialize {
  # hostname
  _ble_edit_prompt__string_h="${HOSTNAME%%.*}"
  _ble_edit_prompt__string_H="${HOSTNAME}"

  # tty basename
  local tmp=$(tty 2>/dev/null)
  _ble_edit_prompt__string_l="${tmp##*/}"

  # command name
  _ble_edit_prompt__string_s="${0##*/}"

  # user
  _ble_edit_prompt__string_u="${USER}"

  # bash versions
  ble/util/sprintf _ble_edit_prompt__string_v '%d.%d' "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}"
  ble/util/sprintf _ble_edit_prompt__string_V '%d.%d.%d' "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"

  # uid
  if [[ $EUID -eq 0 ]]; then
    _ble_edit_prompt__string_root='#'
  else
    _ble_edit_prompt__string_root='$'
  fi

  if [[ $OSTYPE == cygwin* ]]; then
    local windir=/cygdrive/c/Windows
    if [[ $WINDIR == [A-Za-z]:\\* ]]; then
      local bsl='\' sl=/
      local c=${WINDIR::1} path=${WINDIR:3}
      if [[ $c == [A-Z] ]]; then
        if ((_ble_bash>=40000)); then
          c=${c,?}
        else
          local ret
          ble/util/s2c "$c"
          ble/util/c2s "$((ret+32))"
          c=$ret
        fi
      fi
      windir=/cygdrive/$c/${path//$bsl/$sl}
    fi

    if [[ -e $windir && -w $windir ]]; then
      _ble_edit_prompt__string_root='#'
    fi
  fi
}

## 変数 _ble_edit_prompt
##   構築した prompt の情報をキャッシュします。
##   @var _ble_edit_prompt[0]    version
##     prompt 情報を作成した時の _ble_edit_LINENO を表します。
##   @var _ble_edit_prompt[1..3] x y g
##     prompt を表示し終わった時のカーソルの位置と描画属性を表します。
##   @var _ble_edit_prompt[4..5] lc lg
##     bleopt_suppress_bash_output= の時、
##     prompt を表示し終わった時の左側にある文字とその描画属性を表します。
##     それ以外の時はこの値は使われません。
##   @var _ble_edit_prompt[6]    ps1out
##     prompt を表示する為に出力する制御シーケンスを含んだ文字列です。
##   @var _ble_edit_prompt[7]    ps1esc
##     調整前の ps1out を格納します。ps1out の計算を省略する為に使用します。
_ble_edit_prompt=("" 0 0 0 32 0 "" "")

function _ble_edit_prompt.load {
  x="${_ble_edit_prompt[1]}"
  y="${_ble_edit_prompt[2]}"
  g="${_ble_edit_prompt[3]}"
  lc="${_ble_edit_prompt[4]}"
  lg="${_ble_edit_prompt[5]}"
  ret="${_ble_edit_prompt[6]}"
}

## 関数 ble-edit/prompt/update/append text
##   指定された文字列を "" 内に入れる為のエスケープをして出力します。
##   @param[in] text
##     エスケープされる文字列を指定します。
##   @var[out]  DRAW_BUFF[]
##     出力先の配列です。
function ble-edit/prompt/update/append {
  local text="$1" a b
  if [[ $text == *['$\"`']* ]]; then
    a='\' b='\\' text="${text//"$a"/$b}"
    a='$' b='\$' text="${text//"$a"/$b}"
    a='"' b='\"' text="${text//"$a"/$b}"
    a='`' b='\`' text="${text//"$a"/$b}"
  fi
  ble-edit/draw/put "$text"
}
function ble-edit/prompt/update/process-text {
  local text="$1" a b
  if [[ $text == *'"'* ]]; then
    a='"' b='\"' text="${text//"$a"/$b}"
  fi
  ble-edit/draw/put "$text"
}

## 関数 ble-edit/prompt/update/process-backslash
##   @var[in]     tail
##   @var[in.out] DRAW_BUFF
function ble-edit/prompt/update/process-backslash {
  ((i+=2))

  # \\ の次の文字
  local c="${tail:1:1}" pat='[]#!$\'
  if [[ ! ${pat##*"$c"*} ]]; then
    case "$c" in
    (\[) ble-edit/draw/put $'\e[99s' ;; # \[ \] は後処理の為、適当な識別用の文字列を出力する。
    (\]) ble-edit/draw/put $'\e[99u' ;;
    ('#') # コマンド番号 (本当は history に入らない物もある…)
      ble-edit/draw/put "$_ble_edit_CMD" ;;
    (\!) # 編集行の履歴番号
      local count
      ble-edit/history/getcount -v count
      ble-edit/draw/put "$((count+1))" ;;
    ('$') # # or $
      ble-edit/prompt/update/append "$_ble_edit_prompt__string_root" ;;
    (\\)
      # '\\' は '\' と出力された後に、更に "" 内で評価された時に次の文字をエスケープする。
      # 例えば '\\$' は一旦 '\$' となり、更に展開されて '$' となる。'\\\\' も同様に '\' になる。
      ble-edit/draw/put '\' ;;
    esac
  elif local handler="ble-edit/prompt/update/backslash:$c" && ble/util/isfunction "$handler"; then
    "$handler"
  else
    # その他の文字はそのまま出力される。
    # - '\"' '\`' はそのまま出力された後に "" 内で評価され '"' '`' となる。
    # - それ以外の場合は '\?' がそのまま出力された後に、"" 内で評価されても変わらず '\?' 等となる。
    ble-edit/draw/put "\\$c"
  fi
}

function ble-edit/prompt/update/backslash:0 { # 8進表現
  local rex='^\\[0-7]{1,3}'
  if [[ $tail =~ $rex ]]; then
    local seq="${BASH_REMATCH[0]}"
    ((i+=${#seq}-2))
    builtin eval "c=\$'$seq'"
  fi
  ble-edit/prompt/update/append "$c"
}
function ble-edit/prompt/update/backslash:1 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:2 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:3 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:4 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:5 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:6 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:7 { ble-edit/prompt/update/backslash:0; }
function ble-edit/prompt/update/backslash:a { # 0 BEL
  ble-edit/draw/put ""
}
function ble-edit/prompt/update/backslash:d { # ? 日付
  [[ $cache_d ]] || ble/util/strftime -v cache_d '%a %b %d'
  ble-edit/prompt/update/append "$cache_d"
}
function ble-edit/prompt/update/backslash:t { # 8 時刻
  [[ $cache_t ]] || ble/util/strftime -v cache_t '%H:%M:%S'
  ble-edit/prompt/update/append "$cache_t"
}
function ble-edit/prompt/update/backslash:A { # 5 時刻
  [[ $cache_A ]] || ble/util/strftime -v cache_A '%H:%M'
  ble-edit/prompt/update/append "$cache_A"
}
function ble-edit/prompt/update/backslash:T { # 8 時刻
  [[ $cache_T ]] || ble/util/strftime -v cache_T '%I:%M:%S'
  ble-edit/prompt/update/append "$cache_T"
}
function ble-edit/prompt/update/backslash:@ { # ? 時刻
  [[ $cache_at ]] || ble/util/strftime -v cache_at '%I:%M %p'
  ble-edit/prompt/update/append "$cache_at"
}
function ble-edit/prompt/update/backslash:D {
  local rex='^\\D\{([^{}]*)\}' cache_D
  if [[ $tail =~ $rex ]]; then
    ble/util/strftime -v cache_D "${BASH_REMATCH[1]}"
    ble-edit/prompt/update/append "$cache_D"
    ((i+=${#BASH_REMATCH}-2))
  else
    ble-edit/prompt/update/append "\\$c"
  fi
}
function ble-edit/prompt/update/backslash:e {
  ble-edit/draw/put $'\e'
}
function ble-edit/prompt/update/backslash:h { # = ホスト名
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_h"
}
function ble-edit/prompt/update/backslash:H { # = ホスト名
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_H"
}
function ble-edit/prompt/update/backslash:j { #   ジョブの数
  if [[ ! $cache_j ]]; then
    local joblist
    ble/util/joblist
    cache_j=${#joblist[@]}
  fi
  ble-edit/draw/put "$cache_j"
}
function ble-edit/prompt/update/backslash:l { #   tty basename
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_l"
}
function ble-edit/prompt/update/backslash:n {
  ble-edit/draw/put $'\n'
}
function ble-edit/prompt/update/backslash:r {
  ble-edit/draw/put "$_ble_term_cr"
}
function ble-edit/prompt/update/backslash:s { # 4 "bash"
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_s"
}
function ble-edit/prompt/update/backslash:u { # = ユーザ名
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_u"
}
function ble-edit/prompt/update/backslash:v { # = bash version %d.%d
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_w"
}
function ble-edit/prompt/update/backslash:V { # = bash version %d.%d.%d
  ble-edit/prompt/update/append "$_ble_edit_prompt__string_V"
}
function ble-edit/prompt/update/backslash:w { # PWD
  ble-edit/prompt/update/update-cache_wd
  ble-edit/prompt/update/append "$cache_wd"
}
function ble-edit/prompt/update/backslash:W { # PWD短縮
  if [[ $PWD == / ]]; then
    ble-edit/prompt/update/append /
  else
    ble-edit/prompt/update/update-cache_wd
    ble-edit/prompt/update/append "${cache_wd##*/}"
  fi
}
function ble-edit/prompt/update/update-cache_wd {
  [[ $cache_wd ]] && return

  if [[ $PWD == / ]]; then
    cache_wd=/
    return
  fi

  local head= body="${PWD%/}"
  if [[ $body == "$HOME" ]]; then
    cache_wd='~'
    return
  elif [[ $body == "$HOME"/* ]]; then
    head='~/'
    body=${body#"$HOME"/}
  fi

  if [[ $PROMPT_DIRTRIM ]]; then
    local dirtrim=$((PROMPT_DIRTRIM))
    local pat='[^/]'
    local count=${body//$pat}
    if ((${#count}>=dirtrim)); then
      ble/string#repeat '/*' "$dirtrim"
      local omit=${body%$ret}
      ((${#omit}>3)) &&
        body=...${body:${#omit}}
    fi
  fi

  cache_wd="$head$body"
}

function ble-edit/prompt/update/eval-prompt_command {
  # return 等と記述されていた時対策として関数内評価。
  eval "$PROMPT_COMMAND"
}

## 関数 ble-edit/prompt/update
##   _ble_edit_PS1 からプロンプトを構築します。
##   @var[in]  _ble_edit_PS1
##     構築されるプロンプトの内容を指定します。
##   @var[out] _ble_edit_prompt
##     構築したプロンプトの情報を格納します。
##   @var[out] ret
##     プロンプトを描画する為の文字列を返します。
##   @var[in,out] x y g
##     プロンプトの描画開始点を指定します。
##     プロンプトを描画した後の位置を返します。
##   @var[in,out] lc lg
##     bleopt_suppress_bash_output= の際に、
##     描画開始点の左の文字コードを指定します。
##     描画終了点の左の文字コードが分かる場合にそれを返します。
function ble-edit/prompt/update {
  local ps1="${_ble_edit_PS1}"
  local version="$_ble_edit_LINENO"
  if [[ ${_ble_edit_prompt[0]} == "$version" ]]; then
    _ble_edit_prompt.load
    return
  fi

  if [[ $PROMPT_COMMAND ]]; then
    ble-edit/prompt/update/eval-prompt_command
  fi

  local cache_d cache_t cache_A cache_T cache_at cache_D cache_j cache_wd

  # 1 特別な Escape \? を処理
  local i=0 iN="${#ps1}"
  local -a DRAW_BUFF
  local rex_letters='^[^\]+|\\$'
  while ((i<iN)); do
    local tail="${ps1:i}"
    if [[ $tail == '\'?* ]]; then
      ble-edit/prompt/update/process-backslash
    elif [[ $tail =~ $rex_letters ]]; then
      ble-edit/prompt/update/process-text "$BASH_REMATCH"
      ((i+=${#BASH_REMATCH}))
    else
      # ? ここには本来来ないはず。
      ble-edit/draw/put "${tail::1}"
      ((i++))
    fi
  done

  # 2 eval 'ps1esc="..."'
  local ps1esc
  ble-edit/draw/sflush -v ps1esc
  builtin eval "ps1esc=\"$ps1esc\""
  if [[ $ps1esc == "${_ble_edit_prompt[7]}" ]]; then
    # 前回と同じ ps1esc の場合は計測処理は省略
    _ble_edit_prompt[0]="$version"
    _ble_edit_prompt.load
    return
  fi

  # 3 計測
  x=0 y=0 g=0 lc=32 lg=0
  ble-edit/draw/trace "$ps1esc"
  ((lc<0&&(lc=0)))

  #echo "ps1=$ps1" >> 1.tmp
  #echo "ps1esc=$ps1esc" >> 1.tmp
  #declare -p DRAW_BUFF >> 1.tmp

  # 4 出力
  local ps1out
  ble-edit/draw/sflush -v ps1out
  ret="$ps1out"
  _ble_edit_prompt=("$version" "$x" "$y" "$g" "$lc" "$lg" "$ps1out" "$ps1esc")
}

# 
# **** text ****                                                     @line.text

## @var _ble_line_text_cache_pos[]
## @var _ble_line_text_cache_cs[]
##   編集文字列の各文字に対応する位置と表示文字列の配列です。
_ble_line_text_cache_pos=()
_ble_line_text_cache_cs=()

## @var _ble_line_text_cache_ichg[]
##   表示文字に変更のあった物の index の一覧です。
_ble_line_text_cache_ichg=()
_ble_line_text_cache_length=

## 関数 text x y; ble-edit/text/update/position; x y
##   @var[in    ] text
##   @var[in,out] x y
##   @var[in    ] BLELINE_RANGE_UPDATE[]
##   @var[   out] POS_UMIN POS_UMAX
##   @var[   out] _ble_line_text_cache_length
##   @var[   out] _ble_line_text_cache_pos[]
##   @var[   out] _ble_line_text_cache_cs[]
##   @var[   out] _ble_line_text_cache_ichg[]
function ble-edit/text/update/position {
  local dbeg dend dend0
  ((dbeg=BLELINE_RANGE_UPDATE[0]))
  ((dend=BLELINE_RANGE_UPDATE[1]))
  ((dend0=BLELINE_RANGE_UPDATE[2]))

  local iN="${#text}"
  ((_ble_line_text_cache_length=iN))

  # 初期位置 x y
  local _pos="$x $y"
  local -a pos
  if [[ ${_ble_line_text_cache_pos[0]} != "$_pos" ]]; then
    # 初期位置の変更がある場合は初めから計算し直し
    ((dbeg<0&&(dend=dend0=0),
      dbeg=0))
    _ble_line_text_cache_pos[0]="$_pos"
  else
    if ((dbeg<0)); then
      # 初期位置も内容も変更がない場合はOK
      pos=(${_ble_line_text_cache_pos[iN]})
      ((x=pos[0]))
      ((y=pos[1]))
      return
    elif ((dbeg>0)); then
      # 途中から計算を再開
      pos=(${_ble_line_text_cache_pos[dbeg]})
      ((x=pos[0]))
      ((y=pos[1]))
    fi
  fi

  local cols="${COLUMNS-80}" it="$_ble_term_it" xenl="$_ble_term_xenl"
  # local cols="80" it="$_ble_term_it" xenl="1"

#%if !release
  ble-assert '((dbeg<0||(dbeg<=dend&&dbeg<=dend0)))' "($dbeg $dend $dend0) <- (${BLELINE_RANGE_UPDATE[*]})"
#%end

  # shift cached data
  _ble_util_array_prototype.reserve "$iN"
  local -a old_pos old_ichg
  old_pos=("${_ble_line_text_cache_pos[@]:dend0:iN-dend+1}")
  old_ichg=("${_ble_line_text_cache_ichg[@]}")
  _ble_line_text_cache_pos=(
    "${_ble_line_text_cache_pos[@]::dbeg+1}"
    "${_ble_util_array_prototype[@]::dend-dbeg}"
    "${_ble_line_text_cache_pos[@]:dend0+1:iN-dend}")
  _ble_line_text_cache_cs=(
    "${_ble_line_text_cache_cs[@]::dbeg}"
    "${_ble_util_array_prototype[@]::dend-dbeg}"
    "${_ble_line_text_cache_cs[@]:dend0:iN-dend}")
  _ble_line_text_cache_ichg=()

  local i
  for ((i=dbeg;i<iN;)); do
    if ble/util/isprint+ "${text:i}"; then
      local w="${#BASH_REMATCH}"
      local n
      for ((n=i+w;i<n;i++)); do
        local cs="${text:i:1}"
        if (((++x==cols)&&(y++,x=0,xenl))); then
          cs="$cs$_ble_term_nl"
          ble/array#push _ble_line_text_cache_ichg "$i"
        fi
        _ble_line_text_cache_cs[i]="$cs"
        _ble_line_text_cache_pos[i+1]="$x $y 0"
      done
    else
      local ret
      ble/util/s2c "$text" "$i"
      local code="$ret"

      local w=0 cs= changed=0
      if ((code<32)); then
        if ((code==9)); then
          if ((x+1>=cols)); then
            cs=' '
            ((xenl)) && cs="$cs$_ble_term_nl"
            changed=1
            ((y++,x=0))
          else
            local x2
            ((x2=(x/it+1)*it,
              x2>=cols&&(x2=cols-1),
              w=x2-x,
              w!=it&&(changed=1)))
            cs="${_ble_util_string_prototype::w}"
          fi
        elif ((code==10)); then
          ((y++,x=0))
          cs="$_ble_term_el$_ble_term_nl"
        else
          ((w=2))
          ble/util/c2s "$((code+64))"
          cs="^$ret"
        fi
      elif ((code==127)); then
        w=2 cs="^?"
      elif ((128<=code&&code<160)); then
        ble/util/c2s "$((code-64))"
        w=4 cs="M-^$ret"
      else
        ble/util/c2w "$code"
        w="$ret" cs="${text:i:1}"
      fi

      local wrapping=0
      if ((w>0)); then
        if ((x<cols&&cols<x+w)); then
          ((xenl)) && cs="$_ble_term_nl$cs"
          cs="${_ble_util_string_prototype::cols-x}$cs"
          ((x=cols,changed=1,wrapping=1))
        fi

        ((x+=w))
        while ((x>cols)); do
          ((y++,x-=cols))
        done
        if ((x==cols)); then
          if ((xenl)); then
            cs="$cs$_ble_term_nl"
            changed=1
          fi
          ((y++,x=0))
        fi
      fi

      _ble_line_text_cache_cs[i]="$cs"
      ((changed)) && ble/array#push _ble_line_text_cache_ichg "$i"
      _ble_line_text_cache_pos[i+1]="$x $y $wrapping"
      ((i++))
    fi

    # 後は同じなので計算を省略
    ((i>=dend)) && [[ ${old_pos[i-dend]} == ${_ble_line_text_cache_pos[i]} ]] && break
  done

  if ((i<iN)); then
    # 途中で一致して中断した場合は、前の iN 番目の位置を読む
    local -a pos
    pos=(${_ble_line_text_cache_pos[iN]})
    ((x=pos[0]))
    ((y=pos[1]))
  fi

  # 前回までの文字修正位置を shift&add
  local j jN ichg
  for ((j=0,jN=${#old_ichg[@]};j<jN;j++)); do
    if ((ichg=old_ichg[j],
         (ichg>=dend0)&&(ichg+=dend-dend0),
         (0<=ichg&&ichg<dbeg||dend<=i&&ichg<iN)))
    then
      ble/array#push _ble_line_text_cache_ichg "$ichg"
    fi
  done

  ((dbeg<i)) && POS_UMIN="$dbeg" POS_UMAX="$i"
}

_ble_line_text_buff=()
_ble_line_text_buffName=

## 関数 x y lc lg; ble-edit/text/update; x y cx cy lc lg
## @param[in    ] text  編集文字列
## @param[in    ] dirty 編集によって変更のあった最初の index
## @param[in    ] index カーソルの index
## @param[in,out] x     編集文字列開始位置、終了位置。
## @param[in,out] y     編集文字列開始位置、終了位置。
## @param[in,out] lc lg
##   カーソル左の文字のコードと gflag を返します。
##   カーソルが先頭にある場合は、編集文字列開始位置の左(プロンプトの最後の文字)について記述します。
## @var   [   out] umin umax
##   umin,umax は再描画の必要な範囲を文字インデックスで返します。
function ble-edit/text/update {
  # text dirty x y [ble-edit/text/update/position] x y
  local POS_UMIN=-1 POS_UMAX=-1
  ble-edit/text/update/position

  local iN="${#text}"

  # highlight -> HIGHLIGHT_BUFF
  local HIGHLIGHT_BUFF HIGHLIGHT_UMIN HIGHLIGHT_UMAX
  ble-highlight-layer/update "$text"
  #ble-edit/info/show text "highlight-urange = ($HIGHLIGHT_UMIN $HIGHLIGHT_UMAX)"

  # 変更文字の適用
  if ((${#_ble_line_text_cache_ichg[@]})); then
    local ichg g sgr
    builtin eval "_ble_line_text_buff=(\"\${$HIGHLIGHT_BUFF[@]}\")"
    HIGHLIGHT_BUFF=_ble_line_text_buff
    for ichg in "${_ble_line_text_cache_ichg[@]}"; do
      ble-highlight-layer/getg "$ichg"
      ble-color-g2sgr -v sgr "$g"
      _ble_line_text_buff[ichg]="$sgr${_ble_line_text_cache_cs[ichg]}"
    done
  fi

  _ble_line_text_buffName="$HIGHLIGHT_BUFF"

  # umin, umax
  ((umin=HIGHLIGHT_UMIN,
    umax=HIGHLIGHT_UMAX,
    POS_UMIN>=0&&(umin<0||umin>POS_UMIN)&&(umin=POS_UMIN),
    POS_UMAX>=0&&(umax<0||umax<POS_UMAX)&&(umax=POS_UMAX)))
  # ble-edit/info/show text "position $POS_UMIN-$POS_UMAX, highlight $HIGHLIGHT_UMIN-$HIGHLIGHT_UMAX"

  # update lc, lg
  #
  #   lc, lg は bleopt_suppress_bash_output= の時に bash に出力させる文字と
  #   その属性を表す。READLINE_LINE が空だと C-d を押した時にその場でログアウト
  #   してしまったり、エラーメッセージが表示されたりする。その為 READLINE_LINE
  #   に有限の長さの文字列を設定したいが、そうするとそれが画面に出てしまう。
  #   そこで、ble.sh では現在のカーソル位置にある文字と同じ文字を READLINE_LINE
  #   に設定する事で、bash が文字を出力しても見た目に問題がない様にしている。
  #
  #   cx==0 の時には現在のカーソル位置の右にある文字を READLINE_LINE に設定し
  #   READLINE_POINT=0 とする。cx>0 の時には現在のカーソル位置の左にある文字を
  #   READLINE_LINE に設定し READLINE_POINT=(左の文字のバイト数) とする。
  #   (READLINE_POINT は文字数ではなくバイトオフセットである事に注意する。)
  #
  if [[ $bleopt_suppress_bash_output ]]; then
    lc=32 lg=0
  else
    # index==0 の場合は受け取った lc lg をそのまま返す
    if ((index>0)); then
      local cx cy
      ble-edit/text/getxy.cur --prefix=c "$index"

      local lcs ret
      if ((cx==0)); then
        # 次の文字
        if ((index==iN)); then
          # 次の文字がない時は空白
          ret=32
        else
          lcs="${_ble_line_text_cache_cs[index]}"
          ble/util/s2c "$lcs" 0
        fi

        # 次が改行の時は空白にする
        ble-highlight-layer/getg -v lg "$index"
        ((lc=ret==10?32:ret))
      else
        # 前の文字
        lcs="${_ble_line_text_cache_cs[index-1]}"
        ble/util/s2c "$lcs" "$((${#lcs}-1))"
        ble-highlight-layer/getg -v lg "$((index-1))"
        ((lc=ret))
      fi
    fi
  fi
}

function ble-edit/text/is-position-up-to-date {
  ((_ble_edit_dirty_draw_beg==-1))
}
## 関数 ble-edit/text/check-position-up-to-date
##   編集文字列の文字の配置情報が最新であることを確認します。
##   以下の変数を参照する場合に事前に呼び出します。
##
##   _ble_line_text_cache_pos
##   _ble_line_text_cache_length
##
function ble-edit/text/check-position-up-to-date {
  ble-assert 'ble-edit/text/is-position-up-to-date' 'dirty text positions'
}

## 関数 ble-edit/text/getxy.out index
##   index 番目の文字の出力開始位置を取得します。
##
##   @var[out] x y
##
##   行末に収まらない文字の場合は行末のスペースを埋める為に
##   配列 _ble_line_text_cache_cs において空白文字が文字本体の前に追加されます。
##   その場合には、追加される空白文字の前の位置を返すことに注意して下さい。
##   実用上は境界 index の左側の文字の終端位置と解釈できます。
##
function ble-edit/text/getxy.out {
  ble-edit/text/check-position-up-to-date
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix="${1#--prefix=}"
    shift
  fi

  local -a _pos
  _pos=(${_ble_line_text_cache_pos[$1]})
  ((${_prefix}x=_pos[0]))
  ((${_prefix}y=_pos[1]))
}

## 関数 ble-edit/text/getxy.cur index
##   index 番目の文字の表示開始位置を取得します。
##
##   @var[out] x y
##
##   ble-edidt/text/getxy.out の異なり前置される空白は考えずに、
##   文字本体が開始する位置を取得します。
##   実用上は境界 index の右側の文字の開始位置と解釈できます。
##
function ble-edit/text/getxy.cur {
  ble-edit/text/check-position-up-to-date
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix="${1#--prefix=}"
    shift
  fi

  local -a _pos
  _pos=(${_ble_line_text_cache_pos[$1]})

  # 追い出しされたか check
  if (($1<_ble_line_text_cache_length)); then
    local -a _eoc
    _eoc=(${_ble_line_text_cache_pos[$1+1]})
    ((_eoc[2])) && ((_pos[0]=0,_pos[1]++))
  fi

  ((${_prefix}x=_pos[0]))
  ((${_prefix}y=_pos[1]))
}


## 関数 ble-edit/text/slice [beg [end]]
##   @var [out] ret
function ble-edit/text/slice {
  ble-edit/text/check-position-up-to-date
  local iN="$_ble_line_text_cache_length"
  local i1="${1:-0}" i2="${2:-$iN}"
  ((i1<0&&(i1+=iN,i1<0&&(i1=0)),
    i2<0&&(i2+=iN)))
  if ((i1<i2&&i1<iN)); then
    local g sgr
    ble-highlight-layer/getg -v g "$i1"
    ble-color-g2sgr -v sgr "$g"
    IFS= builtin eval "ret=\"\$sgr\${$_ble_line_text_buffName[*]:i1:i2-i1}\""
  else
    ret=
  fi
}

## 関数 ble-edit/text/get-index-at x y
##   指定した位置 x y に対応する index を求めます。
function ble-edit/text/get-index-at {
  ble-edit/text/check-position-up-to-date
  local _var=index
  if [[ $1 == -v ]]; then
    _var="$2"
    shift 2
  fi

  local _x="$1" _y="$2"
  if ((_y>_ble_line_endy)); then
    (($_var=_ble_line_text_cache_length))
  elif ((_y<_ble_line_begy)); then
    (($_var=0))
  else
    # 2分法
    local _l=0 _u="$((_ble_line_text_cache_length+1))" _m
    local -a _mx _my
    while ((_l+1<_u)); do
      ble-edit/text/getxy.cur --prefix=_m "$((_m=(_l+_u)/2))"
      (((_y<_my||_y==_my&&_x<_mx)?(_u=_m):(_l=_m)))
    done
    (($_var=_l))
  fi
}

## 関数 ble-edit/text/find-logical-eol [index [offset]]; ret
##   _ble_edit_str 内で位置 index から offset 行だけ次の行の終端位置を返します。
##
##   offset が 0 の場合は位置 index を含む行の行末を返します。
##   offset が正で offset 次の行がない場合は ${#_ble_edit_str} を返します。
##
function ble-edit/text/find-logical-eol {
  local index=${1:-$_ble_edit_ind} offset=${2:-0}
  if ((offset>0)); then
    local text=${_ble_edit_str:index}
    local rex="^([^$_ble_term_nl]*$_ble_term_nl){0,$offset}[^$_ble_term_nl]*"
    [[ $text =~ $rex ]]
    ((ret=index+${#BASH_REMATCH}))
  elif ((offset<0)); then
    local text=${_ble_edit_str::index}
    local rex="($_ble_term_nl[^$_ble_term_nl]*){0,$((-offset))}$"
    [[ $text =~ $rex ]]
    if [[ $BASH_REMATCH ]]; then
      ((ret=index-${#BASH_REMATCH}))
    else
      ble-edit/text/find-logical-eol "$index" 0
    fi
  else
    local text=${_ble_edit_str:index}
    text=${text%%$'\n'*}
    ((ret=index+${#text}))
  fi
}
## 関数 ble-edit/text/find-logical-bol [index [offset]]; ret
##   _ble_edit_str 内で位置 index から offset 行だけ次の行の先頭位置を返します。
##
##   offset が 0 の場合は位置 index を含む行の行頭を返します。
##   offset が正で offset だけ次の行がない場合は最終行の行頭を返します。
##   特に次の行がない場合は現在の行頭を返します。
##
function ble-edit/text/find-logical-bol {
  local index=${1:-$_ble_edit_ind} offset=${2:-0}
  if ((offset>0)); then
    local text=${_ble_edit_str:index}
    local rex="^([^$_ble_term_nl]*$_ble_term_nl){0,$offset}"
    [[ $text =~ $rex ]]
    if [[ $BASH_REMATCH ]]; then
      ((ret=index+${#BASH_REMATCH}))
    else
      ble-edit/text/find-logical-bol "$index" 0
    fi
  elif ((offset<0)); then
    ble-edit/text/find-logical-eol "$index" "$offset"
    ble-edit/text/find-logical-bol "$ret" 0
  else
    local text=${_ble_edit_str::index}
    text=${text##*$'\n'}
    ((ret=index-${#text}))
  fi
}

## 関数 ble-edit/text/is-single-line
function ble-edit/text/is-single-line {
  [[ $_ble_edit_str != *$'\n'* ]]
}

# 
# **** information pane ****                                         @line.info

## 関数 x y cols out ; ble-edit/info/.put-atomic ( nchar text )+ ; x y out
##   指定した文字列を out に追加しつつ、現在位置を更新します。
##   文字列は幅 1 の文字で構成されていると仮定します。
function ble-edit/info/.put-simple {
  local nchar="$1"

  if ((y+(x+nchar)/cols<lines)); then
    out="$out$2"
    ((x+=nchar%cols,
      y+=nchar/cols,
      (_ble_term_xenl?x>cols:x>=cols)&&(y++,x-=cols)))
  else
    # 画面をはみ出る場合
    out="$out${2::lines*cols-(y*cols+x)}"
    ((x=cols,y=lines-1))
    ble-edit/info/.put-nl-if-eol
  fi
}
## 関数 x y cols out ; ble-edit/info/.put-atomic ( w char )+ ; x y out
##   指定した文字を out に追加しつつ、現在位置を更新します。
function ble-edit/info/.put-atomic {
  local w c
  w="$1"

  # その行に入りきらない文字は次の行へ (幅 w が2以上の文字)
  if ((x<cols&&cols<x+w)); then
    _ble_util_string_prototype.reserve "$((cols-x))"
    out="$out${_ble_util_string_prototype::cols-x}"
    ((x=cols))
  fi

  out="$out$2"

  # 移動
  if ((w>0)); then
    ((x+=w))
    while ((_ble_term_xenl?x>cols:x>=cols)); do
      ((y++,x-=cols))
    done
  fi
}
## 関数 x y cols out ; ble-edit/info/.put-nl-if-eol ; x y out
##   行末にいる場合次の行へ移動します。
function ble-edit/info/.put-nl-if-eol {
  if ((x==cols)); then
    ((_ble_term_xenl)) && out="$out"$'\n'
    ((y++,x=0))
  fi
}

## 関数 x y; ble-edit/info/.construct-text text ; ret
##   指定した文字列を表示する為の制御系列に変換します。
function ble-edit/info/.construct-text {
  local cols=${COLUMNS-80}
  local lines=$(((LINES?LINES:0)-_ble_line_endy-2))

  local text="$1" out=
  local i iN=${#text}
  for ((i=0;i<iN;)); do
    local tail="${text:i}"

    if ble/util/isprint+ "$tail"; then
      ble-edit/info/.put-simple "${#BASH_REMATCH}" "${BASH_REMATCH[0]}"
      ((i+=${#BASH_REMATCH}))
    else
      ble/util/s2c "$text" "$i"
      local code="$ret" w=0
      if ((code<32)); then
        ble/util/c2s "$((code+64))"
        ble-edit/info/.put-atomic 2 "$_ble_term_rev^$ret$_ble_term_sgr0"
      elif ((code==127)); then
        ble-edit/info/.put-atomic 2 '$_ble_term_rev^?$_ble_term_sgr0'
      elif ((128<=code&&code<160)); then
        ble/util/c2s "$((code-64))"
        ble-edit/info/.put-atomic 4 "${_ble_term_rev}M-^$ret$_ble_term_sgr0"
      else
        ble/util/c2w "$code"
        ble-edit/info/.put-atomic "$ret" "${text:i:1}"
      fi

      ((y>=lines)) && break
      ((i++))
    fi
  done

  ble-edit/info/.put-nl-if-eol

  ret="$out"
}

## 関数 ble-edit/info/.construct-content type text
##   @var[in,out] x y
##   @var[out]    content
function ble-edit/info/.construct-content {
  local type=$1 text=$2
  case "$1" in
  (raw)
    local lc=32 lg=0 g=0
    local -a DRAW_BUFF
    ble-edit/draw/trace "$text"
    ble-edit/draw/sflush -v content ;;
  (text)
    local lc=32 ret
    ble-edit/info/.construct-text "$text"
    content="$ret" ;;
  (*)
    echo "usage: ble-edit/info/.construct-content type text" >&2 ;;
  esac
}


_ble_line_info=(0 0 "")

function ble-edit/info/.clear-content {
  [[ ${_ble_line_info[2]} ]] || return

  local -a DRAW_BUFF
  ble-edit/render/goto 0 _ble_line_endy
  ble-edit/draw/put "$_ble_term_ind"
  ble-edit/draw/put.dl '_ble_line_info[1]+1'
  ble-edit/draw/bflush

  _ble_line_y="$((_ble_line_endy+1))"
  _ble_line_x=0
  _ble_line_info=(0 0 "")
}

## 関数 ble-edit/info/.render-content x y content
##   @param[in] x y content
function ble-edit/info/.render-content {
  local x=$1 y=$2 content=$3

  # 既に同じ内容で表示されているとき…。
  [[ $content == "${_ble_line_info[2]}" ]] && return

  if [[ ! $content ]]; then
    ble-edit/info/.clear-content
    return
  fi

  # (1) 移動・領域確保
  local -a DRAW_BUFF
  ble-edit/render/goto 0 "$_ble_line_endy"
  ble-edit/draw/put "$_ble_term_ind"
  [[ ${_ble_line_info[2]} ]] && ble-edit/draw/put.dl '_ble_line_info[1]+1'
  [[ $content ]] && ble-edit/draw/put.il y+1

  # (2) 内容
  ble-edit/draw/put "$content"
  ble-edit/draw/bflush

  _ble_line_y="$((_ble_line_endy+1+y))"
  _ble_line_x="$x"
  _ble_line_info=("$x" "$y" "$content")
}

_ble_line_info_default=(0 0 "")
_ble_line_info_scene=hidden

## 関数 ble-edit/info/show type text
##
##   @param[in] type
##
##     以下の2つの内の何れかを指定する。
##
##     type=text
##     type=raw
##
##   @param[in] text
##
##     type=text のとき、引数 text は表示する文字列を含む。
##     改行などの制御文字は代替表現に置き換えられる。
##     画面からはみ出る文字列に関しては自動で truncate される。
##
##     type=raw のとき、引数 text は制御シーケンスを含む文字列を指定する。
##     画面からはみ出る様なシーケンスに対する対策はない。
##     シーケンスを生成する側でその様なことがない様にする必要がある。
##
function ble-edit/info/show {
  local type=$1 text=$2
  if [[ $text ]]; then
    local x=0 y=0 content=
    ble-edit/info/.construct-content "$type" "$text"
    ble-edit/info/.render-content "$x" "$y" "$content"
    ble/util/buffer.flush >&2
    _ble_line_info_scene=show
  else
    ble-edit/info/default
  fi
}
function ble-edit/info/set-default {
  local type=$1 text=$2
  local x=0 y=0 content
  ble-edit/info/.construct-content "$type" "$text"
  _ble_line_info_default=("$x" "$y" "$content")
  if [[ $_ble_line_info_scene == default ]]; then
    ble-edit/info/.render-content "${_ble_line_info_default[@]}"
    ble/util/buffer.flush >&2
  fi
}
function ble-edit/info/default {
  _ble_line_info_scene=default
  if (($#)); then
    ble-edit/info/set-default "$@"
  else
    ble-edit/info/.render-content "${_ble_line_info_default[@]}"
    ble/util/buffer.flush >&2
  fi
}
function ble-edit/info/clear {
  ble-edit/info/default
}

## 関数 ble-edit/info/hide
## 関数 ble-edit/info/reveal
##
##   これらの関数は .newline 前後に一時的に info の表示を抑制するための関数である。
##   この関数の呼び出しの後に flush が入ることを想定して ble/util/buffer.flush は実行しない。
##
function ble-edit/info/hide {
  _ble_line_info_scene=hidden
  ble-edit/info/.clear-content
}
function ble-edit/info/reveal {
  if [[ $_ble_line_info_scene == hidden ]]; then
    _ble_line_info_scene=default
    ble-edit/info/.render-content "${_ble_line_info_default[@]}"
  fi
}

# 
#------------------------------------------------------------------------------
# **** edit ****                                                          @edit

# 現在の編集状態は以下の変数で表現される
_ble_edit_str=
_ble_edit_ind=0
_ble_edit_mark=0
_ble_edit_mark_active=
_ble_edit_kill_ring=
_ble_edit_kill_type=
_ble_edit_overwrite_mode=
_ble_edit_arg=

# _ble_edit_str は以下の関数を通して変更する。
# 変更範囲を追跡する為。
function _ble_edit_str.replace {
  local -i beg="$1" end="$2"
  local ins="$3"

  # cf. Note#1
  _ble_edit_str="${_ble_edit_str::beg}""$ins""${_ble_edit_str:end}"
  _ble_edit_str/update-dirty-range "$beg" "$((beg+${#ins}))" "$end"
  ble-edit/render/invalidate "$beg"
#%if !release
  # Note: 何処かのバグで _ble_edit_ind に変な値が入ってエラーになるので、
  #   ここで誤り訂正を行う。想定として、この関数を呼出した時の _ble_edit_ind の値は、
  #   replace を実行する前の値とする。この関数の呼び出し元では、
  #   _ble_edit_ind の更新はこの関数の呼び出しより後で行う様にする必要がある。
  # Note: このバグは恐らく #D0411 で解決したが暫く様子見する。
  if ! ((0<=_ble_edit_dirty_syntax_beg&&_ble_edit_dirty_syntax_end<=${#_ble_edit_str})); then
    ble-stackdump "0 <= beg=$_ble_edit_dirty_syntax_beg <= end=$_ble_edit_dirty_syntax_end <= len=${#_ble_edit_str}; beg=$beg, end=$end, ins(${#ins})=$ins"
    _ble_edit_dirty_syntax_beg=0
    _ble_edit_dirty_syntax_end="${#_ble_edit_str}"
    local olen=$((${#_ble_edit_str}-${#ins}+end-beg))
    ((olen<0&&(olen=0),
      _ble_edit_ind>olen&&(_ble_edit_ind=olen),
      _ble_edit_mark>olen&&(_ble_edit_mark=olen)))
  fi
#%end
}
function _ble_edit_str.reset {
  local str="$1"
  _ble_edit_str/update-dirty-range 0 "${#str}" "${#_ble_edit_str}"
  ble-edit/render/invalidate 0
  _ble_edit_str="$str"
#%if !release
  if ! ((0<=_ble_edit_dirty_syntax_beg&&_ble_edit_dirty_syntax_end<=${#_ble_edit_str})); then
    ble-stackdump "0 <= beg=$_ble_edit_dirty_syntax_beg <= end=$_ble_edit_dirty_syntax_end <= len=${#_ble_edit_str}; str(${#str})=$str"
    _ble_edit_dirty_syntax_beg=0
    _ble_edit_dirty_syntax_end="${#_ble_edit_str}"
  fi
#%end
}
function _ble_edit_str.reset-and-check-dirty {
  local str="$1"
  [[ $_ble_edit_str == $str ]] && return

  local ret pref suff
  ble/string#common-prefix "$_ble_edit_str" "$str"; pref="$ret"
  local dmin="${#pref}"
  ble/string#common-suffix "${_ble_edit_str:dmin}" "${str:dmin}"; suff="$ret"
  local dmax0=$((${#_ble_edit_str}-${#suff})) dmax=$((${#str}-${#suff}))

  _ble_edit_str/update-dirty-range "$dmin" "$dmax" "$dmax0"
  _ble_edit_str="$str"
}

_ble_edit_dirty_draw_beg=-1
_ble_edit_dirty_draw_end=-1
_ble_edit_dirty_draw_end0=-1

_ble_edit_dirty_syntax_beg=0
_ble_edit_dirty_syntax_end=0
_ble_edit_dirty_syntax_end0=1

function _ble_edit_str/update-dirty-range {
  ble-edit/dirty-range/update --prefix=_ble_edit_dirty_draw_ "$@"
  ble-edit/dirty-range/update --prefix=_ble_edit_dirty_syntax_ "$@"

  # ble-assert '((
  #   _ble_edit_dirty_draw_beg==_ble_edit_dirty_syntax_beg&&
  #   _ble_edit_dirty_draw_end==_ble_edit_dirty_syntax_end&&
  #   _ble_edit_dirty_draw_end0==_ble_edit_dirty_syntax_end0))'
}

function _ble_edit_str.update-syntax {
  local beg end end0
  ble-edit/dirty-range/load --prefix=_ble_edit_dirty_syntax_
  if ((beg>=0)); then
    ble-edit/dirty-range/clear --prefix=_ble_edit_dirty_syntax_

    ble-syntax/parse "$_ble_edit_str" "$beg" "$end" "$end0"
  fi
}

function _ble_edit_arg.get {
  eval "${ble_util_upvar_setup//ret/arg}"

  local default_value=$1
  if [[ $_ble_edit_arg ]]; then
    arg=$((10#$_ble_edit_arg))
  else
    arg=$default_value
  fi
  _ble_edit_arg=

  eval "${ble_util_upvar//ret/arg}"
}
function _ble_edit_arg.clear {
  _ble_edit_arg=
}


# **** edit/dirty ****                                              @edit.dirty

function ble-edit/dirty-range/load {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix="${1#--prefix=}"
    ((beg=${_prefix}beg,
      end=${_prefix}end,
      end0=${_prefix}end0))
  fi
}

function ble-edit/dirty-range/clear {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix="${1#--prefix=}"
    shift
  fi

  ((${_prefix}beg=-1,
    ${_prefix}end=-1,
    ${_prefix}end0=-1))
}

## 関数 ble-edit/dirty-range/update [--prefix=PREFIX] beg end end0
## @param[out] PREFIX
## @param[in]  beg    変更開始点。beg<0 は変更がない事を表す
## @param[in]  end    変更終了点。end<0 は変更が末端までである事を表す
## @param[in]  end0   変更前の end に対応する位置。
function ble-edit/dirty-range/update {
  local _prefix=
  if [[ $1 == --prefix=* ]]; then
    _prefix="${1#--prefix=}"
    shift
    [[ $_prefix ]] && local beg end end0
  fi

  local begB="$1" endB="$2" endB0="$3"
  ((begB<0)) && return

  local begA endA endA0
  ((begA=${_prefix}beg,endA=${_prefix}end,endA0=${_prefix}end0))

  local delta
  if ((begA<0)); then
    ((beg=begB,
      end=endB,
      end0=endB0))
  else
    ((beg=begA<begB?begA:begB))
    if ((endA<0||endB<0)); then
      ((end=-1,end0=-1))
    else
      ((end=endB,end0=endA0,
        (delta=endA-endB0)>0?(end+=delta):(end0-=delta)))
    fi
  fi

  if [[ $_prefix ]]; then
    ((${_prefix}beg=beg,
      ${_prefix}end=end,
      ${_prefix}end0=end0))
  fi
}

# **** PS1/LINENO ****                                                @edit.ps1
#
# 内部使用変数
## 変数 _ble_edit_PS1
## 変数 _ble_edit_LINENO
## 変数 _ble_edit_CMD

function ble-edit/attach/TRAPWINCH {
  if ((_ble_edit_attached)); then
    local IFS=$' \t\n'
    _ble_line_text_cache_pos=()
    ble-edit/bind/stdout.on
    ble-edit/render/redraw
    ble-edit/bind/stdout.off
  fi
}

## called by ble-edit-attach
_ble_edit_attached=0
function ble-edit/attach {
  ((_ble_edit_attached)) && return
  _ble_edit_attached=1

  if [[ ! ${_ble_edit_LINENO+set} ]]; then
    _ble_edit_LINENO="${BASH_LINENO[*]: -1}"
    ((_ble_edit_LINENO<0)) && _ble_edit_LINENO=0
    unset LINENO; LINENO="$_ble_edit_LINENO"
    _ble_edit_CMD="$_ble_edit_LINENO"
  fi

  trap ble-edit/attach/TRAPWINCH WINCH

  # if [[ ! ${_ble_edit_PS1+set} ]]; then
  # fi
  _ble_edit_PS1="$PS1"
  PS1=
  [[ $bleopt_exec_type == exec ]] && _ble_edit_IFS="$IFS"
}

function ble-edit/detach {
  ((!_ble_edit_attached)) && return
  PS1="$_ble_edit_PS1"
  [[ $bleopt_exec_type == exec ]] && IFS="$_ble_edit_IFS"
  _ble_edit_attached=0
}

# **** ble-edit/render ****                                        @edit/render

#
# 大域変数
#

## 配列 _ble_line_cur
##   キャレット位置 (ユーザに対して呈示するカーソル) と其処の文字の情報を保持します。
## _ble_line_cur[0] x   キャレット位置の y 座標を保持します。
## _ble_line_cur[1] y   キャレット位置の y 座標を保持します。
## _ble_line_cur[2] lc
##   キャレット位置の左側の文字の文字コードを整数で保持します。
##   キャレットが最も左の列にある場合は右側の文字を保持します。
## _ble_line_cur[3] lg
##   キャレット位置の左側の SGR フラグを保持します。
##   キャレットが最も左の列にある場合は右側の文字に適用される SGR フラグを保持します。
_ble_line_cur=(0 0 32 0)

## 変数 x
## 変数 y
##   現在の (描画の為に動き回る) カーソル位置を保持します。
_ble_line_x=0 _ble_line_y=0

_ble_line_begx=0
_ble_line_begy=0
_ble_line_endx=0
_ble_line_endy=0

#
# 補助関数 (公開)
#

## 関数 ble-edit/render/goto varname x y
##   現在位置を指定した座標へ移動する制御系列を生成します。
## @param[in] x y
##   移動先のカーソルの座標を指定します。
##   プロンプト原点が x=0 y=0 に対応します。
function ble-edit/render/goto {
  local -i x="$1" y="$2"
  ble-edit/draw/put "$_ble_term_sgr0"

  local -i dy=y-_ble_line_y
  if ((dy!=0)); then
    if ((dy>0)); then
      ble-edit/draw/put "${_ble_term_cud//'%d'/$dy}"
    else
      ble-edit/draw/put "${_ble_term_cuu//'%d'/$((-dy))}"
    fi
  fi

  local -i dx=x-_ble_line_x
  if ((dx!=0)); then
    if ((x==0)); then
      ble-edit/draw/put "$_ble_term_cr"
    elif ((dx>0)); then
      ble-edit/draw/put "${_ble_term_cuf//'%d'/$dx}"
    else
      ble-edit/draw/put "${_ble_term_cub//'%d'/$((-dx))}"
    fi
  fi

  _ble_line_x="$x" _ble_line_y="$y"
}
## 関数 ble-edit/render/clear-line
##   プロンプト原点に移動して、既存のプロンプト表示内容を空白にする制御系列を生成します。
function ble-edit/render/clear-line {
  ble-edit/render/goto 0 0
  if ((_ble_line_endy>0)); then
    local height=$((_ble_line_endy+1))
    ble-edit/draw/put "${_ble_term_dl//'%d'/$height}${_ble_term_il//'%d'/$height}"
  else
    ble-edit/draw/put "$_ble_term_el2"
  fi
}
## 関数 ble-edit/render/clear-line-after x y
##   指定した x y 位置に移動して、
##   更に、以降の内容を空白にする制御系列を生成します。
## @param[in] x
## @param[in] y
function ble-edit/render/clear-line-after {
  local x="$1" y="$2"

  ble-edit/render/goto "$x" "$y"
  if ((_ble_line_endy>y)); then
    local height=$((_ble_line_endy-y))
    ble-edit/draw/put "$_ble_term_ind${_ble_term_dl//'%d'/$height}${_ble_term_il//'%d'/$height}$_ble_term_ri"
  fi
  ble-edit/draw/put "$_ble_term_el"

  _ble_line_x="$x" _ble_line_y="$y"
}

#
# 表示関数
#

## 変数 _ble_edit_dirty
##   編集文字列の変更開始点を記録します。
##   編集文字列の位置計算は、この点以降に対して実行されます。
##   ble-edit/render/update 関数内で使用されクリアされます。
##   @value _ble_edit_dirty=
##     再描画の必要がない事を表します。
##   @value _ble_edit_dirty=-1
##     プロンプトも含めて内容の再計算をする必要がある事を表します。
##   @value _ble_edit_dirty=(整数)
##     編集文字列の指定した位置以降に対し再計算する事を表します。
_ble_edit_dirty=-1

function ble-edit/render/invalidate {
  local d2="${1:--1}"
  if [[ ! $_ble_edit_dirty ]]; then
    _ble_edit_dirty="$d2"
  else
    ((d2<_ble_edit_dirty&&(_ble_edit_dirty=d2)))
  fi
}

## 関数 ble-edit/render/update
##   プロンプト・編集文字列の表示更新を ble/util/buffer に対して行う。
##   Post-condition: カーソル位置 (x y) = (_ble_line_cur[0] _ble_line_cur[1]) に移動する
##   Post-condition: 編集文字列部分の再描画を実行する
##
##   @var _ble_edit_render_caret_state := inds ':' mark ':' mark_active ':' line_disabled ':' overwrite_mode
##     ble-edit/render/update で用いる変数です。
##     現在の表示内容のカーソル位置・ポイント位置の情報を記録します。
##
_ble_edit_render_caret_state=::
function ble-edit/render/update {
  local caret_state="$_ble_edit_ind:$_ble_edit_mark:$_ble_edit_mark_active:$_ble_edit_line_disabled:$_ble_edit_overwrite_mode"
  if [[ ! $_ble_edit_dirty && $_ble_edit_render_caret_state == $caret_state ]]; then
    local -a DRAW_BUFF
    ble-edit/render/goto "${_ble_line_cur[0]}" "${_ble_line_cur[1]}"
    ble-edit/draw/bflush
    return
  fi

  #-------------------
  # 内容の再計算

  local ret

  local x y g lc lg=0
  ble-edit/prompt/update # x y lc ret
  local prox="$x" proy="$y" prolc="$lc" esc_prompt="$ret"

  # BLELINE_RANGE_UPDATE → ble-edit/text/update 内でこれを見て update を済ませる
  local -a BLELINE_RANGE_UPDATE=("$_ble_edit_dirty_draw_beg" "$_ble_edit_dirty_draw_end" "$_ble_edit_dirty_draw_end0")
  ble-edit/dirty-range/clear --prefix=_ble_edit_dirty_draw_
#%if !release
  ble-assert '((BLELINE_RANGE_UPDATE[0]<0||(
       BLELINE_RANGE_UPDATE[0]<=BLELINE_RANGE_UPDATE[1]&&
       BLELINE_RANGE_UPDATE[0]<=BLELINE_RANGE_UPDATE[2])))' "(${BLELINE_RANGE_UPDATE[*]})"
#%end

  # local graphic_dbeg graphic_dend graphic_dend0
  # ble-edit/dirty-range/update --prefix=graphic_d

  # 編集内容の構築
  local text="$_ble_edit_str" index="$_ble_edit_ind" dirty="$_ble_edit_dirty"
  local iN="${#text}"
  ((index<0?(index=0):(index>iN&&(index=iN))))

  local umin=-1 umax=-1
  ble-edit/text/update # text index dirty -> x y lc lg

  #-------------------
  # 出力

  local -a DRAW_BUFF

  # 1 描画領域の確保 (高さの調整)
  local endx endy begx begy
  ble-edit/text/getxy.out --prefix=beg 0
  ble-edit/text/getxy.out --prefix=end "$iN"
  local delta
  if (((delta=endy-_ble_line_endy)!=0)); then
    if ((delta>0)); then
      ble-edit/render/goto 0 "$_ble_line_endy"
      ble-edit/draw/put.ind delta
      ((delta>1)) && ble-edit/draw/put.cuu delta-1
      ble-edit/draw/put.il delta
      ble-edit/draw/put.cuu
    else
      ble-edit/render/goto 0 "$((_ble_line_endy+1+delta))"
      ble-edit/draw/put.dl -delta
    fi
  fi
  _ble_line_begx="$begx" _ble_line_begy="$begy"
  _ble_line_endx="$endx" _ble_line_endy="$endy"

  # 2 表示内容
  local ret retx=-1 rety=-1 esc_line=
  if ((_ble_edit_dirty>=0)); then
    # 部分更新の場合

    # # 編集文字列全体の描画
    # local ret
    # ble-edit/text/slice # → ret
    # local esc_line="$ret"
    # ble-edit/render/clear-line-after "$prox" "$proy"
    # ble-edit/draw/put "$ret"
    # ble-edit/text/getxy.out --prefix=ret "$iN" # → retx rety
    # _ble_line_x="$retx" _ble_line_y="$rety"

    # 編集文字列の一部を描画する場合
    if ((umin<umax)); then
      local uminx uminy umaxx umaxy
      ble-edit/text/getxy.out --prefix=umin "$umin"
      ble-edit/text/getxy.out --prefix=umax "$umax"

      ble-edit/render/goto "$uminx" "$uminy"
      ble-edit/text/slice "$umin" "$umax"
      ble-edit/draw/put "$ret"
      _ble_line_x="$umaxx" _ble_line_y="$umaxy"
    fi

    if ((BLELINE_RANGE_UPDATE[0]>=0)); then
      ble-edit/render/clear-line-after "$endx" "$endy"
    fi
  else
    # 全体更新

    # プロンプト描画
    ble-edit/render/clear-line
    ble-edit/draw/put "$esc_prompt"
    _ble_line_x="$prox" _ble_line_y="$proy"

    # # SC/RC で復帰する場合はこちら。
    # local ret esc_line
    # if ((index<iN)); then
    #   ble-edit/text/slice 0 "$index"
    #   esc_line="$ret$_ble_term_sc"
    #   ble-edit/text/slice "$index"
    #   esc_line="$esc_line$ret$_ble_term_rc"
    #   ble-edit/draw/put "$esc_line"
    #   ble-edit/text/getxy.out --prefix=ret "$index"
    #   _ble_line_x="$retx" _ble_line_y="$rety"
    # else
    #   ble-edit/text/slice
    #   esc_line="$ret"
    #   ble-edit/draw/put "$esc_line"
    #   ble-edit/text/getxy.out --prefix=ret "$iN"
    #   _ble_line_x="$retx" _ble_line_y="$rety"
    # fi

    # 全体を描画する場合
    local ret esc_line
    ble-edit/text/slice # → ret
    esc_line="$ret"
    ble-edit/draw/put "$ret"
    ble-edit/text/getxy.out --prefix=ret "$iN" # → retx rety
    _ble_line_x="$retx" _ble_line_y="$rety"
  fi

  # 3 移動
  local cx cy
  ble-edit/text/getxy.cur --prefix=c "$index" # → cx cy
  ble-edit/render/goto "$cx" "$cy"
  ble-edit/draw/bflush

  # 4 後で使う情報の記録
  _ble_line_cur=("$cx" "$cy" "$lc" "$lg")
  _ble_edit_dirty= _ble_edit_render_caret_state="$caret_state"

  if [[ -z $bleopt_suppress_bash_output ]]; then
    if ((retx<0)); then
      ble-edit/text/slice
      esc_line="$ret"
      ble-edit/text/getxy.out --prefix=ret "$iN"
    fi

    _ble_line_cache=(
      "$esc_prompt$esc_line"
      "${_ble_line_cur[@]}"
      "$_ble_line_endx" "$_ble_line_endy"
      "$retx" "$rety")
  fi
}
function ble-edit/render/redraw {
  _ble_edit_dirty=-1
  ble-edit/render/update
}

## 配列 _ble_line_cache
##   現在表示している内容のキャッシュです。
##   ble-edit/render/update で値が設定されます。
##   ble-edit/render/redraw-cache はこの情報を元に再描画を行います。
## _ble_line_cache[0]:        表示内容
## _ble_line_cache[1]: curx   カーソル位置 x
## _ble_line_cache[2]: cury   カーソル位置 y
## _ble_line_cache[3]: curlc  カーソル位置の文字の文字コード
## _ble_line_cache[3]: curlg  カーソル位置の文字の SGR フラグ
## _ble_line_cache[4]: endx   末端位置 x
## _ble_line_cache[5]: endy   末端位置 y
_ble_line_cache=()

function ble-edit/render/redraw-cache {
  if [[ ${_ble_line_cache[0]+set} ]]; then
    local -a d
    d=("${_ble_line_cache[@]}")

    local -a DRAW_BUFF

    ble-edit/render/clear-line
    ble-edit/draw/put "${d[0]}"
    _ble_line_x="${d[7]}" _ble_line_y="${d[8]}"
    _ble_line_endx="${d[5]}" _ble_line_endy="${d[6]}"

    _ble_line_cur=("${d[@]:1:4}")
    ble-edit/render/goto "${_ble_line_cur[0]}" "${_ble_line_cur[1]}"
    ble-edit/draw/bflush
  else
    ble-edit/render/redraw
  fi
}

## 関数 ble-edit/render/update-adjusted
##   プロンプト・編集文字列の表示更新を ble/util/buffer に対して行う。
##
## @remarks
## この関数は bind -x される関数から呼び出される事を想定している。
## 通常のコマンドとして実行される関数から呼び出す事は想定していない。
## 内部で PS1= 等の設定を行うのでプロンプトの情報が失われる。
## また、READLINE_LINE, READLINE_POINT 等のグローバル変数の値を変更する。
##
function ble-edit/render/update-adjusted {
  ble-edit/render/update
  # 現在はフルで描画 (bash が消してしまうので)
  # ble-edit/render/redraw

  local -a DRAW_BUFF

  # bash が表示するプロンプトを見えなくする
  # (現在のカーソルの左側にある文字を再度上書きさせる)
  PS1=
  local ret lc="${_ble_line_cur[2]}" lg="${_ble_line_cur[3]}"
  ble/util/c2s "$lc"
  READLINE_LINE="$ret"
  if ((_ble_line_cur[0]==0)); then
    READLINE_POINT=0
  else
    if [[ ! $bleopt_suppress_bash_output ]]; then
      ble/util/c2w "$lc"
      ((ret>0)) && ble-edit/draw/put.cub "$ret"
    fi
    ble-text-c2bc "$lc"
    READLINE_POINT="$ret"
  fi

  ble-color-g2sgr "$lg"
  ble-edit/draw/put "$ret"
  ble-edit/draw/bflush
}

# 
# **** redraw, clear-screen, etc ****                             @widget.clear

function ble/widget/redraw-line {
  _ble_edit_arg.clear
  ble-edit/render/invalidate
}
function ble/widget/clear-screen {
  _ble_edit_arg.clear
  ble/util/buffer "$_ble_term_clear"
  _ble_line_x=0 _ble_line_y=0
  ble-edit/render/invalidate
  ble-term/visible-bell/cancel-erasure
}
function ble/widget/display-shell-version {
  ble/widget/.SHELL_COMMAND 'builtin echo "GNU bash, version $BASH_VERSION ($MACHTYPE) with ble.sh"'
}

# 
# **** mark, kill, copy ****                                       @widget.mark

function ble/widget/overwrite-mode {
  if [[ $_ble_edit_overwrite_mode ]]; then
    _ble_edit_overwrite_mode=
  else
    _ble_edit_overwrite_mode=1
  fi
}

function ble/widget/set-mark {
  _ble_edit_mark="$_ble_edit_ind"
  _ble_edit_mark_active=1
}
function ble/widget/kill-forward-text {
  ((_ble_edit_ind>=${#_ble_edit_str})) && return

  _ble_edit_kill_ring="${_ble_edit_str:_ble_edit_ind}"
  _ble_edit_kill_type=
  _ble_edit_str.replace "$_ble_edit_ind" "${#_ble_edit_str}" ''
  ((_ble_edit_mark>_ble_edit_ind&&(_ble_edit_mark=_ble_edit_ind)))
}
function ble/widget/kill-backward-text {
  ((_ble_edit_ind==0)) && return
  _ble_edit_kill_ring="${_ble_edit_str::_ble_edit_ind}"
  _ble_edit_kill_type=
  _ble_edit_str.replace 0 _ble_edit_ind ''
  ((_ble_edit_mark=_ble_edit_mark<=_ble_edit_ind?0:_ble_edit_mark-_ble_edit_ind))
  _ble_edit_ind=0
}
function ble/widget/exchange-point-and-mark {
  local m="$_ble_edit_mark" p="$_ble_edit_ind"
  _ble_edit_ind="$m" _ble_edit_mark="$p"
}
function ble/widget/yank {
  ble/widget/insert-string "$_ble_edit_kill_ring"
}
function ble/widget/marked {
  if [[ $_ble_edit_mark_active != S ]]; then
    _ble_edit_mark="$_ble_edit_ind"
    _ble_edit_mark_active=S
  fi
  "ble/widget/$@"
}
function ble/widget/nomarked {
  if [[ $_ble_edit_mark_active == S ]]; then
    _ble_edit_mark_active=
  fi
  "ble/widget/$@"
}

## 関数 ble/widget/.process-range-argument P0 P1; p0 p1 len ?
## @param[in]  P0  範囲の端点を指定します。
## @param[in]  P1  もう一つの範囲の端点を指定します。
## @param[out] p0  範囲の開始点を返します。
## @param[out] p1  範囲の終端点を返します。
## @param[out] len 範囲の長さを返します。
## @param[out] $?
##   範囲が有限の長さを持つ場合に正常終了します。
##   範囲が空の場合に 1 を返します。
function ble/widget/.process-range-argument {
  p0="$1" p1="$2" len="${#_ble_edit_str}"
  local pt
  ((
    p0>len?(p0=len):p0<0&&(p0=0),
    p1>len?(p1=len):p0<0&&(p1=0),
    p1<p0&&(pt=p1,p1=p0,p0=pt),
    (len=p1-p0)>0
  ))
}
## 関数 ble/widget/.delete-range P0 P1 [allow_empty]
function ble/widget/.delete-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1

  # delete
  if ((len)); then
    _ble_edit_str.replace p0 p1 ''
    ((
      _ble_edit_ind>p1? (_ble_edit_ind-=len):
      _ble_edit_ind>p0&&(_ble_edit_ind=p0),
      _ble_edit_mark>p1? (_ble_edit_mark-=len):
      _ble_edit_mark>p0&&(_ble_edit_mark=p0)
    ))
  fi
  return 0
}
## 関数 ble/widget/.kill-range P0 P1 [allow_empty [kill_type]]
function ble/widget/.kill-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1

  # copy
  _ble_edit_kill_ring="${_ble_edit_str:p0:len}"
  _ble_edit_kill_type=$4

  # delete
  if ((len)); then
    _ble_edit_str.replace p0 p1 ''
    ((
      _ble_edit_ind>p1? (_ble_edit_ind-=len):
      _ble_edit_ind>p0&&(_ble_edit_ind=p0),
      _ble_edit_mark>p1? (_ble_edit_mark-=len):
      _ble_edit_mark>p0&&(_ble_edit_mark=p0)
    ))
  fi
  return 0
}
## 関数 ble/widget/.copy-range P0 P1 [kill_type]
function ble/widget/.copy-range {
  local p0 p1 len
  ble/widget/.process-range-argument "${@:1:2}" || (($3)) || return 1

  # copy
  _ble_edit_kill_ring="${_ble_edit_str:p0:len}"
  _ble_edit_kill_type=$4
}
## 関数 ble/widget/delete-region
##   領域を削除します。
function ble/widget/delete-region {
  ble/widget/.delete-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
## 関数 ble/widget/kill-region
##   領域を切り取ります。
function ble/widget/kill-region {
  ble/widget/.kill-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
## 関数 ble/widget/copy-region
##   領域を転写します。
function ble/widget/copy-region {
  ble/widget/.copy-range "$_ble_edit_mark" "$_ble_edit_ind"
  _ble_edit_mark_active=
}
## 関数 ble/widget/delete-region-or type
##   領域または引数に指定した単位を削除します。
##   mark が active な場合には領域の削除を行います。
##   それ以外の場合には第一引数に指定した単位の削除を実行します。
## @param[in] type
##   mark が active でない場合に実行される削除の単位を指定します。
##   実際には ble-edit 関数 delete-type が呼ばれます。
function ble/widget/delete-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/delete-region
  else
    "ble/widget/delete-$@"
  fi
}
## 関数 ble/widget/kill-region-or type
##   領域または引数に指定した単位を切り取ります。
##   mark が active な場合には領域の切り取りを行います。
##   それ以外の場合には第一引数に指定した単位の切り取りを実行します。
## @param[in] type
##   mark が active でない場合に実行される切り取りの単位を指定します。
##   実際には ble-edit 関数 kill-type が呼ばれます。
function ble/widget/kill-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/kill-region
  else
    "ble/widget/kill-$@"
  fi
}
## 関数 ble/widget/copy-region-or type
##   領域または引数に指定した単位を転写します。
##   mark が active な場合には領域の転写を行います。
##   それ以外の場合には第一引数に指定した単位の転写を実行します。
## @param[in] type
##   mark が active でない場合に実行される転写の単位を指定します。
##   実際には ble-edit 関数 copy-type が呼ばれます。
function ble/widget/copy-region-or {
  if [[ $_ble_edit_mark_active ]]; then
    ble/widget/copy-region
  else
    "ble/widget/copy-$@"
  fi
}

# 
# **** bell ****                                                     @edit.bell

function ble/widget/.bell {
  [[ $bleopt_edit_vbell ]] && ble-term/visible-bell "$1"
  [[ $bleopt_edit_abell ]] && ble-term/audible-bell
  return 0
}
function ble/widget/bell {
  ble/widget/.bell
  _ble_edit_mark_active=
  _ble_edit_arg=
}

# 
# **** insert ****                                                 @edit.insert

function ble/widget/insert-string {
  local ins="$*"
  [[ $ins ]] || return

  local dx="${#ins}"
  _ble_edit_str.replace _ble_edit_ind _ble_edit_ind "$ins"
  (('
    _ble_edit_mark>_ble_edit_ind&&(_ble_edit_mark+=dx),
    _ble_edit_ind+=dx
  '))
  _ble_edit_mark_active=
}

## 編集関数 ble/widget/self-insert
##   文字を挿入する。
##
##   @var[in] _ble_edit_arg
##     繰り返し回数を指定する。
##
##   @var[in] ble_widget_self_insert_opts
##     コロン区切りの設定のリストを指定する。
##
##     nolineext は上書きモードにおいて、行の長さを拡張しない。
##     行の長さが足りない場合は操作をキャンセルする。
##     vi.sh の r, gr による挿入を想定する。
##
function ble/widget/self-insert {
  local code="$((KEYS[0]&ble_decode_MaskChar))"
  ((code==0)) && return

  local ibeg="$_ble_edit_ind" iend="$_ble_edit_ind"
  local ret ins; ble/util/c2s "$code"; ins="$ret"

  local arg; _ble_edit_arg.get 1
  if ((arg<1)) || [[ ! $ins ]]; then
    arg=0 ins=
  elif ((arg>1)); then
    ble/string#repeat "$ins" "$arg"; ins=$ret
  fi
  # Note: arg はこの時点での ins の文字数になっている。

  if [[ $bleopt_delete_selection_mode && $_ble_edit_mark_active ]]; then
    # 選択範囲を置き換える。
    ((_ble_edit_mark<_ble_edit_ind?(ibeg=_ble_edit_mark):(iend=_ble_edit_mark),
      _ble_edit_ind=ibeg))
    ((arg==0&&ibeg==iend)) && return
  elif [[ $_ble_edit_overwrite_mode ]] && ((code!=10&&code!=9)); then
    ((arg==0)) && return

    local removed_width
    if [[ $_ble_edit_overwrite_mode == R ]]; then
      local removed_text=${_ble_edit_str:ibeg:arg}
      removed_text=${removed_text%%[$'\n\t']*}
      removed_width=${#removed_text}
      ((iend+=removed_width))
    else
      # 上書きモードの時は文字幅を考慮して既存の文字を置き換える。
      local ret w; ble/util/c2w-edit "$code"; w=$((arg*ret))

      local iN="${#_ble_edit_str}"
      for ((removed_width=0;removed_width<w&&iend<iN;iend++)); do
        local c1 w1
        ble/util/s2c "$_ble_edit_str" "$iend"; c1="$ret"
        [[ $c1 == 0 || $c1 == 10 || $c1 == 9 ]] && break
        ble/util/c2w-edit "$c1"; w1="$ret"
        ((removed_width+=w1))
      done

      ((removed_width>w)) && ins="$ins${_ble_util_string_prototype::removed_width-w}"
    fi

    # これは vi.sh の r gr で設定する変数
    if [[ :$ble_widget_self_insert_opts: == *:nolineext:* ]]; then
      if ((removed_width<arg)); then
        ble/widget/.bell
        return
      fi
    fi
  fi

  _ble_edit_str.replace ibeg iend "$ins"
  ((_ble_edit_ind+=arg,
    _ble_edit_mark>ibeg&&(
      _ble_edit_mark<iend?(
        _ble_edit_mark=_ble_edit_ind
      ):(
        _ble_edit_mark+=${#ins}-(iend-ibeg)))))
  _ble_edit_mark_active=
}

# quoted insert
function ble/widget/quoted-insert/.hook {
  local -a KEYS=("$1")
  ble/widget/self-insert
}
function ble/widget/quoted-insert {
  _ble_edit_mark_active=
  _ble_decode_char__hook=ble/widget/quoted-insert/.hook
}

function ble/widget/transpose-chars {
  if ((_ble_edit_ind<=0||_ble_edit_ind>=${#_ble_edit_str})); then
    ble/widget/.bell
  else
    local a="${_ble_edit_str:_ble_edit_ind-1:1}"
    local b="${_ble_edit_str:_ble_edit_ind:1}"
    _ble_edit_str.replace _ble_edit_ind-1 _ble_edit_ind+1 "$b$a"
    ((_ble_edit_ind++))
  fi
}

# 
# **** delete-char ****                                            @edit.delete

function ble/widget/.delete-backward-char {
  if ((_ble_edit_ind<=0)); then
    return 1
  else
    local ins=  
    if [[ $_ble_edit_overwrite_mode ]]; then
      local next="${_ble_edit_str:_ble_edit_ind:1}"
      if [[ $next && $next != [$'\n\t'] ]]; then
        local w
        if [[ $_ble_edit_overwrite_mode == R ]]; then
          w=1
        else
          local ret
          ble/util/s2c "$_ble_edit_str" "$((_ble_edit_ind-1))"
          ble/util/c2w-edit "$ret"; w=$ret
        fi
        ins="${_ble_util_string_prototype::w}"
        ((_ble_edit_mark>=_ble_edit_ind&&(_ble_edit_mark+=w)))
      fi
    fi

    _ble_edit_str.replace _ble_edit_ind-1 _ble_edit_ind "$ins"
    ((_ble_edit_ind--,
      _ble_edit_mark>_ble_edit_ind&&_ble_edit_mark--))
    return 0
  fi
}

function ble/widget/.delete-char {
  local a="${1:-1}"
  if ((a>0)); then
    # delete-forward-char
    if ((_ble_edit_ind>=${#_ble_edit_str})); then
      return 1
    else
      _ble_edit_str.replace _ble_edit_ind _ble_edit_ind+1 ''
    fi
  elif ((a<0)); then
    # delete-backward-char
    ble/widget/.delete-backward-char
    return
  else
    # delete-forward-backward-char
    if ((${#_ble_edit_str}==0)); then
      return 1
    elif ((_ble_edit_ind<${#_ble_edit_str})); then
      _ble_edit_str.replace _ble_edit_ind _ble_edit_ind+1 ''
    else
      _ble_edit_ind="${#_ble_edit_str}"
      ble/widget/.delete-backward-char
      return
    fi
  fi

  ((_ble_edit_mark>_ble_edit_ind&&_ble_edit_mark--))
  return 0
}
function ble/widget/delete-forward-char {
  ble/widget/.delete-char 1 || ble/widget/.bell
}
function ble/widget/delete-backward-char {
  ble/widget/.delete-char -1 || ble/widget/.bell
}
function ble/widget/delete-forward-char-or-exit {
  if [[ $_ble_edit_str ]]; then
    ble/widget/delete-forward-char
    return
  fi

  # job が残っている場合
  local joblist
  ble/util/joblist
  if ((${#joblist[@]})); then
    ble/widget/.bell "(exit) ジョブが残っています!"
    ble/widget/.SHELL_COMMAND 'printf %s "$_ble_util_joblist_jobs"'
    return
  fi

  #_ble_edit_detach_flag=exit

  #ble-term/visible-bell ' Bye!! ' # 最後に vbell を出すと一時ファイルが残る
  ble-edit/info/hide
  local -a DRAW_BUFF
  ble-edit/render/goto "$_ble_line_endx" "$_ble_line_endy"
  ble-edit/draw/bflush
  ble/util/buffer.print "${_ble_term_setaf[12]}[ble: exit]$_ble_term_sgr0"
  ble/util/buffer.flush >&2
  exit
}
function ble/widget/delete-forward-backward-char {
  ble/widget/.delete-char 0 || ble/widget/.bell
}


function ble/widget/delete-horizontal-space {
  local a b rex
  b="${_ble_edit_str::_ble_edit_ind}" rex='[ 	]*$' ; [[ $b =~ $rex ]]; b="${#BASH_REMATCH}"
  a="${_ble_edit_str:_ble_edit_ind}"  rex='^[ 	]*'; [[ $a =~ $rex ]]; a="${#BASH_REMATCH}"
  ble/widget/.delete-range "$((_ble_edit_ind-b))" "$((_ble_edit_ind+a))"
}

# 
# **** cursor move ****                                            @edit.cursor

function ble/widget/.goto-char {
  local -i _ind="$1"
  _ble_edit_ind="$_ind"
}
function ble/widget/.forward-char {
  local _ind=$((_ble_edit_ind+${1:-1}))
  if ((_ind>${#_ble_edit_str})); then
    ble/widget/.goto-char "${#_ble_edit_str}"
    return 1
  elif ((_ind<0)); then
    ble/widget/.goto-char 0
    return 1
  else
    ble/widget/.goto-char "$_ind"
    return 0
  fi
}
function ble/widget/forward-char {
  ble/widget/.forward-char 1 || ble/widget/.bell
}
function ble/widget/backward-char {
  ble/widget/.forward-char -1 || ble/widget/.bell
}
function ble/widget/end-of-text {
  ble/widget/.goto-char ${#_ble_edit_str}
}
function ble/widget/beginning-of-text {
  ble/widget/.goto-char 0
}

function ble/widget/beginning-of-logical-line {
  ble-edit/text/find-logical-bol
  ble/widget/.goto-char "$ret"
}
function ble/widget/end-of-logical-line {
  ble-edit/text/find-logical-eol
  ble/widget/.goto-char "$ret"
}
function ble/widget/kill-backward-logical-line {
  ble-edit/text/find-logical-bol
  ((0<ret&&ret==_ble_edit_ind&&ret--)) # 行頭にいる時は直前の改行を削除
  ble/widget/.kill-range "$ret" "$_ble_edit_ind"
}
function ble/widget/kill-forward-logical-line {
  ble-edit/text/find-logical-eol
  ((ret<${#_ble_edit_ind}&&_ble_edit_ind==ret&&ret++)) # 行末にいる時は直後の改行を削除
  ble/widget/.kill-range "$_ble_edit_ind" "$ret"
}
function ble/widget/forward-logical-line {
  ((_ble_edit_ind<${#_ble_edit_str})) || return 1
  local ret ind=$_ble_edit_ind
  ble-edit/text/find-logical-bol "$ind" 0; local bol1=$ret
  ble-edit/text/find-logical-bol "$ind" 1; local bol2=$ret
  if ((bol1==bol2)); then
    ble-edit/text/find-logical-eol
    ble/widget/.goto-char "$ret"
    ((ret!=ind))
  else
    ble-edit/text/find-logical-eol "$bol2"; local eol2=$ret
    local dst=$((bol2+ind-bol1))
    ble/widget/.goto-char $((dst<eol2?dst:eol2))
    return 0
  fi
}
function ble/widget/backward-logical-line {
  ((_ble_edit_ind>0)) || return 1
  local ret ind=$_ble_edit_ind
  ble-edit/text/find-logical-bol "$ind" 0; local bol1=$ret
  ble-edit/text/find-logical-bol "$ind" -1; local bol2=$ret
  if ((bol1==bol2)); then
    ble/widget/.goto-char "$bol1"
    ((bol1!=ind))
  else
    ble-edit/text/find-logical-eol "$bol2"; local eol2=$ret
    local dst=$((bol2+ind-bol1))
    ble/widget/.goto-char $((dst<eol2?dst:eol2))
    return 0
  fi
}

function ble/widget/beginning-of-line {
  if ble-edit/text/is-position-up-to-date; then
    # 配置情報があるときは表示行頭
    local x y index
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at 0 "$y"
    ble/widget/.goto-char "$index"
  else
    # 配置情報がないときは論理行頭
    ble/widget/beginning-of-logical-line
  fi
}
function ble/widget/end-of-line {
  if ble-edit/text/is-position-up-to-date; then
    # 配置情報があるときは表示行末
    local x y index ax ay
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at 0 "$((y+1))"
    ble-edit/text/getxy.cur --prefix=a "$index"
    ((ay>y&&index--))
    ble/widget/.goto-char "$index"
  else
    # 配置情報がないときは論理行末
    ble/widget/end-of-logical-line
  fi
}
function ble/widget/kill-backward-line {
  if ble-edit/text/is-position-up-to-date; then
    local x y index
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at 0 "$y"
    ((index==_ble_edit_ind&&index>0&&index--))
    ble/widget/.kill-range "$index" "$_ble_edit_ind"
  else
    ble/widget/kill-backward-logical-line
  fi
}
function ble/widget/kill-forward-line {
  if ble-edit/text/is-position-up-to-date; then
    local x y index ax ay
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at 0 "$((y+1))"
    ble-edit/text/getxy.cur --prefix=a "$index"
    ((_ble_edit_ind+1<index&&ay>y&&index--))
    ble/widget/.kill-range "$_ble_edit_ind" "$index"
  else
    ble/widget/kill-forward-logical-line
  fi
}
function ble/widget/forward-line {
  ((_ble_edit_ind<${#_ble_edit_str})) || return 1
  if ble-edit/text/is-position-up-to-date; then
    # 配置情報があるときは表示行を移動
    local x y index
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at "$x" "$((y+1))"
    ble/widget/.goto-char "$index"
    ((y<_ble_line_endy))
  else
    # 配置情報がないときは論理行を移動
    ble/widget/forward-logical-line
  fi
}
function ble/widget/backward-line {
  # 一番初めの文字でも追い出しによって2行目以降に表示される可能性。
  # その場合に exit status 1 にする為に初めに check してしまう。
  ((_ble_edit_ind>0)) || return 1

  if ble-edit/text/is-position-up-to-date; then
    # 配置情報があるときは表示行を移動
    local x y index
    ble-edit/text/getxy.cur "$_ble_edit_ind"
    ble-edit/text/get-index-at "$x" "$((y-1))"
    ble/widget/.goto-char "$index"
    ((y>_ble_line_begy))
  else
    # 配置情報がないときは論理行を移動
    ble/widget/backward-logical-line
  fi
}

# 
# **** word location ****                                            @edit.word

function ble/widget/.genword-setup-cword {
  WSET='_a-zA-Z0-9'; WSEP="^$WSET"
}
function ble/widget/.genword-setup-uword {
  WSEP="${IFS:-$' \t\n'}"; WSET="^$WSEP"
}
function ble/widget/.genword-setup-sword {
  WSEP=$'|%WSEP%;()<> \t\n'; WSET="^$WSEP"
}
function ble/widget/.genword-setup-fword {
  WSEP="/${IFS:-$' \t\n'}"; WSET="^$WSEP"
}

## 関数 ble/widget/.locate-backward-genword; a b c
##   後方の単語を探索します。
##
##   |---|www|---|
##   a   b   c   x
##
##   @var[in] WSET,WSEP
##   @var[out] a,b,c
##
function ble/widget/.locate-backward-genword {
  local x="${1:-$_ble_edit_ind}"
  c="${_ble_edit_str::x}"; c="${c##*[$WSET]}"; c=$((x-${#c}))
  b="${_ble_edit_str::c}"; b="${b##*[$WSEP]}"; b=$((c-${#b}))
  a="${_ble_edit_str::b}"; a="${a##*[$WSET]}"; a=$((b-${#a}))
}
## 関数 ble/widget/.locate-backward-genword; s t u
##   前方の単語を探索します。
##
##   |---|www|---|
##   x   s   t   u
##
##   @var[in] WSET,WSEP
##   @var[out] s,t,u
##
function ble/widget/.locate-forward-genword {
  local x="${1:-$_ble_edit_ind}"
  s="${_ble_edit_str:x}"; s="${s%%[$WSET]*}"; s=$((x+${#s}))
  t="${_ble_edit_str:s}"; t="${t%%[$WSEP]*}"; t=$((s+${#t}))
  u="${_ble_edit_str:t}"; u="${u%%[$WSET]*}"; u=$((t+${#u}))
}
## 関数 ble/widget/.locate-backward-genword; s t u
##   現在位置の単語を探索します。
##
##   |---|wwww|---|
##   r   s    t   u
##        <- x --->
##
##   @var[in] WSET,WSEP
##   @var[out] s,t,u
##
function ble/widget/.locate-current-genword {
  local x="${1:-$_ble_edit_ind}"

  local a b c # <a> *<b>w*<c> *<x>
  ble/widget/.locate-backward-genword

  r="$a"
  ble/widget/.locate-forward-genword "$r"
}


## 関数 ble/widget/.delete-forward-genword
##   前方の unix word を削除します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.delete-forward-genword {
  # |---|www|---|
  # x   s   t   u
  local x="${1:-$_ble_edit_ind}" s t u
  ble/widget/.locate-forward-genword
  if ((x!=t)); then
    ble/widget/.delete-range "$x" "$t"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.delete-backward-genword
##   後方の単語を削除します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.delete-backward-genword {
  # |---|www|---|
  # a   b   c   x
  local a b c x="${1:-$_ble_edit_ind}"
  ble/widget/.locate-backward-genword
  if ((x>c&&(c=x),b!=c)); then
    ble/widget/.delete-range "$b" "$c"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.delete-genword
##   現在位置の単語を削除します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.delete-genword {
  local x="${1:-$_ble_edit_ind}" r s t u
  ble/widget/.locate-current-genword "$x"
  if ((x>t&&(t=x),r!=t)); then
    ble/widget/.delete-range "$r" "$t"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.kill-forward-genword
##   前方の単語を切り取ります。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.kill-forward-genword {
  # <x> *<s>w*<t> *<u>
  local x="${1:-$_ble_edit_ind}" s t u
  ble/widget/.locate-forward-genword
  if ((x!=t)); then
    ble/widget/.kill-range "$x" "$t"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.kill-backward-genword
##   後方の単語を切り取ります。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.kill-backward-genword {
  # <a> *<b>w*<c> *<x>
  local a b c x="${1:-$_ble_edit_ind}"
  ble/widget/.locate-backward-genword
  if ((x>c&&(c=x),b!=c)); then
    ble/widget/.kill-range "$b" "$c"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.kill-genword
##   現在位置の単語を切り取ります。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.kill-genword {
  local x="${1:-$_ble_edit_ind}" r s t u
  ble/widget/.locate-current-genword "$x"
  if ((x>t&&(t=x),r!=t)); then
    ble/widget/.kill-range "$r" "$t"
  else
    ble/widget/.bell
  fi
}
## 関数 ble/widget/.copy-forward-genword
##   前方の単語を転写します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.copy-forward-genword {
  # <x> *<s>w*<t> *<u>
  local x="${1:-$_ble_edit_ind}" s t u
  ble/widget/.locate-forward-genword
  ble/widget/.copy-range "$x" "$t"
}
## 関数 ble/widget/.copy-backward-genword
##   後方の単語を転写します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.copy-backward-genword {
  # <a> *<b>w*<c> *<x>
  local a b c x="${1:-$_ble_edit_ind}"
  ble/widget/.locate-backward-genword
  ble/widget/.copy-range "$b" "$((c>x?c:x))"
}
## 関数 ble/widget/.copy-genword
##   現在位置の単語を転写します。
##
##   @var[in] WSET,WSEP
##
function ble/widget/.copy-genword {
  local x="${1:-$_ble_edit_ind}" r s t u
  ble/widget/.locate-current-genword "$x"
  ble/widget/.copy-range "$r" "$((t>x?t:x))"
}
## 関数 ble/widget/.forward-genword
##
##   @var[in] WSET,WSEP
##
function ble/widget/.forward-genword {
  local x="${1:-$_ble_edit_ind}" s t u
  ble/widget/.locate-forward-genword "$x"
  if ((x==t)); then
    ble/widget/.bell
  else
    ble/widget/.goto-char "$t"
  fi
}
## 関数 ble/widget/.backward-genword
##
##   @var[in] WSET,WSEP
##
function ble/widget/.backward-genword {
  local a b c x="${1:-$_ble_edit_ind}"
  ble/widget/.locate-backward-genword "$x"
  if ((x==b)); then
    ble/widget/.bell
  else
    ble/widget/.goto-char "$b"
  fi
}

# 
#%m kill-xword

# generic word

## 関数 ble/widget/delete-forward-xword
##   前方の generic word を削除します。
function ble/widget/delete-forward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.delete-forward-genword "$@"
}
## 関数 ble/widget/delete-backward-xword
##   後方の generic word を削除します。
function ble/widget/delete-backward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.delete-backward-genword "$@"
}
## 関数 ble/widget/delete-xword
##   現在位置の generic word を削除します。
function ble/widget/delete-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.delete-genword "$@"
}
## 関数 ble/widget/kill-forward-xword
##   前方の generic word を切り取ります。
function ble/widget/kill-forward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.kill-forward-genword "$@"
}
## 関数 ble/widget/kill-backward-xword
##   後方の generic word を切り取ります。
function ble/widget/kill-backward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.kill-backward-genword "$@"
}
## 関数 ble/widget/kill-xword
##   現在位置の generic word を切り取ります。
function ble/widget/kill-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.kill-genword "$@"
}
## 関数 ble/widget/copy-forward-xword
##   前方の generic word を転写します。
function ble/widget/copy-forward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.copy-forward-genword "$@"
}
## 関数 ble/widget/copy-backward-xword
##   後方の generic word を転写します。
function ble/widget/copy-backward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.copy-backward-genword "$@"
}
## 関数 ble/widget/copy-xword
##   現在位置の generic word を転写します。
function ble/widget/copy-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.copy-genword "$@"
}
#%end
#%x kill-xword .r/generic word/unix word/  .r/xword/cword/
#%x kill-xword .r/generic word/c word/     .r/xword/uword/
#%x kill-xword .r/generic word/shell word/ .r/xword/sword/
#%x kill-xword .r/generic word/filename/   .r/xword/fword/

#%m forward-xword (
function ble/widget/forward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.forward-genword "$@"
}
function ble/widget/backward-xword {
  local WSET WSEP; ble/widget/.genword-setup-xword
  ble/widget/.backward-genword "$@"
}
#%)
#%x forward-xword .r/generic word/unix word/  .r/xword/cword/
#%x forward-xword .r/generic word/c word/     .r/xword/uword/
#%x forward-xword .r/generic word/shell word/ .r/xword/sword/

# **** ble-edit/exec ****                                            @edit.exec

_ble_edit_exec_lines=()
_ble_edit_exec_lastexit=0
_ble_edit_exec_lastarg=$BASH
function ble-edit/exec/register {
  local BASH_COMMAND="$1"
  ble/array#push _ble_edit_exec_lines "$1"
}
function ble-edit/exec/.setexit {
  # $? 変数の設定
  return "$_ble_edit_exec_lastexit"
}
function ble-edit/exec/.adjust-eol {
  # 文末調整
  local cols="${COLUMNS:-80}"
  local -a DRAW_BUFF
  ble-edit/draw/put "$_ble_term_sc"
  ble-edit/draw/put "${_ble_term_setaf[12]}[ble: EOF]$_ble_term_sgr0"
  ble-edit/draw/put "$_ble_term_rc"
  ble-edit/draw/put.cuf "$((_ble_term_xenl?cols-2:cols-3))"
  ble-edit/draw/put "  $_ble_term_cr$_ble_term_el"
  ble-edit/draw/bflush
}

## 関数 _ble_edit_exec_lines= ble-edit/exec:$bleopt_exec_type/process;
##   指定したコマンドを実行します。
## @param[in,out] _ble_edit_exec_lines
##   実行するコマンドの配列を指定します。実行したコマンドは削除するか空文字列を代入します。
## @return
##   戻り値が 0 の場合、終端 (ble-edit/bind/.tail) に対する処理も行われた事を意味します。
##   つまり、そのまま ble-decode/.hook から抜ける事を期待します。
##   それ以外の場合には終端処理をしていない事を表します。

#--------------------------------------
# bleopt_exec_type = exec
#--------------------------------------

function ble-edit/exec:exec/.eval-TRAPINT {
  builtin echo >&2
  # echo "SIGINT ${FUNCNAME[1]}"
  if ((_ble_bash>=40300)); then
    _ble_edit_exec_INT=130
  else
    _ble_edit_exec_INT=128
  fi
  trap 'ble-edit/exec:exec/.eval-TRAPDEBUG SIGINT "$*" && return' DEBUG
}
function ble-edit/exec:exec/.eval-TRAPDEBUG {
  # 一旦 DEBUG を設定すると bind -x を抜けるまで削除できない様なので、
  # _ble_edit_exec_INT のチェックと _ble_edit_exec_in_eval のチェックを行う。
  if ((_ble_edit_exec_INT&&_ble_edit_exec_in_eval)); then
    builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 ${FUNCNAME[1]} $2" >&2
    return 0
  else
    trap - DEBUG # 何故か効かない
    return 1
  fi
}

function ble-edit/exec:exec/.eval-prologue {
  ble-stty/leave

  set -H

  # C-c に対して
  trap 'ble-edit/exec:exec/.eval-TRAPINT; return 128' INT
  # trap '_ble_edit_exec_INT=126; return 126' TSTP
}
function ble-edit/exec:exec/.save-params {
  _ble_edit_exec_lastarg="$_" _ble_edit_exec_lastexit="$?"
  return "$_ble_edit_exec_lastexit"
}
function ble-edit/exec:exec/.eval {
  local _ble_edit_exec_in_eval=1 nl=$'\n'
  # BASH_COMMAND に return が含まれていても大丈夫な様に関数内で評価
  ble-edit/exec/.setexit
  : "$_ble_edit_exec_lastarg"
  builtin eval -- "$BASH_COMMAND${nl}ble-edit/exec:exec/.save-params"
}
function ble-edit/exec:exec/.eval-epilogue {
  trap - INT DEBUG # DEBUG 削除が何故か効かない

  ble-stty/enter
  _ble_edit_PS1="$PS1"
  _ble_edit_IFS="$IFS"

  ble-edit/exec/.adjust-eol

  # lastexit
  if ((_ble_edit_exec_lastexit==0)); then
    _ble_edit_exec_lastexit="$_ble_edit_exec_INT"
  fi
  if [ "$_ble_edit_exec_lastexit" -ne 0 ]; then
    # SIGERR処理
    if type -t TRAPERR &>/dev/null; then
      TRAPERR
    else
      builtin echo "${_ble_term_setaf[9]}[ble: exit $_ble_edit_exec_lastexit]$_ble_term_sgr0" >&2
    fi
  fi
}

## 関数 ble-edit/exec:exec/.recursive index
##   index 番目のコマンドを実行し、引数 index+1 で自己再帰します。
##   コマンドがこれ以上ない場合は何もせずに終了します。
## @param[in] index
function ble-edit/exec:exec/.recursive {
  (($1>=${#_ble_edit_exec_lines})) && return

  local BASH_COMMAND="${_ble_edit_exec_lines[$1]}"
  _ble_edit_exec_lines[$1]=
  if [[ ${BASH_COMMAND//[ 	]/} ]]; then
    # 実行
    local PS1="$_ble_edit_PS1"
    local IFS="$_ble_edit_IFS"
    local HISTCMD
    ble-edit/history/getcount -v HISTCMD

    local _ble_edit_exec_INT=0
    ble-edit/exec:exec/.eval-prologue
    ble-edit/exec:exec/.eval
    _ble_edit_exec_lastexit="$?"
    ble-edit/exec:exec/.eval-epilogue
  fi

  ble-edit/exec:exec/.recursive "$(($1+1))"
}

_ble_edit_exec_replacedDeclare=
_ble_edit_exec_replacedTypeset=
function ble-edit/exec:exec/.isGlobalContext {
  local offset="$1"

  local path
  for path in "${FUNCNAME[@]:offset+1}"; do
    # source or . が続く限りは遡る (. で呼び出しても FUNCNAME には source が入る様だ。)
    if [[ $path = ble-edit/exec:exec/.eval ]]; then
      return 0
    elif [[ $path != source ]]; then
      # source という名の関数を定義して呼び出している場合、source と区別が付かない。
      # しかし関数と組込では、組込という判定を優先する。
      # (理由は (1) 関数内では普通 local を使う事
      # (2) local になるべき物が global になるのと、
      # global になるべき物が local になるのでは前者の方がまし、という事)
      return 1
    fi
  done

  # BASH_SOURCE は source が関数か builtin か判定するのには使えない
  # local i iN=${#FUNCNAME[@]}
  # for ((i=offset;i<iN;i++)); do
  #   local func="${FUNCNAME[i]}"
  #   local path="${BASH_SOURCE[i]}"
  #   if [[ $func = ble-edit/exec:exec/.eval && $path = $BASH_SOURCE ]]; then
  #     return 0
  #   elif [[ $path != source && $path != $BASH_SOURCE ]]; then
  #     # source ble.sh の中の declare が全て local になるので上だと駄目。
  #     # しかしそもそも二重にロードしても大丈夫な物かは謎。
  #     return 1
  #   fi
  # done

  return 0
}

function ble-edit/exec:exec {
  [[ ${#_ble_edit_exec_lines[@]} -eq 0 ]] && return

  # コマンド内部で declare してもグローバルに定義されない。
  # bash-4.2 以降では -g オプションがあるので declare を上書きする。
  #
  # - -g は変数の作成・変更以外の場合は無視されると man に書かれているので、
  #   変数定義の参照などの場合に影響は与えない。
  # - 既に declare が定義されている場合には上書きはしない。
  #   custom declare に -g を渡す様に書き換えても良いが、
  #   custom declare に -g を指定した時に何が起こるか分からない。
  #   また、custom declare を待避・定義しなければならず実装が面倒。
  # - コマンド内で直接 declare をしているのか、
  #   関数内で declare をしているのかを判定する為に FUNCNAME 変数を使っている。
  #   但し、source という名の関数を定義して呼び出している場合は
  #   source している場合と区別が付かない。この場合は source しているとの解釈を優先させる。
  #
  # ※内部で declare() を上書きされた場合に対応していない。
  # ※builtin declare と呼び出された場合に対しては流石に対応しない
  #
  if ((_ble_bash>=40200)); then
    if ! builtin declare -f declare &>/dev/null; then
      _ble_edit_exec_replacedDeclare=1
      # declare() { builtin declare -g "$@"; }
      declare() {
        if ble-edit/exec:exec/.isGlobalContext 1; then
          builtin declare -g "$@"
        else
          builtin declare "$@"
        fi
      }
    fi
    if ! builtin declare -f typeset &>/dev/null; then
      _ble_edit_exec_replacedTypeset=1
      # typeset() { builtin typeset -g "$@"; }
      typeset() {
        if ble-edit/exec:exec/.isGlobalContext 1; then
          builtin typeset -g "$@"
        else
          builtin typeset "$@"
        fi
      }
    fi
  fi

  # ローカル変数を宣言すると実行されるコマンドから見えてしまう。
  # また、実行されるコマンドで定義される変数のスコープを制限する事にもなるので、
  # ローカル変数はできるだけ定義しない。
  # どうしても定義する場合は、予約識別子名として _ble_ で始まる名前にする。

  # 以下、配列 _ble_edit_exec_lines に登録されている各コマンドを順に実行する。
  # ループ構文を使うと、ループ構文自体がユーザの入力した C-z (SIGTSTP)
  # を受信して(?)停止してしまう様なので、再帰でループする必要がある。
  ble/util/buffer.flush >&2
  ble-edit/exec:exec/.recursive 0

  _ble_edit_exec_lines=()

  # C-c で中断した場合など以下が実行されないかもしれないが
  # 次の呼出の際にここが実行されるのでまあ許容する。
  if [[ $_ble_edit_exec_replacedDeclare ]]; then
    _ble_edit_exec_replacedDeclare=
    unset declare
  fi
  if [[ $_ble_edit_exec_replacedTypeset ]]; then
    _ble_edit_exec_replacedTypeset=
    unset typeset
  fi
}

function ble-edit/exec:exec/process {
  ble-edit/exec:exec
  ble-edit/bind/.check-detach
  return $?
}

#--------------------------------------
# bleopt_exec_type = gexec
#--------------------------------------

function ble-edit/exec:gexec/.eval-TRAPINT {
  builtin echo >&2
  if ((_ble_bash>=40300)); then
    _ble_edit_exec_INT=130
  else
    _ble_edit_exec_INT=128
  fi
  trap 'ble-edit/exec:gexec/.eval-TRAPDEBUG SIGINT "$*" && { return &>/dev/null || break &>/dev/null;}' DEBUG
}
function ble-edit/exec:gexec/.eval-TRAPDEBUG {
  if ((_ble_edit_exec_INT!=0)); then
    # エラーが起きている時

    local IFS=$' \t\n'
    local depth="${#FUNCNAME[*]}"
    local rex='^\ble-edit/exec:gexec/.'
    if ((depth>=2)) && ! [[ ${FUNCNAME[*]:depth-1} =~ $rex ]]; then
      # 関数内にいるが、ble-edit/exec:gexec/. の中ではない時
      builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 ${FUNCNAME[1]} $2" >&2
      return 0
    fi

    local rex='^(\ble-edit/exec:gexec/.|trap - )'
    if ((depth==1)) && ! [[ $BASH_COMMAND =~ $rex ]]; then
      # 一番外側で、ble-edit/exec:gexec/. 関数ではない時
      builtin echo "${_ble_term_setaf[9]}[ble: $1]$_ble_term_sgr0 $BASH_COMMAND $2" >&2
      return 0
    fi
  fi

  trap - DEBUG # 何故か効かない
  return 1
}
function ble-edit/exec:gexec/.begin {
  local IFS=$' \t\n'
  _ble_decode_bind_hook=
  ble-edit/bind/stdout.on
  set -H

  # C-c に対して
  trap 'ble-edit/exec:gexec/.eval-TRAPINT' INT
}
function ble-edit/exec:gexec/.end {
  local IFS=$' \t\n'
  trap - INT DEBUG
  # ↑何故か効かないので、
  #   end の呼び出しと同じレベルで明示的に実行する。

  ble/util/joblist.flush >&2
  ble-edit/bind/.check-detach && return 0
  ble-edit/bind/.tail
}
function ble-edit/exec:gexec/.eval-prologue {
  local IFS=$' \t\n'
  BASH_COMMAND="$1"
  PS1="$_ble_edit_PS1"
  unset HISTCMD; ble-edit/history/getcount -v HISTCMD
  _ble_edit_exec_INT=0
  ble/util/joblist.clear
  ble-stty/leave
  ble-edit/exec/.setexit
}
function ble-edit/exec:gexec/.save-params {
  _ble_edit_exec_lastarg="$_" _ble_edit_exec_lastexit="$?"
  return "$_ble_edit_exec_lastexit"
}
function ble-edit/exec:gexec/.eval-epilogue {
  # lastexit
  _ble_edit_exec_lastexit="$?"
  if ((_ble_edit_exec_lastexit==0)); then
    _ble_edit_exec_lastexit="$_ble_edit_exec_INT"
  fi
  _ble_edit_exec_INT=0

  unset -f builtin
  builtin unset -f builtin return break continue : eval echo

  local IFS=$' \t\n'
  trap - DEBUG # DEBUG 削除が何故か効かない

  ble-stty/enter
  _ble_edit_PS1="$PS1"
  PS1=
  ble-edit/exec/.adjust-eol

  if ((_ble_edit_exec_lastexit)); then
    # SIGERR処理
    if builtin type -t TRAPERR &>/dev/null; then
      TRAPERR
    else
      builtin echo "${_ble_term_setaf[9]}[ble: exit $_ble_edit_exec_lastexit]$_ble_term_sgr0" >&2
    fi
  fi
}
function ble-edit/exec:gexec/.setup {
  # コマンドを _ble_decode_bind_hook に設定してグローバルで評価する。
  #
  # ※ユーザの入力したコマンドをグローバルではなく関数内で評価すると
  #   declare した変数がコマンドローカルになってしまう。
  #   配列でない単純な変数に関しては declare を上書きする事で何とか誤魔化していたが、
  #   declare -a arr=(a b c) の様な特殊な構文の物は上書きできない。
  #   この所為で、例えば source 内で declare した配列などが壊れる。
  #
  ((${#_ble_edit_exec_lines[@]}==0)) && return 1
  ble/util/buffer.flush >&2

  local apos=\' APOS="'\\''"
  local cmd
  local -a buff
  local count=0
  buff[${#buff[@]}]=ble-edit/exec:gexec/.begin
  for cmd in "${_ble_edit_exec_lines[@]}"; do
    if [[ "$cmd" == *[^' 	']* ]]; then
      local nl=$'\n'
      buff[${#buff[@]}]="ble-edit/exec:gexec/.eval-prologue '${cmd//$apos/$APOS}'"
      buff[${#buff[@]}]=': "$_ble_edit_exec_lastarg"' # set $_
      buff[${#buff[@]}]="builtin eval -- '${cmd//$apos/$APOS}${nl}ble-edit/exec:gexec/.save-params'"
      buff[${#buff[@]}]="ble-edit/exec:gexec/.eval-epilogue"
      ((count++))

      # ※直接 $cmd と書き込むと文法的に破綻した物を入れた時に
      #   下の行が実行されない事になってしまう。
    fi
  done
  _ble_edit_exec_lines=()

  ((count==0)) && return 1

  buff[${#buff[@]}]='trap - INT DEBUG' # trap - は一番外側でないと効かない様だ
  buff[${#buff[@]}]=ble-edit/exec:gexec/.end

  IFS=$'\n' builtin eval '_ble_decode_bind_hook="${buff[*]}"'
  return 0
}

function ble-edit/exec:gexec/process {
  ble-edit/exec:gexec/.setup
  return $?
}

# **** accept-line ****                                            @edit.accept

function ble/widget/.insert-newline {
  # 最終状態の描画
  ble-edit/info/hide
  ble-edit/render/update

  # 新しい描画領域
  local -a DRAW_BUFF
  ble-edit/render/goto "$_ble_line_endx" "$_ble_line_endy"
  ble-edit/draw/put "$_ble_term_nl"
  ble-edit/draw/bflush
  ble/util/joblist.bflush

  # 描画領域情報の初期化
  _ble_line_x=0 _ble_line_y=0
  _ble_line_begx=0 _ble_line_begy=0
  _ble_line_endx=0 _ble_line_endy=0
  ((LINENO=++_ble_edit_LINENO))
}

function ble/widget/.newline {
  ble/widget/.insert-newline

  # カーソルを表示する。
  # layer:overwrite でカーソルを消している時の為。
  [[ $_ble_edit_overwrite_mode ]] && ble/util/buffer $'\e[?25h'

  # 行内容の初期化
  _ble_edit_str.reset ''
  _ble_edit_ind=0
  _ble_edit_mark=0
  _ble_edit_mark_active=
  _ble_edit_dirty=-1
  _ble_edit_overwrite_mode=
}

function ble/widget/discard-line {
  _ble_edit_line_disabled=1 ble/widget/.newline
}

if ((_ble_bash>=30100)); then
  function ble-edit/hist_expanded/.expand {
    history -p -- "$BASH_COMMAND" 2>/dev/null || echo "$BASH_COMMAND"
    builtin echo -n :
  }
else
  function ble-edit/hist_expanded/.expand {
    (history -p -- "$BASH_COMMAND" 2>/dev/null || echo "$BASH_COMMAND")
    builtin echo -n :
  }
fi

## @var[out] hist_expanded
function ble-edit/hist_expanded.update {
  local BASH_COMMAND="$*"
  if [[ ! -o histexpand || ! ${BASH_COMMAND//[ 	]} ]]; then
    hist_expanded="$BASH_COMMAND"
    return 0
  elif ble/util/assign hist_expanded ble-edit/hist_expanded/.expand; then
    hist_expanded="${hist_expanded%$_ble_term_nl:}"
    return 0
  else
    return 1
  fi
}

function ble/widget/accept-line {
  local BASH_COMMAND="$_ble_edit_str"

  # 履歴展開
  local hist_expanded
  if ! ble-edit/hist_expanded.update "$BASH_COMMAND"; then
    ble-edit/render/invalidate
    return
  fi

  _ble_edit_mark_active=
  ble/widget/.newline

  if [[ $hist_expanded != "$BASH_COMMAND" ]]; then
    BASH_COMMAND="$hist_expanded"
    ble/util/buffer.print "${_ble_term_setaf[12]}[ble: expand]$_ble_term_sgr0 $BASH_COMMAND"
  fi

  if [[ ${BASH_COMMAND//[ 	]} ]]; then
    ((++_ble_edit_CMD))

    # 編集文字列を履歴に追加
    ble-edit/history/add "$BASH_COMMAND"

    # 実行を登録
    ble-edit/exec/register "$BASH_COMMAND"
  fi
}

function ble/widget/accept-and-next {
  local index count
  ble-edit/history/getindex -v index
  ble-edit/history/getcount -v count

  if ((index+1<count)); then
    local HISTINDEX_NEXT="$((index+1))" # to be modified in accept-line
    ble/widget/accept-line
    ble-edit/history/goto "$HISTINDEX_NEXT"
  else
    local content="$_ble_edit_str"
    ble/widget/accept-line

    ble-edit/history/getcount -v count
    if [[ ${_ble_edit_history[count-1]} == $_ble_edit_str ]]; then
      ble-edit/history/goto "$((count-1))"
    else
      _ble_edit_str.reset "$content"
    fi
  fi
}
function ble/widget/newline {
  KEYS=(10) ble/widget/self-insert
}
function ble/widget/accept-single-line-or {
  if ble-edit/text/is-single-line; then
    ble/widget/accept-line
  else
    ble/widget/"$@"
  fi
}
function ble/widget/accept-single-line-or-newline {
  ble/widget/accept-single-line-or newline
}

# 
#------------------------------------------------------------------------------
# **** history ****                                                    @history

: ${bleopt_history_preserve_point=}
_ble_edit_history=()
_ble_edit_history_edit=()
_ble_edit_history_dirt=()
_ble_edit_history_ind=0

_ble_edit_history_loaded=
_ble_edit_history_count=

function ble-edit/history/getindex {
  local _var=index _ret
  [[ $1 == -v ]] && { _var="$2"; shift 2; }
  if [[ $_ble_edit_history_loaded ]]; then
    (($_var=_ble_edit_history_ind))
  else
    ble-edit/history/getcount -v "$_var"
  fi
}

function ble-edit/history/getcount {
  local _var=count _ret
  [[ $1 == -v ]] && { _var="$2"; shift 2; }

  if [[ $_ble_edit_history_loaded ]]; then
    _ret="${#_ble_edit_history[@]}"
  else
    if [[ ! $_ble_edit_history_count ]]; then
      _ble_edit_history_count=($(history 1))
    fi
    _ret="$_ble_edit_history_count"
  fi

  (($_var=_ret))
}

function ble-edit/history/.generate-source-to-load-history {
  if ! history -p '!1' &>/dev/null; then
    # rcfile として起動すると history が未だロードされていない。
    history -n
  fi
  HISTTIMEFORMAT=__ble_ext__

  # 285ms for 16437 entries
  local apos="'"
  history | command awk -v apos="'" '
    BEGIN{
      n="";
      print "_ble_edit_history=("
    }

    # ※rcfile として読み込むと HISTTIMEFORMAT が ?? に化ける。
    /^ *[0-9]+\*? +(__ble_ext__|\?\?)/{
      if(n!=""){
        n="";
        print "  " apos t apos;
      }

      n=$1;t="";
      sub(/^ *[0-9]+\*? +(__ble_ext__|\?\?)/,"",$0);
    }
    {
      line=$0;
      if(line~/^eval -- \$'$apos'([^'$apos'\\]|\\.)*'$apos'$/)
        line=apos substr(line,9) apos;
      else
        gsub(apos,apos "\\" apos apos,line);

      t=t!=""?t "\n" line:line;
    }
    END{
      if(n!=""){
        n="";
        print "  " apos t apos;
      }

      print ")"
    }
  '
}

## called by ble-edit-initialize
function ble-edit/history/load {
  [[ $_ble_edit_history_loaded ]] && return
  _ble_edit_history_loaded=1

  if ((_ble_edit_attached)); then
    local x="$_ble_line_x" y="$_ble_line_y"
    ble-edit/info/show text "loading history..."

    local -a DRAW_BUFF
    ble-edit/render/goto "$x" "$y"
    ble-edit/draw/flush >&2
  fi

  # * プロセス置換にしてもファイルに書き出しても大した違いはない。
  #   270ms for 16437 entries (generate-source の時間は除く)
  # * プロセス置換×source は bash-3 で動かない。eval に変更する。
  builtin eval -- "$(ble-edit/history/.generate-source-to-load-history)"
  _ble_edit_history_edit=("${_ble_edit_history[@]}")
  _ble_edit_history_count="${#_ble_edit_history[@]}"
  _ble_edit_history_ind="$_ble_edit_history_count"
  if ((_ble_edit_attached)); then
    ble-edit/info/clear
  fi
}

# @var[in,out] HISTINDEX_NEXT
#   used by ble/widget/accept-and-next to get modified next-entry positions
function ble-edit/history/add {
  # 注意: bash-3.2 未満では何故か bind -x の中では常に history off になっている。
  [[ -o history ]] || ((_ble_bash<30200)) || return

  if [[ $_ble_edit_history_loaded ]]; then
    # 登録・不登録に拘わらず取り敢えず初期化
    _ble_edit_history_ind=${#_ble_edit_history[@]}

    # _ble_edit_history_edit を未編集状態に戻す
    local index
    for index in "${!_ble_edit_history_dirt[@]}"; do
      _ble_edit_history_edit[index]="${_ble_edit_history[index]}"
    done
    _ble_edit_history_dirt=()
  fi

  local cmd="$1"
  if [[ $HISTIGNORE ]]; then
    local pats pat
    ble/string#split pats : "$HISTIGNORE"
    for pat in "${pats[@]}"; do
      [[ $cmd == $pat ]] && return
    done
  fi

  local histfile=

  if [[ $_ble_edit_history_loaded ]]; then
    if [[ $HISTCONTROL ]]; then
      local ignorespace ignoredups erasedups spec
      for spec in ${HISTCONTROL//:/ }; do
        case "$spec" in
        (ignorespace) ignorespace=1 ;;
        (ignoredups)  ignoredups=1 ;;
        (ignoreboth)  ignorespace=1 ignoredups=1 ;;
        (erasedups)   erasedups=1 ;;
        esac
      done

      if [[ $ignorespace ]]; then
        [[ $cmd == [' 	']* ]] && return
      fi
      if [[ $ignoredups ]]; then
        local lastIndex=$((${#_ble_edit_history[@]}-1))
        ((lastIndex>=0)) && [[ $cmd == "${_ble_edit_history[lastIndex]}" ]] && return
      fi
      if [[ $erasedups ]]; then
        local indexNext="$HISTINDEX_NEXT"
        local i n=-1 N=${#_ble_edit_history[@]}
        for ((i=0;i<N;i++)); do
          if [[ ${_ble_edit_history[i]} != "$cmd" ]]; then
            if ((++n!=i)); then
              _ble_edit_history[n]="${_ble_edit_history[i]}"
              _ble_edit_history_edit[n]="${_ble_edit_history_edit[i]}"
            fi
          else
            ((i<HISTINDEX_NEXT&&HISTINDEX_NEXT--))
          fi
        done
        for ((i=N-1;i>n;i--)); do
          unset '_ble_edit_history[i]'
          unset '_ble_edit_history_edit[i]'
        done
        [[ ${HISTINDEX_NEXT+set} ]] && HISTINDEX_NEXT=$indexNext
      fi
    fi

    local topIndex=${#_ble_edit_history[@]}
    _ble_edit_history[topIndex]="$cmd"
    _ble_edit_history_edit[topIndex]="$cmd"
    _ble_edit_history_count=$((topIndex+1))
    _ble_edit_history_ind="$_ble_edit_history_count"

    # _ble_bash<30100 の時は必ずここを通る。
    # 初期化時に _ble_edit_history_loaded=1 になるので。
    ((_ble_bash<30100)) && histfile="${HISTFILE:-$HOME/.bash_history}"
  else
    if [[ $HISTCONTROL ]]; then
      # 未だ履歴が初期化されていない場合は取り敢えず history -s に渡す。
      # history -s でも HISTCONTROL に対するフィルタはされる。
      # history -s で項目が追加されたかどうかはスクリプトからは分からないので
      # _ble_edit_history_count は一旦クリアする。
      _ble_edit_history_count=
    else
      # HISTCONTROL がなければ多分 history -s で必ず追加される。
      # _ble_edit_history_count 取得済ならば更新。
      [[ $_ble_edit_history_count ]] &&
        ((_ble_edit_history_count++))
    fi
  fi

  if [[ $cmd == *$'\n'* ]]; then
    # Note: 改行を含む場合は %q は常に $'' の形式になる。
    ble/util/sprintf cmd 'eval -- %q' "$cmd"
  fi

  if [[ $histfile ]]; then
    # bash-3.1 work around
    local tmp="$_ble_base_tmp/$$.ble_edit_history_add.txt"
    builtin printf '%s\n' "$cmd" >> "$histfile"
    builtin printf '%s\n' "$cmd" >| "$tmp"
    history -r "$tmp"
  else
    history -s -- "$cmd"
  fi
}

function ble-edit/history/goto {
  ble-edit/history/load

  local histlen=${#_ble_edit_history[@]}
  local index0="$_ble_edit_history_ind"
  local index1="$1"

  ((index0==index1)) && return

  if ((index1>histlen)); then
    index1=histlen
    ble/widget/.bell
  elif ((index1<0)); then
    index1=0
    ble/widget/.bell
  fi

  ((index0==index1)) && return

  # store
  if [[ ${_ble_edit_history_edit[index0]} != "$_ble_edit_str" ]]; then
    _ble_edit_history_edit[index0]="$_ble_edit_str"
    _ble_edit_history_dirt[index0]=1
  fi

  # restore
  _ble_edit_history_ind="$index1"
  _ble_edit_str.reset "${_ble_edit_history_edit[index1]}"

  # point
  if [[ $bleopt_history_preserve_point ]]; then
    if ((_ble_edit_ind>"${#_ble_edit_str}")); then
      _ble_edit_ind="${#_ble_edit_str}"
    fi
  else
    _ble_edit_ind="${#_ble_edit_str}"
  fi
  _ble_edit_mark=0
  _ble_edit_mark_active=
}

function ble/widget/history-next {
  if [[ $_ble_edit_history_loaded ]]; then
    ble-edit/history/goto $((_ble_edit_history_ind+1))
  else
    ble/widget/.bell
  fi
}
function ble/widget/history-prev {
  ble-edit/history/load # $_ble_edit_history_ind のため
  ble-edit/history/goto $((_ble_edit_history_ind-1))
}
function ble/widget/history-beginning {
  ble-edit/history/goto 0
}
function ble/widget/history-end {
  if [[ $_ble_edit_history_loaded ]]; then
    ble-edit/history/goto "${#_ble_edit_history[@]}"
  else
    ble/widget/.bell
  fi
}

function ble/widget/history-expand-line {
  local hist_expanded
  ble-edit/hist_expanded.update "$_ble_edit_str" || return
  [[ $_ble_edit_str == $hist_expanded ]] && return

  _ble_edit_str.reset "$hist_expanded"
  _ble_edit_ind="${#hist_expanded}"
  _ble_edit_mark=0
  _ble_edit_mark_active=
}
function ble/widget/magic-space {
  KEYS=(32) ble/widget/self-insert

  local prevline="${_ble_edit_str::_ble_edit_ind}" hist_expanded
  ble-edit/hist_expanded.update "$prevline" || return
  [[ $prevline == $hist_expanded ]] && return

  _ble_edit_str.replace 0 _ble_edit_ind "$hist_expanded"
  _ble_edit_ind="${#hist_expanded}"
  _ble_edit_mark=0
  _ble_edit_mark_active=
  #ble/widget/history-expand-line
}

function ble/widget/forward-line-or-history-next {
  ble/widget/forward-line || ((_ble_edit_mark_active)) || ble/widget/history-next
}
function ble/widget/backward-line-or-history-prev {
  ble/widget/backward-line || ((_ble_edit_mark_active)) || ble/widget/history-prev
}


# 
# **** incremental search ****                                 @history.isearch

## 変数 _ble_edit_isearch_str
##   一致した文字列
## 変数 _ble_edit_isearch_dir
##   現在・直前の検索方法
## 配列 _ble_edit_isearch_arr[]
##   インクリメンタル検索の過程を記録する。
##   各要素は ind:dir:beg:end:needle の形式をしている。
##   ind は履歴項目の番号を表す。dir は履歴検索の方向を表す。
##   beg, end はそれぞれ一致開始位置と終了位置を表す。
##   丁度 _ble_edit_ind 及び _ble_edit_mark に対応する。
##   needle は検索に使用した文字列を表す。
## 配列 _ble_edit_isearch_que
##   未処理の操作
_ble_edit_isearch_str=
_ble_edit_isearch_dir=-
_ble_edit_isearch_arr=()
_ble_edit_isearch_que=()

## @var[in] isearch_ntask
function ble-edit/isearch/.draw-line-with-progress {
  # 出力
  local ll rr
  if [[ $_ble_edit_isearch_dir == - ]]; then
    # Emacs work around: '<<' や "<<" と書けない。
    ll=\<\< rr="  "
  else
    ll="  " rr=">>"
    text="  >>)"
  fi
  local histIndex='!'"$((_ble_edit_history_ind+1))"
  local text="(${#_ble_edit_isearch_arr[@]}: $ll $histIndex $rr) \`$_ble_edit_isearch_str'"

  if [[ $1 ]]; then
    local pos="$1"
    local percentage="$((pos*1000/${#_ble_edit_history_edit[@]}))"
    text="$text searching... @$pos ($((percentage/10)).$((percentage%10))%)"
    ((isearch_ntask)) && text="$text *$isearch_ntask"
  fi

  ble-edit/info/show text "$text"
}

function ble-edit/isearch/.draw-line {
  ble-edit/isearch/.draw-line-with-progress
}
function ble-edit/isearch/.erase-line {
  ble-edit/info/default
}
function ble-edit/isearch/.set-region {
  local beg="$1" end="$2"
  if ((beg<end)); then
    if [[ $_ble_edit_isearch_dir == - ]]; then
      _ble_edit_ind="$beg"
      _ble_edit_mark="$end"
    else
      _ble_edit_ind="$end"
      _ble_edit_mark="$beg"
    fi
    _ble_edit_mark_active=S
  else
    _ble_edit_mark_active=
  fi
}
## 関数 ble-edit/isearch/.push-isearch-array
##   現在の isearch の情報を配列 _ble_edit_isearch_arr に待避する。
##
##   これから登録しようとしている情報が現在のものと同じならば何もしない。
##   これから登録しようとしている情報が配列の最上にある場合は、
##   検索の巻き戻しと解釈して配列の最上の要素を削除する。
##   それ以外の場合は、現在の情報を配列に追加する。
##   @var[in] ind beg end needle
##     これから登録しようとしている isearch の情報。
function ble-edit/isearch/.push-isearch-array {
  local hash="$beg:$end:$needle"

  # [... A | B] -> A と来た時 (A を _ble_edit_isearch_arr から削除) [... | A] になる。
  local ilast="$((${#_ble_edit_isearch_arr[@]}-1))"
  if ((ilast>=0)) && [[ ${_ble_edit_isearch_arr[ilast]} == "$ind:"[-+]":$hash" ]]; then
    unset "_ble_edit_isearch_arr[$ilast]"
    return
  fi

  local oind="$_ble_edit_history_ind"
  local obeg="$_ble_edit_ind" oend="$_ble_edit_mark" tmp
  ((obeg<=oend||(tmp=obeg,obeg=oend,oend=tmp)))
  local oneedle="$_ble_edit_isearch_str"
  local ohash="$obeg:$oend:$oneedle"

  # [... A | B] -> B と来た時 (何もしない) [... A | B] になる。
  [[ $ind == "$oind" && $hash == "$ohash" ]] && return

  # [... A | B] -> C と来た時 (B を _ble_edit_isearch_arr に移動) [... A B | C] になる。
  ble/array#push _ble_edit_isearch_arr "$oind:$_ble_edit_isearch_dir:$ohash"
}
function ble-edit/isearch/.goto-match {
  local ind="$1" beg="$2" end="$3" needle="$4"
  ((beg==end&&(beg=end=-1)))

  # 検索履歴に待避 (変数 ind beg end needle 使用)
  ble-edit/isearch/.push-isearch-array

  # 状態を更新
  _ble_edit_isearch_str="$needle"
  [[ $_ble_edit_history_ind != $ind ]] &&
    ble-edit/history/goto "$ind"
  ble-edit/isearch/.set-region "$beg" "$end"

  # isearch 表示
  ble-edit/isearch/.draw-line
  _ble_edit_bind_force_draw=1
}

function ble-edit/isearch/next.fib {
  local needle="${1-$_ble_edit_isearch_str}" isAdd="$2"
  local ind="$_ble_edit_history_ind" beg= end=

  # isAdd -> 現在位置における伸張
  # !isAdd -> 現在一致範囲と重複のない新しい一致
  if [[ $_ble_edit_isearch_dir == - ]]; then
    local target="${_ble_edit_str::(isAdd?_ble_edit_mark+1:_ble_edit_ind)}"
    local m="${target%"$needle"*}"
    if [[ $target != "$m" ]]; then
      beg="${#m}"
      end="$((beg+${#needle}))"
    fi
  else
    local target="${_ble_edit_str:(isAdd?_ble_edit_mark:_ble_edit_ind)}"
    local m="${target#*"$needle"}"
    if [[ $target != "$m" ]]; then
      end="$((${#_ble_edit_str}-${#m}))"
      beg="$((end-${#needle}))"
    fi
  fi

  if [[ $beg ]]; then
    ble-edit/isearch/.goto-match "$ind" "$beg" "$end" "$needle"
    return
  fi

  ble-edit/isearch/next-history.fib "${@:1:1}"
}

## 関数 ble-edit/isearch/next-history.fib [needle isAdd]
##
##   @var[in,out] isearch_suspend
##     中断した時にこの変数に再開用のデータを格納します。
##     再開する時はこの変数の中断時の内容を復元してこの関数を呼び出します。
##     この変数が空の場合は新しい検索を開始します。
##   @param[in,opt] needle,isAdd
##     新しい検索を開始する場合に、検索対象を明示的に指定します。
##     needle に検索対象の文字列を指定します。
##     isAdd 現在の履歴項目を検索対象とするかどうかを指定します。
##   @var[in] _ble_edit_isearch_str
##     最後に一致した検索文字列を指定します。
##     検索対象を明示的に指定しなかった場合に使う検索対象です。
##   @var[in] _ble_edit_history_ind
##     現在の履歴項目の位置を指定します。
##     新しい検索を開始する時の検索開始位置になります。
##
##   @var[in] _ble_edit_isearch_dir
##     現在の検索方向を指定します。
##   @var[in] _ble_edit_history_edit[]
##   @var[in,out] isearch_time
##
## 関数 ble-edit/isearch/next-history/.blockwise-backward-search
##   work around for bash slow array access: blockwise search
##   @var[in,out] i ind susp
##   @var[in,out] isearch_time
##   @var[in] _ble_edit_history_edit start
##
function ble-edit/isearch/next-history/.blockwise-backward-search {
  local NSTPCHK=1000 # 十分高速なのでこれぐらい大きくてOK
  local NPROGRESS=$((NSTPCHK*2)) # 倍数である必要有り
  local irest block j
  while ((i>=0)); do
    ((block=start-i,
      block<5&&(block=5),
      irest=NSTPCHK-isearch_time%NSTPCHK,
      block>i+1&&(block=i+1),
      block>irest&&(block=irest)))

    for ((j=i-block;++j<=i;)); do
      if [[ ${_ble_edit_history_edit[j]} == *"$needle"* ]]; then
        ind="$j"
      fi
    done

    ((isearch_time+=block))
    if [[ $ind ]]; then
      ((i=j))
    else
      ((i-=block))
    fi

    if [[ $ind ]]; then
      break
    elif ((isearch_time%NSTPCHK==0)) && ble/util/is-stdin-ready; then
      susp=1
      break
    elif ((isearch_time%NPROGRESS==0)); then
      ble-edit/isearch/.draw-line-with-progress "$i"
    fi
  done
}
function ble-edit/isearch/next-history.fib {
  if [[ $isearch_suspend ]]; then
    # resume the previous search
    local needle="${isearch_suspend#*:}" isAdd=
    local i start; eval "${isearch_suspend%%:*}"
    isearch_suspend=
  else
    # initialize new search
    local needle="${1-$_ble_edit_isearch_str}" isAdd="$2"
    local start="$_ble_edit_history_ind"
    local i="$start"
  fi

  local dir="$_ble_edit_isearch_dir"
  if [[ $dir == - ]]; then
    # backward-search
    local x_cond='i>=0' x_incr='i--'
  else
    # forward-search
    local x_cond="i<${#_ble_edit_history_edit[@]}" x_incr='i++'
  fi
  ((isAdd||x_incr))

  # 検索
  local ind= susp=
  if [[ $dir == - ]]; then
    ble-edit/isearch/next-history/.blockwise-backward-search
  else
    for ((;x_cond;x_incr)); do
      if ((++isearch_time%100==0)) && ble/util/is-stdin-ready; then
        susp=1
        break
      fi
      if [[ ${_ble_edit_history_edit[i]} == *"$needle"* ]]; then
        ind="$i"
        break
      fi

      if ((isearch_time%1000==0)); then
        ble-edit/isearch/.draw-line-with-progress "$i"
      fi
    done
  fi

  if [[ $ind ]]; then
    # 見付かった場合

    # 一致範囲 beg-end を取得
    local str="${_ble_edit_history_edit[ind]}"
    if [[ $_ble_edit_isearch_dir == - ]]; then
      local prefix="${str%"$needle"*}"
    else
      local prefix="${str%%"$needle"*}"
    fi
    local beg="${#prefix}" end="$((${#prefix}+${#needle}))"

    ble-edit/isearch/.goto-match "$ind" "$beg" "$end" "$needle"
  elif [[ $susp ]]; then
    # 中断した場合
    isearch_suspend="i=$i start=$start:$needle"
    return
  else
    # 見つからなかった場合
    ble/widget/.bell "isearch: \`$needle' not found"
    return
  fi
}

function ble-edit/isearch/forward.fib {
  _ble_edit_isearch_dir=+
  ble-edit/isearch/next.fib
}
function ble-edit/isearch/backward.fib {
  _ble_edit_isearch_dir=-
  ble-edit/isearch/next.fib
}
function ble-edit/isearch/self-insert.fib {
  local code="$1"
  ((code==0)) && return
  local ret needle
  ble/util/c2s "$code"
  ble-edit/isearch/next.fib "$_ble_edit_isearch_str$ret" 1
}
function ble-edit/isearch/history-forward.fib {
  _ble_edit_isearch_dir=+
  ble-edit/isearch/next-history.fib
}
function ble-edit/isearch/history-backward.fib {
  _ble_edit_isearch_dir=-
  ble-edit/isearch/next-history.fib
}
function ble-edit/isearch/history-self-insert.fib {
  local code="$1"
  ((code==0)) && return
  local ret needle
  ble/util/c2s "$code"
  ble-edit/isearch/next-history.fib "$_ble_edit_isearch_str$ret" 1
}

function ble-edit/isearch/prev {
  local sz="${#_ble_edit_isearch_arr[@]}"
  ((sz==0)) && return 0

  local ilast=$((sz-1))
  local top="${_ble_edit_isearch_arr[ilast]}"
  unset "_ble_edit_isearch_arr[$ilast]"

  local ind dir beg end
  ind="${top%%:*}"; top="${top#*:}"
  dir="${top%%:*}"; top="${top#*:}"
  beg="${top%%:*}"; top="${top#*:}"
  end="${top%%:*}"; top="${top#*:}"

  _ble_edit_isearch_dir="$dir"
  ble-edit/history/goto "$ind"
  ble-edit/isearch/.set-region "$beg" "$end"
  _ble_edit_isearch_str="$top"

  # isearch 表示
  ble-edit/isearch/.draw-line
}

function ble-edit/isearch/process {
  _ble_edit_isearch_que=()

  local isearch_suspend=
  local isearch_time=0
  local isearch_ntask="$#"
  while (($#)); do
    ((isearch_ntask--))
    case "$1" in
    (sf)  ble-edit/isearch/forward.fib ;;
    (sb)  ble-edit/isearch/backward.fib ;;
    (si*) ble-edit/isearch/self-insert.fib "${1:2}";;
    (hf)  ble-edit/isearch/history-forward.fib ;;
    (hb)  ble-edit/isearch/history-backward.fib ;;
    (hi*) ble-edit/isearch/history-self-insert.fib "${1:2}";;
    (z*)  isearch_suspend="${1:1}"
          ble-edit/isearch/next-history.fib;;
    (*)   ble-stackdump "unknown isearch process entry '$1'." ;;
    esac
    shift

    if [[ $isearch_suspend ]]; then
      _ble_edit_isearch_que=("z$isearch_suspend" "$@")
      return
    fi
  done

  # 検索処理が完了した時
  ble-edit/isearch/.draw-line
}

function ble/widget/isearch/forward {
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" sf
}
function ble/widget/isearch/backward {
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" sb
}
function ble/widget/isearch/self-insert {
  local code="$((KEYS[0]&ble_decode_MaskChar))"
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" "si$code"
}
function ble/widget/isearch/history-forward {
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" hf
}
function ble/widget/isearch/history-backward {
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" hb
}
function ble/widget/isearch/history-self-insert {
  local code="$((KEYS[0]&ble_decode_MaskChar))"
  ble-edit/isearch/process "${_ble_edit_isearch_que[@]}" "hi$code"
}
function ble/widget/isearch/prev {
  local nque
  if ((nque=${#_ble_edit_isearch_que[@]})); then
    unset _ble_edit_isearch_que[nque-1]
    if ((nque>=2)); then
      ble-edit/isearch/process "${_ble_edit_isearch_que[@]}"
    else
      ble-edit/isearch/.draw-line # 進捗状況を消去
    fi
  else
    ble-edit/isearch/prev
  fi
}
function ble/widget/isearch/exit {
  ble-decode/keymap/pop
  _ble_edit_isearch_arr=()
  _ble_edit_isearch_dir=
  _ble_edit_isearch_que=()
  _ble_edit_isearch_str=
  ble-edit/isearch/.erase-line
}
function ble/widget/isearch/cancel {
  if ((${#_ble_edit_isearch_que[@]})); then
    _ble_edit_isearch_que=()
    ble-edit/isearch/.draw-line # 進捗状況を消去
  else
    if ((${#_ble_edit_isearch_arr[@]})); then
      local step
      ble/string#split step : "${_ble_edit_isearch_arr[0]}"
      ble-edit/history/goto "${step[0]}"
      _ble_edit_ind=${step[2]} _ble_edit_mark=${step[3]}
    fi

    ble/widget/isearch/exit
  fi
}
function ble/widget/isearch/exit-default {
  ble/widget/isearch/exit
  ble-decode-key "${KEYS[@]}"
}
function ble/widget/isearch/accept {
  if ((${#_ble_edit_isearch_que[@]})); then
    ble/widget/.bell "isearch: now searching..."
  else
    ble/widget/isearch/exit
    ble/widget/accept-line
  fi
}
function ble/widget/isearch/exit-delete-forward-char {
  ble/widget/isearch/exit
  ble/widget/delete-forward-char
}

function ble/widget/history-isearch-backward {
  ble-edit/history/load
  ble-decode/keymap/push isearch
  _ble_edit_isearch_dir=-
  _ble_edit_isearch_arr=()
  _ble_edit_isearch_que=()
  _ble_edit_mark="$_ble_edit_ind"
  ble-edit/isearch/.draw-line
}
function ble/widget/history-isearch-forward {
  ble-edit/history/load
  ble-decode/keymap/push isearch
  _ble_edit_isearch_dir=+
  _ble_edit_isearch_arr=()
  _ble_edit_isearch_que=()
  _ble_edit_mark="$_ble_edit_ind"
  ble-edit/isearch/.draw-line
}

# 
#------------------------------------------------------------------------------
# **** completion ****                                                    @comp

ble-autoload "$_ble_base/complete.sh" ble/widget/complete

function ble/widget/command-help {
  local -a args
  args=($_ble_edit_str)
  local cmd="${args[0]}"

  if [[ ! $cmd ]]; then
    ble/widget/.bell
    return 1
  fi

  if ! type -t "$cmd" &>/dev/null; then
    ble/widget/.bell "command \`$cmd' not found"
    return 1
  fi

  local content
  if content="$("$cmd" --help 2>&1)" && [[ $content ]]; then
    ble/util/buffer.flush >&2
    builtin printf '%s\n' "$content" | ble/util/less
    return
  fi

  if content="$(command man "$cmd" 2>&1)" && [[ $content ]]; then
    ble/util/buffer.flush >&2
    builtin printf '%s\n' "$content" | ble/util/less
    return
  fi

  ble/widget/.bell "help of \`$cmd' not found"
  return 1
}

# 
#------------------------------------------------------------------------------
# **** bash key binder ****                                               @bind

# **** binder ****                                                   @bind.bind

function ble-edit/bind/stdout.on { :;}
function ble-edit/bind/stdout.off { ble/util/buffer.flush >&2;}
function ble-edit/bind/stdout.finalize { :;}

if [[ $bleopt_suppress_bash_output ]]; then
  _ble_edit_io_stdout=
  _ble_edit_io_stderr=
  if ((_ble_bash>40100)); then
    exec {_ble_edit_io_stdout}>&1
    exec {_ble_edit_io_stderr}>&2
  else
    ble/util/openat _ble_edit_io_stdout '>&1'
    ble/util/openat _ble_edit_io_stderr '>&2'
  fi
  _ble_edit_io_fname1="$_ble_base_tmp/$$.stdout"
  _ble_edit_io_fname2="$_ble_base_tmp/$$.stderr"

  function ble-edit/bind/stdout.on {
    exec 1>&$_ble_edit_io_stdout 2>&$_ble_edit_io_stderr
  }
  function ble-edit/bind/stdout.off {
    ble/util/buffer.flush >&2
    ble-edit/bind/stdout/check-stderr
    exec 1>>$_ble_edit_io_fname1 2>>$_ble_edit_io_fname2
  }
  function ble-edit/bind/stdout.finalize {
    ble-edit/bind/stdout.on
    [[ -f $_ble_edit_io_fname1 ]] && command rm -f "$_ble_edit_io_fname1"
    [[ -f $_ble_edit_io_fname2 ]] && command rm -f "$_ble_edit_io_fname2"
  }

  ## 関数 ble-edit/bind/stdout/check-stderr
  ##   bash が stderr にエラーを出力したかチェックし表示する。
  function ble-edit/bind/stdout/check-stderr {
    local file="${1:-$_ble_edit_io_fname2}"

    # if the visible bell function is already defined.
    if ble/util/isfunction ble-term/visible-bell; then
      # checks if "$file" is an ordinary non-empty file
      #   since the $file might be /dev/null depending on the configuration.
      #   /dev/null の様なデバイスではなく、中身があるファイルの場合。
      if [[ -f $file && -s $file ]]; then
        local message= line
        while IFS= read -r line || [[ $line ]]; do
          # * The head of error messages seems to be ${BASH##*/}.
          #   例えば ~/bin/bash-3.1 等から実行していると
          #   "bash-3.1: ～" 等というエラーメッセージになる。
          if [[ $line == 'bash: '* || $line == "${BASH##*/}: "* ]]; then
            message="$message${message:+; }$line"
          fi
        done < "$file"

        [[ $message ]] && ble-term/visible-bell "$message"
        : >| "$file"
      fi
    fi
  }

  # * bash-3.1, bash-3.2, bash-4.0 では C-d は直接検知できない。
  #   IGNOREEOF を設定しておくと C-d を押した時に
  #   stderr に bash が文句を吐くのでそれを捕まえて C-d が押されたと見做す。
  if ((_ble_bash<40000)); then
    function ble-edit/bind/stdout/TRAPUSR1 {
      local IFS=$' \t\n'
      local file="$_ble_edit_io_fname2.proc"
      if [[ -s $file ]]; then
        content="$(< $file)"
        : >| "$file"
        for cmd in $content; do
          case "$cmd" in
          (eof)
            # C-d
            ble-decode/.hook 4 ;;
          esac
        done
      fi
    }

    trap -- 'ble-edit/bind/stdout/TRAPUSR1' USR1

    command rm -f "$_ble_edit_io_fname2.pipe"
    command mkfifo "$_ble_edit_io_fname2.pipe"
    {
      {
        function ble-edit/stdout/check-ignoreeof-message {
          local line="$1"

          [[ $line = *$bleopt_ignoreeof_message* ||
               $line = *'Use "exit" to leave the shell.'* ||
               $line = *'ログアウトする為には exit を入力して下さい'* ||
               $line = *'シェルから脱出するには "exit" を使用してください。'* ||
               $line = *'シェルから脱出するのに "exit" を使いなさい.'* ||
               $line = *'Gebruik Kaart na Los Tronk'* ]] && return 0

          # ignoreeof-messages.txt の中身をキャッシュする様にする?
          [[ $line == *exit* ]] && command grep -q -F "$line" "$_ble_base"/ignoreeof-messages.txt
        }

        while IFS= read -r line; do
          SPACE=$' \n\t'
          if [[ $line == *[^$SPACE]* ]]; then
            builtin printf '%s\n' "$line" >> "$_ble_edit_io_fname2"
          fi

          if [[ $bleopt_ignoreeof_message ]] && ble-edit/stdout/check-ignoreeof-message "$line"; then
            builtin echo eof >> "$_ble_edit_io_fname2.proc"
            kill -USR1 $$
            ble/util/sleep 0.1 # 連続で送ると bash が落ちるかも (落ちた事はないが念の為)
          fi
        done < "$_ble_edit_io_fname2.pipe"
      } &>/dev/null & disown
    } &>/dev/null

    ble/util/openat _ble_edit_fd_stderr_pipe '> "$_ble_edit_io_fname2.pipe"'

    function ble-edit/bind/stdout.off {
      ble/util/buffer.flush >&2
      ble-edit/bind/stdout/check-stderr
      exec 1>>$_ble_edit_io_fname1 2>&$_ble_edit_fd_stderr_pipe
    }
  fi
fi

_ble_edit_detach_flag=
function ble-edit/bind/.exit-TRAPRTMAX {
  # シグナルハンドラの中では stty は bash によって設定されている。
  local IFS=$' \t\n'
  ble-stty/TRAPEXIT
  exit 0
}

## 関数 ble-edit/bind/.check-detach
##
##   @exit detach した場合に 0 を返します。それ以外の場合に 1 を返します。
##
function ble-edit/bind/.check-detach {
  if [[ ! -o emacs && ! -o vi ]]; then
    # 実は set +o emacs などとした時点で eval の評価が中断されるので、これを検知することはできない。
    # 従って、現状ではここに入ってくることはないようである。
    builtin echo "${_ble_term_setaf[9]}[ble: unsupported]$_ble_term_sgr0 Sorry, ble.sh is supported only with some editing mode (set -o emacs/vi)." 1>&2
    ble-detach
  fi

  if [[ $_ble_edit_detach_flag ]]; then
    type="$_ble_edit_detach_flag"
    _ble_edit_detach_flag=
    #ble-term/visible-bell ' Bye!! '

    ble-edit-finalize
    ble-decode-detach
    ble-stty/finalize

    READLINE_LINE="" READLINE_POINT=0

    if [[ $type == exit ]]; then
      # ※この部分は現在使われていない。
      #   exit 時の処理は trap EXIT を用いて行う事に決めた為。
      #   一応 _ble_edit_detach_flag=exit と直に入力する事で呼び出す事はできる。

      # exit
      ble/util/buffer.flush >&2
      builtin echo "${_ble_term_setaf[12]}[ble: exit]$_ble_term_sgr0" 1>&2
      ble-edit/info/hide
      ble-edit/render/update
      ble/util/buffer.flush >&2

      # bind -x の中から exit すると bash が stty を「前回の状態」に復元してしまう様だ。
      # シグナルハンドラの中から exit すれば stty がそのままの状態で抜けられる様なのでそうする。
      trap 'ble-edit/bind/.exit-TRAPRTMAX' RTMAX
      kill -RTMAX $$
    else
      ble/util/buffer.flush >&2
      builtin echo "${_ble_term_setaf[12]}[ble: detached]$_ble_term_sgr0" 1>&2
      builtin echo "Please run \`stty sane' to recover the correct TTY state." >&2
      ble-edit/render/update
      ble/util/buffer.flush >&2
      READLINE_LINE='stty sane' READLINE_POINT=9
    fi

    return 0
  else
    # Note: ここに入った時 -o emacs か -o vi のどちらかが成立する。なぜなら、
    #   [[ ! -o emacs && ! -o vi ]] のときは ble-detach が呼び出されるのでここには来ない。
    local state=$_ble_decode_bind_state
    if [[ ( $state == emacs || $state == vi ) && ! -o $state ]]; then
      ble-decode-detach
      ble-decode-attach
    fi

    return 1
  fi
}

if ((_ble_bash>=40100)); then
  function ble-edit/bind/.head {
    ble-edit/bind/stdout.on

    if [[ -z $bleopt_suppress_bash_output ]]; then
      # bash-4.1 以降では呼出直前にプロンプトが消される
      ble-edit/render/redraw-cache
      ble/util/buffer.flush >&2
    fi
  }
else
  function ble-edit/bind/.head {
    ble-edit/bind/stdout.on

    if [[ -z $bleopt_suppress_bash_output ]]; then
      # bash-3.*, bash-4.0 では呼出直前に次の行に移動する
      ((_ble_line_y++,_ble_line_x=0))
      local -a DRAW_BUFF=()
      ble-edit/render/goto "${_ble_edit_cur[0]}" "${_ble_edit_cur[1]}"
      ble-edit/draw/flush
    fi
  }
fi

function ble-edit/bind/.tail-without-draw {
  ble-edit/bind/stdout.off
}

if ((_ble_bash>40000)); then
  function ble-edit/bind/.tail {
    ble-edit/info/reveal
    ble-edit/render/update-adjusted
    ble-edit/bind/stdout.off
  }
else
  IGNOREEOF=10000
  function ble-edit/bind/.tail {
    ble-edit/info/reveal
    ble-edit/render/update # bash-3 では READLINE_LINE を設定する方法はないので常に 0 幅
    ble-edit/bind/stdout.off
  }
fi

_ble_edit_bind_force_draw=

## ble-decode.sh 用の設定
function ble-decode/PROLOGUE {
  ble-edit/bind/.head
  ble-decode-bind/uvw
  ble-stty/enter
  _ble_edit_bind_force_draw=
}

## ble-decode.sh 用の設定
function ble-decode/EPILOGUE {
  if ((_ble_bash>=40000)); then
    # 貼付対策:
    #   大量の文字が入力された時に毎回再描画をすると滅茶苦茶遅い。
    #   次の文字が既に来て居る場合には描画処理をせずに抜ける。
    #   (再描画は次の文字に対する bind 呼出でされる筈。)
    if [[ ! $_ble_edit_bind_force_draw ]] && ble/util/is-stdin-ready; then
      ble-edit/bind/.tail-without-draw
      return 0
    fi
  fi

  # _ble_decode_bind_hook で bind/tail される。
  "ble-edit/exec:$bleopt_exec_type/process" && return 0

  ble-edit/bind/.tail
  return 0
}

## 関数 ble/widget/.SHELL_COMMAND command
##   ble-bind -cf で登録されたコマンドを処理します。
function ble/widget/.SHELL_COMMAND {
  local -a BASH_COMMAND
  BASH_COMMAND=("$*")

  ble/widget/.insert-newline

  # やはり通常コマンドはちゃんとした環境で評価するべき
  if [[ "${BASH_COMMAND//[ 	]/}" ]]; then
    ble-edit/exec/register "$BASH_COMMAND"
  fi

  ble-edit/render/invalidate
}

## 関数 ble/widget/.EDIT_COMMAND command
##   ble-bind -xf で登録されたコマンドを処理します。
function ble/widget/.EDIT_COMMAND {
  local READLINE_LINE="$_ble_edit_str"
  local READLINE_POINT="$_ble_edit_ind"
  eval "$command" || return 1

  [[ $READLINE_LINE != $_ble_edit_str ]] &&
    _ble_edit_str.reset-and-check-dirty "$READLINE_LINE"
  [[ $READLINE_POINT != $_ble_edit_ind ]] &&
    ble/widget/.goto-char "$READLINE_POINT"
}

## ble-decode.sh 用の設定
function ble-decode/DEFAULT_KEYMAP {
  if [[ $bleopt_default_keymap == auto ]]; then
    if [[ -o vi ]]; then
      ble-edit/load-keymap-definition vi
      builtin eval "$2=vi_insert"
    else
      ble-edit/load-keymap-definition emacs
      builtin eval "$2=emacs"
    fi
  elif [[ $bleopt_default_keymap == vi ]]; then
    ble-edit/load-keymap-definition vi
    builtin eval "$2=vi_insert"
  else
    ble-edit/load-keymap-definition "$bleopt_default_keymap"
    builtin eval "$2=\"\$bleopt_default_keymap\""
  fi
}

function ble-edit/load-keymap-definition:emacs {
  function ble-edit/load-keymap-definition:emacs { :; }

  local fname_keymap_cache=$_ble_base_cache/keymap.emacs
  if [[ $fname_keymap_cache -nt $_ble_base/keymap/emacs.sh &&
          $fname_keymap_cache -nt $_ble_base/keymap/isearch.sh &&
          $fname_keymap_cache -nt $_ble_base/cmap/default.sh ]]; then
    source "$fname_keymap_cache"
  else
    source "$_ble_base/keymap/emacs.sh"
  fi
}

function ble-edit/load-keymap-definition {
  local name=$1
  if ble/util/isfunction ble-edit/load-keymap-definition:"$name"; then
    ble-edit/load-keymap-definition:"$name"
  else
    source "$_ble_base/keymap/$name.sh"
  fi
}

function ble-edit-initialize {
  ble-edit/prompt/initialize
}
function ble-edit-attach {
  if ((_ble_bash>=30100)) && [[ $bleopt_history_lazyload ]]; then
    _ble_edit_history_loaded=
  else
    # * history-load は initialize ではなく attach で行う。
    #   detach してから attach する間に
    #   追加されたエントリがあるかもしれないので。
    # * bash-3.0 では history -s は最近の履歴項目を置換するだけなので、
    #   履歴項目は全て自分で処理する必要がある。
    #   つまり、初めから load しておかなければならない。
    ble-edit/history/load
  fi

  ble-edit/attach
  _ble_line_x=0 _ble_line_y=0
  ble/util/buffer "$_ble_term_cr"
}
function ble-edit-finalize {
  ble-edit/bind/stdout.finalize
  ble-edit/detach
}
