#!/usr/bin/env ksh

# Copyright 2021 hyenias <https://github.com/hyenias>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set --noglob # turn off globbing

USAGE=$'[-]
[-program?arrmath.ksh]
[-?0.1 2021-04-27]
[-author?hyenias <https://github.com/hyenias>]
[-copyright?(c) 2021 https://github.com/hyenias]
[-license?https://www.apache.org/licenses/LICENSE-2.0]
[+DESCRIPTION?Arithmetic array value testing script]
[a:all?Iterate over all array subscripts]
[d:debug?Debugging levels as follows:]#?[level:=0]{
[0  =?Total errors count]
[1  =?+ errors displayed]
[2  =?++ \btypeset -p arr\b for each error]
[3  =?+++ print header for each test]
[4  =?++++ verbose]
}
[l:limit?Limit tests to homogeneous multidimensional arrays of type:]:?[atype]{
[i:indexed?Indexed arrays, typeset -a arr]
[a:associative?Associative arrays, typeset -A arr]
[c:compound?Compound variable arrays, typeset -C arr]
[f:fixed   ?Fixed width indexed arrays, typeset -a arr[3]][3]] ]
}
[n:numeric?Filter out only specified numerics: NA, i, si, li, ui, usi, uli, F, E, X, lF, lE, lX.]:[ntype]
[o:op?Test only this specified arithmetic operation: ++, --, +=1, -=1, *=2, /=2, %=8, <<=1, >>=1, |=64, &=7, ^=42, =99, etc.]:[aop]
[t:test?Run using the provided test]:{
[Test Examples (must end with a colon)]
[\b-a NA e --::\b = indexed array using arr++]
[\b-A NA b --::\b = associative array using ++arr]
[\b-C -i e *=2::\b = compound variable array of integers using arr*=2]
[\b-f -F1 e =99::\b = fixed width indexed array of floats with precision of 1 using arr=99]
]}
'

ALLSUBS='N'
DEBUG=0
LIMITARR=''
NTYPE=''
AOP=''
TEST=''

while getopts "$USAGE" opt
do
	case $opt in
	a )	ALLSUBS='Y'
		;;
	d )	case $OPTARG in
		0 )	;&
		1 )	;&
		2 )	;& 
		3 )	;&
		4 )	DEBUG=$OPTARG
			;;
		esac
		;;
	l )	case $OPTARG in
		i )	LIMITARR='-a' # indexed arrays
			;;
		a )	LIMITARR='-A' # associtive arrays
			;;
		c )	LIMITARR='-C' # compound variable arrays
			;;
		f )	LIMITARR='-f' # fixed width indexed arrays
			;;
		esac
		;;
	n )	case "$OPTARG" in
		i|si|li|ui|usi|uli ) ;&
		    F|E|X|lF|lE|lX ) NTYPE="-$OPTARG"
			;;
		''|NA )	NTYPE='NA'
			;;
		esac
		;;
	o )	AOP="$OPTARG"
		;;
	t )	TEST="$OPTARG"
		;;
	esac
done
shift $(($OPTIND-1))

typeset -i errors=0
ini_a() { unset arr; typeset -a ${numeric} arr=((6 10 14) 22 26); }
ini_A() { unset arr; typeset -A ${numeric} arr=([b]=22 [c]=26); arr[a]=([i]=6 [ii]=10 [iii]=14); }
ini_C() { unset arr; typeset -C arr=(a=(typeset $numeric i=6 ii=10 iii=14); typeset $numeric b=22 c=26); }
ini_f() { unset arr; typeset -a ${numeric} arr[3][3]; arr=( (3 5 7) (11 13 17) (19 23 29) ); }

apply_formatting()
{
	# New values of compounds or associatives lack formatting modifiers
	if [[ -n $numeric ]]
	then
		if [[ $atype == '-C' ]]
		then
			case $a_idx in
			  '.a.iv' )	;&
			     '.d' )	;&
			'[a][iv]' )	;&
			    '[d]' )	typeset $numeric $aref
					;; # All other subscripts should be formatted
			esac
		fi
		# issues with formatting associatives
		[[ $atype == '-A' ]] && typeset $numeric $aref
	fi
}

errormsg()
{
	if [[ -n $header ]]
	then
		(( DEBUG > 0 )) && echo "Error: $header"
		header=''
	fi
	(( DEBUG > 0 )) && echo '      '$1
	(( DEBUG > 1 )) && { print -n '\t'; typeset -p arr; }
	errors+=1
}

