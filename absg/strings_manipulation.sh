#!/bin/bash

var="abcABC123ABCabc"
echo "${var} it is original string"
echo $(expr substr $var 1 2) #echo first two simbols
echo $(expr substr $var 4 3) #echo three simbols, starting at four positin

echo "${var:4}" #var starting from offset 4
echo "${var:4:3}" #var starting from offset 4 and length 3

echo "${var#a*C}" #strip out shortest math between 'a' and 'C' from left end
echo "${var##a*C}" #strip out longest math between 'a' and 'C' from left end

echo "${var%C*c}" #delete shortest math from right end of $var
echo "${var%%C*c}" #delete longest math from right end of $var
echo "${var%abc}" #delete 'abc' from back of $var
#remember # and ## work from left end (beginning) of string
#         % and %% work from right end

echo "${var/abc/xyz}" #substitude first math of 'abc' to 'xyz'
echo "${var//abc/xyz}" #substitude all matches of 'abc' to 'xyz'
echo "${var/abc}" #delete first match of 'abc'
echo "${var//abc}" #delete all matches of 'abc'

echo "${var/#abc/xyz}" #front substitude match 'abc' to 'xyz'
echo "${var/%abc/xyz}" #back substitude match 'abc' to 'xyz'

opt1="par1=val1"
echo "option1 is ${opt1}"
echo "${opt1%%=*}" #delete '=val1'
echo "${opt1##*=}" #delete 'par1='

echo "${username-$(whoami)}" #if 'username' is not set then $(whoami) $username remains uninitialized
username=
echo "${username:-$(whoami)}" #if 'username' declared but NULL then $(whoami) $username remains uninitialized

echo "${var1=abc}" #if var1 undeclared then 'abc', opposite, if var declared but NULL then no 'abc'
echo "${var1:=abc}" #if var declared but NULL then 'abc' $var1 initialized as 'abc'

echo "### \${parameter+alt_val} ###"
a=${param1+xyz}
echo "a = $a" #a =
param2=
a="${param2+xyz}"
echo "a = $a" # a = xyz
param3=123
a="${param3+asdf}"
echo "a = $a" # a = asdf, param3 unchanged
echo "### \${parameter:+alt_val} ###"
a="${param4:+xyz}"
echo "a = $a" # a =
param5=
a="${param5:+xyz}"
echo "a = $a" # a =
param6=123
a="${param6:+xyz}"
echo "a = $a" #a = xyz, param6 unchanged

unset a
#: "${a?"ERROR a is not set"}" #if uncomment then print error message and exit with return code 1
a=
echo "${a?"ERROR a is declared but NULL"}" #no error mess
#echo "${a:?"ERROR a is declared but NULL"}" #if uncomment then print error message end exit with return code 1

echo "length of \$var is ${#var}" #print number of characters in var

abc23="somthing_else"
echo "\$abc23 = \"${abc23}\""
b="${!abc@}" #expand to abc23 !abc* same effect
echo "b is \"${b}\""
c="${!b}" #refers to $abc23
echo "c is \"${c}\"" #somthing_else

exit 0
