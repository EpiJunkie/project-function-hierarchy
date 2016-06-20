#!/bin/sh

# Copyright (c) 2016, Justin D Holcomb All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Name            : project-function-hierarchy.sh
# Description     : This script spiders through an entire script project to find
#                   each function and visually display how each function calls
#                   other functions, and what they call, what those call and so
#                   forth.
# Author          : Justin D Holcomb
# Origin date     : 20160620
# Last change     : 20160620
# Version         : 0.1    
# Usage           : Edit variables in next section.
#                   Run: ./project-function-spider.sh
#                   OR:  ./project-function-spider.sh __function_to_visualize
# Notes           : Tested on FreeBSD 10.3 using /bin/sh against my own Bourne
#                   Shell projects.
# Requirements    : Functions must start with two underscores, followed by any
#                   number of upper and lower case leters or underscores "_",
#                   then followed by open parathesis "(", then closed 
#                   parathesis ")", then a single space and lastly an open
#                   brace "{".
# History         : 20160620 - Initial release.

# Edit these variables:
_ENTRY_POINT="sbin/cmd.sh"         # This is the script called by the user for regular use
_PROJECT_FILES="sbin/* lib/*"      # This contain the files or directories where other scripts or libraries the entry point depends on.
_INDENTION_DEPTH="   "

# List functions in hierarchical fashion
__list_functions() {
	_INDENTION_tier=1

	# Determine where to start
	if [ -z "$1" ]; then

		# Entry point for script
		local _origin_functions="$( pcregrep -vM '^__[_a-zAZ]{1,}.*(\n|.)*^}$' $_ENTRY_POINT | grep -vE '^#' | grep -o -E '__[_a-zAZ]{1,}' )"
	else

		# A single function
		local _origin_functions="$1"
	fi

	# Spider through the functions.
	for _child in `echo $_origin_functions`
	do
		__list_functions_sub "$_child"
	done
}

# Backend for '__list_functions', spiders through each supplied function block for functions it calls.
__list_functions_sub() {
	local _this_parent=$1
	local incoming_tier=$_INDENTION_tier
	_INDENTION_tier="$( expr 1 + $_INDENTION_tier )"
	local _children="$( grep -vhE '^#' $_PROJECT_FILES | grep -A9999999 "$_this_parent() {" | grep -B999999 -m 1 -E '^\}$' | grep -o -E '__[_a-zAZ]{1,}' | tail +2 )"

	# Create indentions
	__make_indention

	# Print the function name
	echo "$_this_parent"

	# Spider down through functions calls other functions.
	if [ -n "$_children" ]; then
		for _gbaby in `echo $_children`
		do

			# Keep from infinitely looping on itself
			if [ "$_gbaby" = "$_this_parent" ]; then

				# Create indentions
				__make_indention

				# Give warning
				echo "$_INDENTION_DEPTH$_this_parent - [WARNING] Infinite loop [WARNING]"

				# Go to next function rather than looping forever
				continue
			fi

			# Inception for each function that calls other functions.
			__list_functions_sub "$_gbaby"
		done
	fi

	# Reset the tier level to what it was when the function was called.
	_INDENTION_tier="$incoming_tier"
}

# Create non-broken indention
__make_indention() {
	local i=0
	
	# Create indentions for current tier
	while [ "$i" -ne "$_INDENTION_tier" ]
	do
		echo -n "$_INDENTION_DEPTH"
		local i="$( expr 1 + $i )"
	done
}

# Run it
__list_functions $@