ini='' # Reference to initialization function for particular test
while read line
do
	[[ -n $TEST ]] && line=$TEST
	[[ ${line:0:1} == '#' ]] && continue # Allow comment lines in input data
	while read -d ':' atype numeric tst op # Each individual test record ends with a colon
	do
		[[ -n $LIMITARR && $LIMITARR != "$atype" ]] && continue
		[[ -n $NTYPE && $NTYPE != "$numeric" ]] && continue
		[[ -n $AOP && $AOP != "$op" ]] && continue
		header=${ printf -- '---------->> %s :  %4s  : %s :  %4s  <<----------' $atype $numeric $tst $op; }
		(( DEBUG > 2 )) && echo "$header"
		numeric=${numeric%NA} # Turn placeholder of NA into '' for no numeric type nor formatting
		unset cmp bares bsres sval
		typeset ${numeric} cmp bares bsres sval
		if [[ $atype == '-a' ]]
		then
			ini='ini_a'
			indices=('' '[0]' '[0][0]' '[0][1]' '[0][2]' '[0][3]' '[1]' '[2]' '[3]')
		elif [[ $atype == '-A' ]]
		then
			ini='ini_A'
			indices=('[a][i]' '[a][ii]' '[a][iii]' '[a][iv]' '[b]' '[c]' '[d]')
		elif [[ $atype == '-C' ]]
		then
			ini='ini_C'
			indices=('.a.i' '.a.ii' '.a.iii' '.a.iv' '.b' '.c' '.d')
		elif [[ $atype == '-f' ]]
		then
			ini='ini_f'
			indices=('[0][0]' '[0][1]' '[0][2]' '[1][0]' '[1][1]' '[1][2]' '[2][0]' '[2][1]' '[2][2]')
		else
			echo "Error: Unknown or missing container type of '${atype}'."
			continue 
		fi
		val=${op#*=} # value only if present
		opr=${.sh.match} # assignment operator only, unary will be empty string
		if [[ $ALLSUBS == 'Y' && -n op ]]
		then
			b_indices="$val ""$( printf 'arr%s ' "${indices[@]}"; )"
		else
			b_indices="$val"
		fi
		for a_idx in "${indices[@]}"
		do
			$ini # initialize arr
			aref="arr${a_idx}"
			eval "cmp=\${$aref}" # save original array value for comparison
			case $tst in
			b )	scmd="${op}cmp" # scalar
				acmd="${op}${aref}" # array 
				(( $scmd ))
				(( $acmd ))
				apply_formatting
				eval "ares=\${$aref}"
				if [[ $ares != "$cmp" ]]
				then
					errormsg "Error: ${acmd} value is '${ares}' should be '${cmp}'."
				fi
				(( DEBUG > 3 )) && { printf '%10s: ' $aref; typeset -p arr; }
				;;
			e )	for b_idx in $b_indices
				do
					sval=${cmp}
					if [[ -n $opr ]]
					then	# Assignment operators, arr[0][1]+=arr[0]
						if [[ $opr == '/=' || $opr == '%=' ]]
						then
							(( ${b_idx} == 0 )) && continue # avoid division by zero
							if [[ $atype == '-a' && ( ${b_idx} == 'arr' || ${b_idx} == 'arr[0]' ) ]]
							then
								# cannot perform /= or %= using default referencing of arr or arr[0]
								# but full subscript referencing works aka arr[0][0]
								continue
							fi
						fi
						scmd="sval${opr}${b_idx}"
						acmd="${aref}${opr}${b_idx}"
						(( $scmd ))
						(( $acmd ))
					else # opr=''
						scmd="sval${op}" # unary
						acmd="${aref}${op}"
						bsres=$(( $scmd ))
						bares=$(( $acmd ))
					fi
					apply_formatting
					eval "ares=\${$aref}"
					if [[ $atype == '-A' && -n $numeric ]]
					then
						# For -A only the top row outputs with formatting, so switch to ((...)) instead of [[...]]
						if [[ -z $opr ]] && (( $bares != $bsres ))
						then
							errormsg "Error: ${acmd} before value is '${bares}' should be '${bsres}'."
						fi
						if (( $ares != $sval ))
						then
							errormsg "Error: ${acmd} result value is '${ares}' should be '${sval}'."
						fi
					else
						if [[ -z $opr ]] && [[ $bares != "$bsres" ]]
						then
							errormsg "Error: ${acmd} before value is '${bares}' should be '${bsres}'."
						fi
						if [[ $ares != "$sval" ]]
						then
							errormsg "Error: ${acmd} result value is '${ares}' should be '${sval}'."
						fi
					fi
					(( DEBUG > 3 )) && { printf '%10s: ' $aref; typeset -p arr; }
					$ini # reset arr
				done # b_idx loop
				;;
			* )	echo "Error: unknown test placement of '$tst' given. Placement must be either 'b' or 'e'."
				;;
			esac
		done # a_idx loop
		[[ -n $TEST ]] && break 2
	done <<< "$line" # field parsing loop
done <<-EOF
# Fixed width indexed arrays
-f NA b --:-f NA b ++:-f NA e --:-f NA e ++:-f NA e +=1:-f NA e -=1:-f NA e *=2:-f NA e /=2:-f NA e %=8:-f NA e <<=1:-f NA e >>=1:-f NA e |=64:-f NA e &=7:-f NA e ^=42:-f NA e =99:
-f -i b --:-f -i b ++:-f -i e --:-f -i e ++:-f -i e +=1:-f -i e -=1:-f -i e *=2:-f -i e /=2:-f -i e %=8:-f -i e <<=1:-f -i e >>=1:-f -i e |=64:-f -i e &=7:-f -i e ^=42:-f -i e =99:
-f -ui b --:-f -ui b ++:-f -ui e --:-f -ui e ++:-f -ui e +=1:-f -ui e -=1:-f -ui e *=2:-f -ui e /=2:-f -ui e %=8:-f -ui e <<=1:-f -ui e >>=1:-f -ui e |=64:-f -ui e &=7:-f -ui e ^=42:-f -ui e =99:
-f -si b --:-f -si b ++:-f -si e --:-f -si e ++:-f -si e +=1:-f -si e -=1:-f -si e *=2:-f -si e /=2:-f -si e %=8:-f -si e <<=1:-f -si e >>=1:-f -si e |=64:-f -si e &=7:-f -si e ^=42:-f -si e =99:
-f -usi b --:-f -usi b ++:-f -usi e --:-f -usi e ++:-f -usi e +=1:-f -usi e -=1:-f -usi e *=2:-f -usi e /=2:-f -usi e %=8:-f -usi e <<=1:-f -usi e >>=1:-f -usi e |=64:-f -usi e &=7:-f -usi e ^=42:-f -usi e =99:
-f -li b --:-f -li b ++:-f -li e --:-f -li e ++:-f -li e +=1:-f -li e -=1:-f -li e *=2:-f -li e /=2:-f -li e %=8:-f -li e <<=1:-f -li e >>=1:-f -li e |=64:-f -li e &=7:-f -li e ^=42:-f -li e =99:
-f -uli b --:-f -uli b ++:-f -uli e --:-f -uli e ++:-f -uli e +=1:-f -uli e -=1:-f -uli e *=2:-f -uli e /=2:-f -uli e %=8:-f -uli e <<=1:-f -uli e >>=1:-f -uli e |=64:-f -uli e &=7:-f -uli e ^=42:-f -uli e =99:
-f -F1 e +=1:-f -F1 e -=1:-f -F1 e *=2:-f -F1 e /=2:-f -F1 e =99:
-f -E3 e +=1:-f -E3 e -=1:-f -E3 e *=2:-f -E3 e /=2:-f -E3 e =99:
-f -X3 e +=1:-f -X3 e -=1:-f -X3 e *=2:-f -X3 e /=2:-f -X3 e =99:
-f -lF1 e +=1:-f -lF1 e -=1:-f -lF1 e *=2:-f -lF1 e /=2:-f -lF1 e =99:
-f -lE3 e +=1:-f -lE3 e -=1:-f -lE3 e *=2:-f -lE3 e /=2:-f -lE3 e =99:
-f -lX3 e +=1:-f -lX3 e -=1:-f -lX3 e *=2:-f -lX3 e /=2:-f -lX3 e =99:

# Compound variables
-C NA b --:-C NA b ++:-C NA e --:-C NA e ++:-C NA e +=1:-C NA e -=1:-C NA e *=2:-C NA e /=2:-C NA e %=8:-C NA e <<=1:-C NA e >>=1:-C NA e |=64:-C NA e &=7:-C NA e ^=42:-C NA e =99:
-C -i b --:-C -i b ++:-C -i e --:-C -i e ++:-C -i e +=1:-C -i e -=1:-C -i e *=2:-C -i e /=2:-C -i e %=8:-C -i e <<=1:-C -i e >>=1:-C -i e |=64:-C -i e &=7:-C -i e ^=42:-C -i e =99:
-C -ui b --:-C -ui b ++:-C -ui e --:-C -ui e ++:-C -ui e +=1:-C -ui e -=1:-C -ui e *=2:-C -ui e /=2:-C -ui e %=8:-C -ui e <<=1:-C -ui e >>=1:-C -ui e |=64:-C -ui e &=7:-C -ui e ^=42:-C -ui e =99:
-C -si b --:-C -si b ++:-C -si e --:-C -si e ++:-C -si e +=1:-C -si e -=1:-C -si e *=2:-C -si e /=2:-C -si e %=8:-C -si e <<=1:-C -si e >>=1:-C -si e |=64:-C -si e &=7:-C -si e ^=42:-C -si e =99:
-C -usi b --:-C -usi b ++:-C -usi e --:-C -usi e ++:-C -usi e +=1:-C -usi e -=1:-C -usi e *=2:-C -usi e /=2:-C -usi e %=8:-C -usi e <<=1:-C -usi e >>=1:-C -usi e |=64:-C -usi e &=7:-C -usi e ^=42:-C -usi e =99:
-C -li b --:-C -li b ++:-C -li e --:-C -li e ++:-C -li e +=1:-C -li e -=1:-C -li e *=2:-C -li e /=2:-C -li e %=8:-C -li e <<=1:-C -li e >>=1:-C -li e |=64:-C -li e &=7:-C -li e ^=42:-C -li e =99:
-C -uli b --:-C -uli b ++:-C -uli e --:-C -uli e ++:-C -uli e +=1:-C -uli e -=1:-C -uli e *=2:-C -uli e /=2:-C -uli e %=8:-C -uli e <<=1:-C -uli e >>=1:-C -uli e |=64:-C -uli e &=7:-C -uli e ^=42:-C -uli e =99:
-C -F1 e +=1:-C -F1 e -=1:-C -F1 e *=2:-C -F1 e /=2:-C -F1 e =99:
-C -E3 e +=1:-C -E3 e -=1:-C -E3 e *=2:-C -E3 e /=2:-C -E3 e =99:
-C -X3 e +=1:-C -X3 e -=1:-C -X3 e *=2:-C -X3 e /=2:-C -X3 e =99:
-C -lF1 e +=1:-C -lF1 e -=1:-C -lF1 e *=2:-C -lF1 e /=2:-C -lF1 e =99:
-C -lE3 e +=1:-C -lE3 e -=1:-C -lE3 e *=2:-C -lE3 e /=2:-C -lE3 e =99:
-C -lX3 e +=1:-C -lX3 e -=1:-C -lX3 e *=2:-C -lX3 e /=2:-C -lX3 e =99:

# Associative arrays
-A NA b --:-A NA b ++:-A NA e --:-A NA e ++:-A NA e +=1:-A NA e -=1:-A NA e *=2:-A NA e /=2:-A NA e %=8:-A NA e <<=1:-A NA e >>=1:-A NA e |=64:-A NA e &=7:-A NA e ^=42:-A NA e =99:
-A -i b --:-A -i b ++:-A -i e --:-A -i e ++:-A -i e +=1:-A -i e -=1:-A -i e *=2:-A -i e /=2:-A -i e %=8:-A -i e <<=1:-A -i e >>=1:-A -i e |=64:-A -i e &=7:-A -i e ^=42:-A -i e =99:
-A -ui b --:-A -ui b ++:-A -ui e --:-A -ui e ++:-A -ui e +=1:-A -ui e -=1:-A -ui e *=2:-A -ui e /=2:-A -ui e %=8:-A -ui e <<=1:-A -ui e >>=1:-A -ui e |=64:-A -ui e &=7:-A -ui e ^=42:-A -ui e =99:
-A -si b --:-A -si b ++:-A -si e --:-A -si e ++:-A -si e +=1:-A -si e -=1:-A -si e *=2:-A -si e /=2:-A -si e %=8:-A -si e <<=1:-A -si e >>=1:-A -si e |=64:-A -si e &=7:-A -si e ^=42:-A -si e =99:
-A -usi b --:-A -usi b ++:-A -usi e --:-A -usi e ++:-A -usi e +=1:-A -usi e -=1:-A -usi e *=2:-A -usi e /=2:-A -usi e %=8:-A -usi e <<=1:-A -usi e >>=1:-A -usi e |=64:-A -usi e &=7:-A -usi e ^=42:-A -usi e =99:
-A -li b --:-A -li b ++:-A -li e --:-A -li e ++:-A -li e +=1:-A -li e -=1:-A -li e *=2:-A -li e /=2:-A -li e %=8:-A -li e <<=1:-A -li e >>=1:-A -li e |=64:-A -li e &=7:-A -li e ^=42:-A -li e =99:
-A -uli b --:-A -uli b ++:-A -uli e --:-A -uli e ++:-A -uli e +=1:-A -uli e -=1:-A -uli e *=2:-A -uli e /=2:-A -uli e %=8:-A -uli e <<=1:-A -uli e >>=1:-A -uli e |=64:-A -uli e &=7:-A -uli e ^=42:-A -uli e =99:
-A -E3 e +=1:-A -E3 e -=1:-A -E3 e *=2:-A -E3 e =99:
-A -lE3 e +=1:-A -lE3 e -=1:-A -lE3 e *=2:-A -lE3 e =99:
-A -F1 e +=1:-A -F1 e -=1:-A -F1 e *=2:-A -F1 e =99:
-A -lF1 e +=1:-A -lF1 e -=1:-A -lF1 e *=2:-A -lF1 e =99:
-A -X3 e +=1:-A -X3 e -=1:-A -X3 e *=2:-A -X3 e =99:
-A -lX3 e +=1:-A -lX3 e -=1:-A -lX3 e *=2:-A -lX3 e =99:
# problem with /= for associative arrays
-A -E3 e /=2:-A -lE3 e /=2:
-A -F1 e /=2:-A -lF1 e /=2:
-A -X3 e /=2:-A -lX3 e /=2:

# Indexed arrays
-a NA b --:-a NA b ++:-a NA e --:-a NA e ++:-a NA e +=1:-a NA e -=1:-a NA e *=2:-a NA e /=2:-a NA e %=8:-a NA e <<=1:-a NA e >>=1:-a NA e |=64:-a NA e &=7:-a NA e ^=42:-a NA e =99:
-a -i b --:-a -i b ++:-a -i e --:-a -i e ++:-a -i e +=1:-a -i e -=1:-a -i e *=2:-a -i e /=2:-a -i e %=8:-a -i e <<=1:-a -i e >>=1:-a -i e |=64:-a -i e &=7:-a -i e ^=42:-a -i e =99:
-a -ui b --:-a -ui b ++:-a -ui e --:-a -ui e ++:-a -ui e +=1:-a -ui e -=1:-a -ui e *=2:-a -ui e /=2:-a -ui e %=8:-a -ui e <<=1:-a -ui e >>=1:-a -ui e |=64:-a -ui e &=7:-a -ui e ^=42:-a -ui e =99:
-a -si b --:-a -si b ++:-a -si e --:-a -si e ++:-a -si e +=1:-a -si e -=1:-a -si e *=2:-a -si e /=2:-a -si e %=8:-a -si e <<=1:-a -si e >>=1:-a -si e |=64:-a -si e &=7:-a -si e ^=42:-a -si e =99:
-a -usi b --:-a -usi b ++:-a -usi e --:-a -usi e ++:-a -usi e +=1:-a -usi e -=1:-a -usi e *=2:-a -usi e /=2:-a -usi e %=8:-a -usi e <<=1:-a -usi e >>=1:-a -usi e |=64:-a -usi e &=7:-a -usi e ^=42:-a -usi e =99:
-a -li b --:-a -li b ++:-a -li e --:-a -li e ++:-a -li e +=1:-a -li e -=1:-a -li e *=2:-a -li e /=2:-a -li e %=8:-a -li e <<=1:-a -li e >>=1:-a -li e |=64:-a -li e &=7:-a -li e ^=42:-a -li e =99:
-a -uli b --:-a -uli b ++:-a -uli e --:-a -uli e ++:-a -uli e +=1:-a -uli e -=1:-a -uli e *=2:-a -uli e /=2:-a -uli e %=8:-a -uli e <<=1:-a -uli e >>=1:-a -uli e |=64:-a -uli e &=7:-a -uli e ^=42:-a -uli e =99:
-a -F1 e +=1:-a -F1 e -=1:-a -F1 e *=2:-a -F1 e /=2:-a -F1 e =99:
-a -E3 e +=1:-a -E3 e -=1:-a -E3 e *=2:-a -E3 e /=2:-a -E3 e =99:
-a -X3 e +=1:-a -X3 e -=1:-a -X3 e *=2:-a -X3 e /=2:-a -X3 e =99:
-a -lF1 e +=1:-a -lF1 e -=1:-a -lF1 e *=2:-a -lF1 e /=2:-a -lF1 e =99:
-a -lE3 e +=1:-a -lE3 e -=1:-a -lE3 e *=2:-a -lE3 e /=2:-a -lE3 e =99:
-a -lX3 e +=1:-a -lX3 e -=1:-a -lX3 e *=2:-a -lX3 e /=2:-a -lX3 e =99:

EOF
echo Total Errors: $errors
